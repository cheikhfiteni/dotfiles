/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
curl -LsSf https://astral.sh/uv/install.sh | sh

brew bundle --file=brew/Brewfile
nvim --headless +Lazy! +qa

# Backup and replace ~/.zshrc
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi
cp ./zsh/.zshrc "$HOME/.zshrc"

# Backup and replace ~/.config/starship.toml
mkdir -p "$HOME/.config"
if [ -f "$HOME/.config/starship.toml" ]; then
    cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
fi
cp ./zsh/starship/starship.toml "$HOME/.config/starship.toml"

# Source the new zshrc
source "$HOME/.zshrc"
