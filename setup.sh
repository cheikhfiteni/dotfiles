#!/bin/bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

homebrew_installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
/bin/bash -c "$homebrew_installer"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
curl -LsSf https://astral.sh/uv/install.sh | sh
brew bundle --file="$repo_dir/brew/Brewfile"
"$repo_dir/scripts/sync.sh"
printf 'Configuration linked. Open a new shell to load it.\n'
