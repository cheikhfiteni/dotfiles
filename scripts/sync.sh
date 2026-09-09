#!/bin/bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/config-common.sh"
for i in "${!targets[@]}"; do
    check_target "${targets[$i]}"
    [[ -f "${sources[$i]}" ]] || { printf 'Missing source: %s\n' "${sources[$i]}" >&2; exit 1; }
done
start_transaction
changed=()
for i in "${!targets[@]}"; do
    target="${targets[$i]}"
    if [[ "${names[$i]}" == codex-config.toml ]]; then
        stage_target "$target" "${sources[$i]}" codex
        if [[ -f "$target" ]] && cmp -s "$target" "${transaction_dirs[$((transaction_count-1))]}/replacement"; then
            transaction_count=$((transaction_count-1))
            rm -rf "${transaction_dirs[$transaction_count]}"
            continue
        fi
        changed+=("$i")
        continue
    fi
    if [[ -L "$target" && "$(readlink "$target")" == "${sources[$i]}" ]]; then
        continue
    fi
    stage_target "$target" "${sources[$i]}" link
    changed+=("$i")
done
for i in ${changed[@]+"${changed[@]}"}; do
    backup_target "${targets[$i]}" "${names[$i]}"
done
apply_transaction
