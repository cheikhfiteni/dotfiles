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
