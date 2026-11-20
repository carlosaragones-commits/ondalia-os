#!/usr/bin/env bash
# Construye la ISO de Ondalia OS a partir de la ISO oficial de Kubuntu 26.04 LTS.
#
# Pasos:
#   1. Descarga la ISO base y comprueba su SHA256.
#   2. Extrae la ISO y su sistema de archivos (squashfs).
#   3. Copia los archivos de Ondalia y ejecuta los hooks dentro del sistema (chroot).
#   4. Vuelve a comprimir el sistema y genera la ISO nueva, conservando el
#      arranque UEFI/BIOS de la original.
#
# Uso:  sudo ./build.sh
#       sudo FAST_TEST=1 ./build.sh   (solo regenera la ISO, sin personalizar)
# Necesita: wget xorriso squashfs-tools rsync librsvg2-bin y unos 25 GB libres.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"
# shellcheck source=config/ondalia.conf
source config/ondalia.conf

ISO_DIR="$WORK_DIR/iso"
CHROOT="$WORK_DIR/chroot"
DL_DIR="$WORK_DIR/download"
OVERLAY="$WORK_DIR/overlay"
BASE_ISO=""
OUT_ISO=""

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mError: %s\033[0m\n' "$*" >&2; exit 1; }

unmount_chroot() {
    local m
    for m in run sys proc dev/pts dev; do
        if mountpoint -q "$CHROOT/$m" 2>/dev/null; then
            umount -lf "$CHROOT/$m" || true
        fi
    done
}
trap unmount_chroot EXIT

check_requirements() {
    [[ $EUID -eq 0 ]] || die "Ejecuta el script como root: sudo ./build.sh"
    local cmd
    for cmd in wget xorriso unsquashfs mksquashfs rsync rsvg-convert sha256sum; do
        command -v "$cmd" >/dev/null ||
            die "Falta '$cmd'. Instala: apt install wget xorriso squashfs-tools rsync librsvg2-bin"
    done
    mkdir -p "$WORK_DIR" "$OUT_DIR"
    local free_gb
    free_gb=$(df --output=avail -BG "$WORK_DIR" | tail -n1 | tr -dc '0-9')
    if ((free_gb < 25)); then
        printf '\033[1;33mAviso: solo hay %s GB libres en %s; se recomiendan 25 GB.\033[0m\n' \
            "$free_gb" "$WORK_DIR"
    fi
}

download_base() {
    log "Buscando la ISO base en $BASE_URL"
    mkdir -p "$DL_DIR"
    wget -q -O "$DL_DIR/SHA256SUMS" "$BASE_URL/SHA256SUMS" ||
        die "No se pudo descargar $BASE_URL/SHA256SUMS"

    local line name sum
    line=$(grep -E "kubuntu-[0-9.]+-${BASE_ISO_PATTERN}\$" "$DL_DIR/SHA256SUMS" | sort -V | tail -n1) ||
        die "No encuentro ninguna ISO '*-${BASE_ISO_PATTERN}' en SHA256SUMS"
    sum=$(awk '{print $1}' <<<"$line")
    name=$(awk '{print $2}' <<<"$line" | tr -d '*')
    BASE_ISO="$DL_DIR/$name"

    if [[ -f $BASE_ISO ]] && echo "$sum  $BASE_ISO" | sha256sum -c --status; then
        log "Ya descargada y verificada: $name"
        return
    fi
    log "Descargando $name (unos 5 GB)"
    wget -c --progress=dot:giga -O "$BASE_ISO" "$BASE_URL/$name"
    echo "$sum  $BASE_ISO" | sha256sum -c --status ||
        die "La suma SHA256 de $name no coincide; borra el archivo y vuelve a intentarlo"
    log "ISO base verificada: $name"
}

extract_base() {
    log "Extrayendo la ISO"
    unmount_chroot
    rm -rf "$ISO_DIR" "$CHROOT"
    mkdir -p "$ISO_DIR"
    xorriso -osirrox on -indev "$BASE_ISO" -extract / "$ISO_DIR" 2>/dev/null
    chmod -R u+w "$ISO_DIR"

    local squashfs="$ISO_DIR/casper/filesystem.squashfs"
    [[ -f $squashfs ]] ||
        die "La ISO no trae casper/filesystem.squashfs. Contenido de casper/: $(ls "$ISO_DIR/casper" | tr '\n' ' ')"

    if [[ ${FAST_TEST:-0} == 1 ]]; then
        log "Prueba rápida: se conserva el sistema de Kubuntu sin modificar"
        return
    fi
    log "Extrayendo el sistema de archivos (puede tardar varios minutos)"
    unsquashfs -q -f -d "$CHROOT" "$squashfs"
    rm -f "$squashfs"   # se regenera al final; así se ahorran unos 4 GB
}

render_branding() {
    log "Generando imágenes de la marca"
    rm -rf "$OVERLAY"
    local wp="$OVERLAY/usr/share/wallpapers/Ondalia/contents"
    local ply="$OVERLAY/usr/share/plymouth/themes/ondalia"
    local pix="$OVERLAY/usr/share/pixmaps"
    mkdir -p "$wp/images" "$wp/images_dark" "$ply" "$pix"

    local size w h
    for size in 3840x2160 2560x1440 1920x1080; do
        w=${size%x*}; h=${size#*x}
        rsvg-convert -w "$w" -h "$h" branding/wallpaper.svg -o "$wp/images/$size.png"
        rsvg-convert -w "$w" -h "$h" branding/wallpaper-dark.svg -o "$wp/images_dark/$size.png"
    done
    rsvg-convert -w 400 -h 225 branding/wallpaper.svg -o "$wp/screenshot.png"

    rsvg-convert -w 200 -h 200 branding/logo-mono-light.svg -o "$ply/logo.png"
    install -m 0644 branding/logo.svg "$pix/ondalia-logo.svg"
    install -m 0644 branding/logo-mono-light.svg "$pix/ondalia-logo-symbolic.svg"
    rsvg-convert -w 512 -h 512 branding/logo.svg -o "$pix/ondalia-logo.png"
}

prepare_chroot() {
    log "Preparando el entorno chroot"
    mount --bind /dev "$CHROOT/dev"
    mount --bind /dev/pts "$CHROOT/dev/pts"
    mount -t proc proc "$CHROOT/proc"
    mount -t sysfs sysfs "$CHROOT/sys"
    mount -t tmpfs tmpfs "$CHROOT/run"

    # DNS del anfitrión dentro del chroot (se restaura al terminar).
    if [[ -e $CHROOT/etc/resolv.conf || -L $CHROOT/etc/resolv.conf ]]; then
        mv "$CHROOT/etc/resolv.conf" "$CHROOT/etc/resolv.conf.ondalia"
    fi
    if [[ -f /run/systemd/resolve/resolv.conf ]]; then
        cp /run/systemd/resolve/resolv.conf "$CHROOT/etc/resolv.conf"
    else
        cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf"
    fi

    # Impide que los paquetes arranquen servicios durante la compilación.
    printf '#!/bin/sh\nexit 101\n' >"$CHROOT/usr/sbin/policy-rc.d"
    chmod +x "$CHROOT/usr/sbin/policy-rc.d"
}

customize() {
    log "Copiando archivos de Ondalia al sistema"
    rsync -a --no-owner --no-group config/includes.chroot/ "$CHROOT/"
    rsync -a --no-owner --no-group "$OVERLAY/" "$CHROOT/"
    chown -R root:root "$CHROOT/etc/xdg" "$CHROOT/usr/share/plasma" 2>/dev/null || true

    rm -rf "$CHROOT/tmp/ondalia"
    mkdir -p "$CHROOT/tmp/ondalia"
    cp -r config/hooks config/packages "$CHROOT/tmp/ondalia/"

    local hook name
    for hook in config/hooks/*.chroot; do
        name=$(basename "$hook")
        log "Hook $name"
        chroot "$CHROOT" /usr/bin/env -i \
            HOME=/root \
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
            LANG=C.UTF-8 \
            DISTRO_NAME="$DISTRO_NAME" DISTRO_ID="$DISTRO_ID" \
            VERSION="$VERSION" CODENAME="$CODENAME" \
            DEFAULT_LOCALE="$DEFAULT_LOCALE" DEFAULT_KEYMAP="$DEFAULT_KEYMAP" \
            DEFAULT_TIMEZONE="$DEFAULT_TIMEZONE" \
            AUTOFIRMA_REQUIRED="${AUTOFIRMA_REQUIRED:-0}" \
            /bin/bash "/tmp/ondalia/hooks/$name" ||
            die "Falló el hook $name"
    done
}

cleanup_chroot() {
    log "Limpiando el sistema"
    chroot "$CHROOT" apt-get clean
    rm -rf "$CHROOT/tmp/"* "$CHROOT/var/tmp/"* "$CHROOT/var/lib/apt/lists/"*
    rm -f "$CHROOT/root/.bash_history" "$CHROOT/usr/sbin/policy-rc.d"
    find "$CHROOT/var/log" -type f -exec truncate -s 0 {} +
    : >"$CHROOT/etc/machine-id"

    rm -f "$CHROOT/etc/resolv.conf"
    if [[ -e $CHROOT/etc/resolv.conf.ondalia || -L $CHROOT/etc/resolv.conf.ondalia ]]; then
        mv "$CHROOT/etc/resolv.conf.ondalia" "$CHROOT/etc/resolv.conf"
    fi
    unmount_chroot
}

update_boot_files() {
    log "Actualizando kernel, initrd y menú de arranque"
    local kver
    kver=$(find "$CHROOT/boot" -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' |
        sed 's/^vmlinuz-//' | sort -V | tail -n1)
    [[ -n $kver ]] || die "No se encuentra ningún kernel en /boot del sistema"
    cp "$CHROOT/boot/vmlinuz-$kver" "$ISO_DIR/casper/vmlinuz"
    cp "$CHROOT/boot/initrd.img-$kver" "$ISO_DIR/casper/initrd"

    # Menú de arranque en español y con el nombre de Ondalia.
    # Sin tildes ni eñes: la fuente de GRUB las muestra como "?".
    # boot=casper: el initrd original de Kubuntu lo trae dentro, pero el que
    # se regenera en el chroot no, y sin él no arranca la sesión en vivo.
    local cfg
    for cfg in "$ISO_DIR/boot/grub/grub.cfg" "$ISO_DIR/boot/grub/loopback.cfg"; do
        [[ -f $cfg ]] || continue
        sed -i \
            -e "s/Try or Install Kubuntu/Probar o instalar $DISTRO_NAME/g" \
            -e "s/Kubuntu/$DISTRO_NAME/g" \
            -e "s/safe graphics/modo grafico seguro/g" \
            -e "s/OEM install (for manufacturers)/Instalacion OEM (para fabricantes)/g" \
            -e "/linux.*casper/ s|---| locale=$DEFAULT_LOCALE keyboard-configuration/layoutcode=$DEFAULT_KEYMAP ---|" \
            -e "/linux.*casper/ { /boot=casper/! s|\(/casper/[^ ]*vmlinuz\)|\1 boot=casper| }" \
            "$cfg"
    done

    if [[ -d $ISO_DIR/.disk ]]; then
        printf '%s %s "%s" - amd64 (%s)\n' "$DISTRO_NAME" "$VERSION" "$CODENAME" "$(date +%Y%m%d)" \
            >"$ISO_DIR/.disk/info"
    fi
}

build_squashfs() {
    log "Comprimiendo el sistema ($SQUASHFS_COMP); es el paso más largo"
    # shellcheck disable=SC2016  # el formato lo interpreta dpkg-query, no bash
    chroot "$CHROOT" dpkg-query -W --showformat='${Package} ${Version}\n' \
        >"$ISO_DIR/casper/filesystem.manifest"
    mksquashfs "$CHROOT" "$ISO_DIR/casper/filesystem.squashfs" \
        -noappend -comp "$SQUASHFS_COMP" -b 1M -quiet \
        -wildcards -e 'proc/*' 'sys/*' 'dev/*' 'run/*' 'tmp/*'
    du -sx --block-size=1 "$CHROOT" | cut -f1 | tr -d '\n' >"$ISO_DIR/casper/filesystem.size"
}

build_iso() {
    log "Generando la ISO"
    (
        cd "$ISO_DIR"
        find . -type f ! -name md5sum.txt ! -name boot.catalog ! -path './isolinux/*' -print0 |
            sort -z | xargs -0 md5sum >"$WORK_DIR/md5sum.txt"
        mv "$WORK_DIR/md5sum.txt" md5sum.txt
    )

    OUT_ISO="$OUT_DIR/${DISTRO_ID}-${VERSION}-amd64.iso"
    rm -f "$OUT_ISO"

    # Se reutiliza exactamente el arranque UEFI y BIOS de la ISO de Kubuntu:
    # xorriso describe cómo se creó (opciones de mkisofs) y se repite con
    # nuestro contenido. La partición EFI se lee de la ISO original.
    local boot_args
    boot_args=$(xorriso -indev "$BASE_ISO" -report_el_torito as_mkisofs 2>/dev/null |
        grep -vE '^-V ' | tr '\n' ' ')
    [[ -n $boot_args ]] || die "No se pudo leer la configuración de arranque de la ISO base"
    log "Opciones de arranque heredadas: $boot_args"

    eval "xorriso -as mkisofs -r -iso-level 3 $boot_args" \
        '-V "$ISO_LABEL" -o "$OUT_ISO" "$ISO_DIR"'

    (cd "$OUT_DIR" && sha256sum "$(basename "$OUT_ISO")" >"$(basename "$OUT_ISO").sha256")
    log "ISO lista: $OUT_ISO ($(du -h "$OUT_ISO" | cut -f1))"
}

main() {
    check_requirements
    download_base
    extract_base
    if [[ ${FAST_TEST:-0} == 1 ]]; then
        # Solo comprueba que la ISO se puede regenerar y arrancar (unos 5 min).
        build_iso
        return
    fi
    render_branding
    prepare_chroot
    customize
    cleanup_chroot
    update_boot_files
    build_squashfs
    build_iso
    if [[ ${KEEP_WORK:-0} != 1 ]]; then
        log "Borrando la carpeta de trabajo (usa KEEP_WORK=1 para conservarla)"
        rm -rf "$ISO_DIR" "$CHROOT" "$OVERLAY"
    fi
}

main "$@"
