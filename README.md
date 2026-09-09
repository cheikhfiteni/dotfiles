## Installation

Run `~/Desktop/github/dotfiles/setup.sh` from any directory to install dependencies
and link the shell, Starship, and tmux configuration.

To apply configuration without installing software:

```sh
~/Desktop/github/dotfiles/scripts/sync.sh
```

These commands replace `~/.zshrc`, `~/.config/starship.toml`, and `~/.tmux.conf`
with symlinks into this checkout. Keep the checkout at its current location.
Edits through those links change the repo files; review and commit them normally.
Open a new shell after syncing.

Existing files are saved under `~/.local/state/dotfiles/backups/` in unique UTC
timestamped directories. Backups of valid symlinks capture their contents;
broken symlinks are preserved as links. Repeating sync skips already-correct
links. Neovim and VS Code configuration are not installed by this script.

For isolated testing, set `DOTFILES_HOME` to a temporary directory when running
the configuration scripts.

## Locate and restore backups

List backup IDs and the files each contains:

```sh
~/Desktop/github/dotfiles/scripts/restore.sh --list
```

Restore a selected backup using its ID from that list:

```sh
~/Desktop/github/dotfiles/scripts/restore.sh 20260909T220000Z.ABC123
```

Restore saves current files in a new timestamped backup before replacing them.
It restores only files present in the selected backup, leaving other files alone.
Restored regular files are independent of the repo; repo sources are never
changed by restoration. Run `sync.sh` again when ready to relink them (which
backs up the restored files). Old `.bak` files are left alone and are not listed.

Run the isolated backup/restore checks with `python3 scripts/test-config.py`.
