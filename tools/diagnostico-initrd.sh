#!/usr/bin/env bash
# Diagnóstico: compara el initrd original de Kubuntu con uno regenerado
# dentro del sistema en vivo, para ver por qué no arranca la sesión live.
set -uo pipefail
cd "$(dirname "$0")/.."
source config/ondalia.conf
W=/mnt/diag; mkdir -p "$W"; cd "$W"
wget -q -O SHA256SUMS "$BASE_URL/SHA256SUMS"
NAME=$(grep -E "kubuntu-[0-9.]+-desktop-amd64.iso$" SHA256SUMS | sort -V | tail -n1 | awk '{print $2}' | tr -d '*')
wget -q -O base.iso "$BASE_URL/$NAME"
mkdir -p iso && xorriso -osirrox on -indev base.iso -extract /casper iso/casper -extract /.disk iso/.disk 2>/dev/null
echo "=== casper/ en la ISO"; ls -la iso/casper; echo "=== .disk"; ls -la iso/.disk; head -c 200 iso/.disk/casper-uuid* 2>/dev/null; echo
apt-get install -y -qq initramfs-tools-core zstd >/dev/null 2>&1 || true
mkdir -p orig && unmkinitramfs iso/casper/initrd orig
echo "=== initrd original: carpetas"; ls orig; ls orig/main 2>/dev/null | head -30
R=orig/main; [[ -d $R ]] || R=orig
echo "=== scripts casper original"; ls $R/scripts | head -40; ls $R/conf; cat $R/conf/uuid.conf 2>/dev/null; cat $R/conf/initramfs.conf 2>/dev/null | grep -v '^#' | sed '/^$/d'
echo "=== kernel del initrd original"; ls $R/usr/lib/modules 2>/dev/null || ls $R/lib/modules
unsquashfs -q -d root iso/casper/filesystem.squashfs
echo "=== paquetes clave en el squashfs"; chroot root dpkg -l casper initramfs-tools dracut dracut-core lupin-casper 2>&1 | grep -E '^(ii|un|rc)|no packages'
echo "=== kernels en el squashfs"; ls root/boot root/usr/lib/modules
echo "=== initramfs.conf del squashfs"; grep -v '^#' root/etc/initramfs-tools/initramfs.conf | sed '/^$/d'; ls root/etc/initramfs-tools/conf.d root/usr/share/initramfs-tools/conf.d 2>/dev/null
for m in dev dev/pts proc sys; do mount --bind /$m root/$m; done
K=$(ls root/usr/lib/modules | sort -V | tail -n1)
chroot root update-initramfs -c -k "$K" -b /tmp >/dev/null 2>&1 || chroot root mkinitramfs -o /tmp/initrd.new "$K"
NEW=$(ls root/tmp/initrd.img-* root/tmp/initrd.new 2>/dev/null | head -n1)
mkdir -p new && unmkinitramfs "$NEW" new
N=new/main; [[ -d $N ]] || N=new
echo "=== scripts regenerado"; ls $N/scripts | head -40; ls $N/conf
echo "=== diferencias en scripts"; diff <(cd $R && find scripts conf -type f | sort) <(cd $N && find scripts conf -type f | sort)
echo "=== tamaño módulos original vs nuevo"; du -sh $R/usr/lib/modules $N/usr/lib/modules 2>/dev/null
echo "=== módulos de cd/iso/squashfs en el nuevo"; find $N -name 'sr_mod*' -o -name 'isofs*' -o -name 'squashfs*' -o -name 'overlay*' | head
for m in sys proc dev/pts dev; do umount -lf root/$m; done
