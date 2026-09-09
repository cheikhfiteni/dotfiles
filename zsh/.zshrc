export PATH="/opt/homebrew/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

. "$HOME/.cargo/env"

function zvm_after_init() {
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  bindkey '^F' autosuggest-accept
  bindkey '^E' forward-word
  bindkey '^X^A' autosuggest-toggle
}
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

eval "$(starship init zsh)"

# User defined aliases
alias clip='pbcopy <'

# single command to run and build, single container or services
dockerup() {
    if [ -f "docker-compose.yml" ]; then
        echo "Found compose file, building and starting services..."
        docker compose up --build -d
    elif [ -f "Dockerfile" ]; then
        if [ -z "$1" ]; then
            echo "Error: Please provide a tag name when building a single container"
            return 1
        fi
        echo "Building and running single container with tag: $1"
        docker build -t "$1" .
        docker run -d "$1"
    else
        echo "Error: No docker-compose.yml or Dockerfile found"
        return 1
    fi
}

export PATH="$PATH:$HOME/.volta/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
if [[ -n $TMUX ]]; then
  export COLUMNS=$(tput cols)
  export LINES=$(tput lines)
fi

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
export PATH="$HOME/.local/bin:$PATH"

# >>> loadenv >>>
loadenv(){ set -a;. "${1:-.env}";set +a;}
# <<< loadenv <<<

# Automatically enter tmux for interactive SSH connections.
if [[ $- == *i* && -n "$SSH_CONNECTION" && -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    tmux new-session -A -s main
fi
