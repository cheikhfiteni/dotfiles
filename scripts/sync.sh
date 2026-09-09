#!/bin/bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/config-common.sh"
for i in "${!targets[@]}"; do
    check_target "${targets[$i]}"
    [[ -f "${sources[$i]}" ]] || { printf 'Missing source: %s\n' "${sources[$i]}" >&2; exit 1; }
done
start_transaction
for i in "${!targets[@]}"; do
    target="${targets[$i]}"
    if [[ -L "$target" && "$(readlink "$target")" == "${sources[$i]}" ]]; then
        continue
    fi
    stage_target "$target" "${sources[$i]}" link
done
for i in "${!targets[@]}"; do
    if [[ -L "${targets[$i]}" && "$(readlink "${targets[$i]}")" == "${sources[$i]}" ]]; then
        continue
    fi
    backup_target "${targets[$i]}" "${names[$i]}"
done
apply_transaction
