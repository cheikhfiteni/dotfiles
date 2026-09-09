#!/bin/bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/config-common.sh"

if [[ $# == 0 || ( $# == 1 && "$1" == --list ) ]]; then
    printf 'Backups in %s:\n' "$backup_root"
    shopt -s nullglob
    for snapshot in "$backup_root"/*/; do
        printf '\n%s\n' "$(basename -- "$snapshot")"
        for name in "${names[@]}"; do
            if [[ -e "$snapshot/$name" || -L "$snapshot/$name" ]]; then
                printf '  %s\n' "$name"
            fi
        done
    done
    exit 0
fi
if [[ $# != 1 || "$1" == */* || "$1" == . || "$1" == .. ]]; then
    printf 'Usage: %s [--list | BACKUP_ID]\n' "$0" >&2
    exit 1
fi
snapshot="$backup_root/$1"
if [[ ! -d "$snapshot" || -L "$snapshot" ]]; then
    printf 'Backup not found: %s\n' "$snapshot" >&2
    exit 1
fi
found=false
for i in "${!names[@]}"; do
    saved="$snapshot/${names[$i]}"
    if [[ -e "$saved" || -L "$saved" ]]; then
        check_target "$saved"
        check_target "${targets[$i]}"
        found=true
    fi
done
if [[ "$found" == false ]]; then
    printf 'No recognized configuration files in backup.\n' >&2
    exit 1
fi
for i in "${!names[@]}"; do
    saved="$snapshot/${names[$i]}"
    if [[ -e "$saved" || -L "$saved" ]]; then
        target="${targets[$i]}"
        backup_target "$target" "${names[$i]}"
        mkdir -p "$(dirname -- "$target")"
        rm -f "$target"
        cp -pP "$saved" "$target"
        printf 'Restored: %s\n' "$target"
    fi
done
printf 'Restored files are independent of the repo. Run sync.sh to relink them.\n'
