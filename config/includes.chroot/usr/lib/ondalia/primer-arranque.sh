#!/usr/bin/env bash
# Primer arranque del sistema instalado: configura las instantáneas de Snapper
# si la raíz es Btrfs. No hace nada en la sesión en vivo (USB).
set -u

STAMP_DIR=/var/lib/ondalia
grep -qw 'boot=casper' /proc/cmdline && exit 0
mkdir -p "$STAMP_DIR"

if [[ $(findmnt -no FSTYPE /) == btrfs ]] && command -v snapper >/dev/null &&
    [[ ! -f /etc/snapper/configs/root ]]; then
    snapper -c root create-config /
    snapper -c root set-config \
        NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5 \
        TIMELINE_CREATE=no
fi

touch "$STAMP_DIR/primer-arranque.hecho"
