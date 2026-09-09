#!/bin/bash
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
config_home="${DOTFILES_HOME:-$HOME}"
backup_root="$config_home/.local/state/dotfiles/backups"
backup_dir=""
names=(zshrc starship.toml tmux.conf)
sources=("$repo_dir/zsh/.zshrc" "$repo_dir/zsh/starship/starship.toml" "$repo_dir/tmux/.tmux.conf")
targets=("$config_home/.zshrc" "$config_home/.config/starship.toml" "$config_home/.tmux.conf")

check_target() {
    if [[ -e "$1" && ! -f "$1" ]]; then
        printf 'Refusing to replace a non-file: %s\n' "$1" >&2
        return 1
    fi
}

backup_target() {
    local target="$1" name="$2"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -z "$backup_dir" ]]; then
            mkdir -p "$backup_root"
            backup_dir="$(mktemp -d "$backup_root/$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")"
            printf 'Backup: %s\n' "$backup_dir"
        fi
        # Snapshot contents so later edits cannot change a symlink's backup.
        if [[ -e "$target" ]]; then
            cp -pL "$target" "$backup_dir/$name"
        else
            cp -P "$target" "$backup_dir/$name"
        fi
    fi
}

# Prepare every replacement beside its destination before changing any live file.
# Keep exact originals (including symlinks) for rollback, separate from backups.
transaction_count=0
applied_count=0
transaction_dirs=()
transaction_targets=()

finish_transaction() {
    local status=$? j directory target rollback_failed=false
    trap - EXIT INT TERM
    set +e
    if [[ "$status" != 0 ]]; then
        for ((j=applied_count-1; j>=0; j--)); do
            directory="${transaction_dirs[$j]}"
            target="${transaction_targets[$j]}"
            if [[ -e "$directory/original" || -L "$directory/original" ]]; then
                if ! mv -f "$directory/original" "$target"; then
                    printf 'Rollback failed for %s; recovery files: %s\n' "$target" "$directory" >&2
                    rollback_failed=true
                fi
            elif ! rm -f "$target"; then
                printf 'Rollback could not remove %s\n' "$target" >&2
                rollback_failed=true
            fi
        done
    fi
    if [[ "$rollback_failed" == false ]]; then
        for ((j=0; j<transaction_count; j++)); do
            rm -rf "${transaction_dirs[$j]}"
        done
    fi
    exit "$status"
}

start_transaction() {
    trap finish_transaction EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

stage_target() {
    local target="$1" source="$2" mode="$3" directory
    check_target "$target"
    mkdir -p "$(dirname -- "$target")"
    directory="$(mktemp -d "$(dirname -- "$target")/.dotfiles-stage.XXXXXX")"
    transaction_dirs[$transaction_count]="$directory"
    transaction_targets[$transaction_count]="$target"
    transaction_count=$((transaction_count+1))
    if [[ -e "$target" || -L "$target" ]]; then
        cp -pP "$target" "$directory/original"
    fi
    if [[ "$mode" == link ]]; then
        ln -s "$source" "$directory/replacement"
    else
        cp -pP "$source" "$directory/replacement"
    fi
}

apply_transaction() {
    local j
    for ((j=0; j<transaction_count; j++)); do
        applied_count=$((j+1))
        mv -f "${transaction_dirs[$j]}/replacement" "${transaction_targets[$j]}"
        printf 'Updated: %s\n' "${transaction_targets[$j]}"
    done
}
