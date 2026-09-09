#!/bin/bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/config-common.sh"
for i in "${!targets[@]}"; do
    check_target "${targets[$i]}"
    [[ -f "${sources[$i]}" ]] || { printf 'Missing source: %s\n' "${sources[$i]}" >&2; exit 1; }
done
for i in "${!targets[@]}"; do
    target="${targets[$i]}"
    if [[ -L "$target" && "$(readlink "$target")" == "${sources[$i]}" ]]; then
        continue
    fi
    backup_target "$target" "${names[$i]}"
    mkdir -p "$(dirname -- "$target")"
    rm -f "$target"
    ln -s "${sources[$i]}" "$target"
    printf 'Linked: %s\n' "$target"
done
