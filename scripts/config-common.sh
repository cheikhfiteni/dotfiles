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
