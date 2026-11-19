#!/usr/bin/env bash
# Funciones comunes para los hooks. Cada hook la carga con:
#   source /tmp/ondalia/hooks/lib.sh

set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

log()  { printf '\033[1;34m  -> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  !! %s\033[0m\n' "$*" >&2; }

apt_get() {
    # Reintenta si el mirror falla de forma puntual.
    local i
    for i in 1 2 3; do
        apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "$@" && return 0
        warn "apt-get $* falló (intento $i); reintentando en 10 s"
        sleep 10
    done
    return 1
}

# Instala solo los paquetes que existen en los repositorios y avisa de los que no.
# Así un nombre que cambie entre versiones de Ubuntu no rompe la compilación.
install_available() {
    local pkg available=() missing=()
    for pkg in "$@"; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            available+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done
    if ((${#missing[@]})); then
        warn "No existen en los repositorios y se omiten: ${missing[*]}"
    fi
    if ((${#available[@]})); then
        log "Instalando: ${available[*]}"
        apt_get install --no-install-recommends "${available[@]}"
    fi
}

# Desinstala solo los paquetes que estén instalados.
purge_installed() {
    local pkg installed=()
    for pkg in "$@"; do
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed+=("$pkg")
        fi
    done
    if ((${#installed[@]})); then
        log "Quitando: ${installed[*]}"
        apt_get purge "${installed[@]}"
    fi
}

# Lee una lista de paquetes ignorando comentarios y líneas vacías.
read_list() {
    sed -e 's/#.*//' -e 's/[[:space:]]\+$//' -e '/^[[:space:]]*$/d' "$1"
}
