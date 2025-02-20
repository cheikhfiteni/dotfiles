 # If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
plugins=(zsh-autosuggestions z)

source $ZSH/oh-my-zsh.sh

export PATH="/opt/homebrew/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

. "$HOME/.cargo/env"

eval "$(starship init zsh)"
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

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

# single command to install and update requirements in python venv
uvadd() {
    if [ $# -eq 0 ]; then
        echo "Error: Please provide at least one package name"
        return 1
    fi
    
    local req_file="requirements.txt"
    if [ "$LAST_ARG" = "dev" ]; then
        req_file="requirements-dev.txt"
        set -- "${@:1:$(($#-1))}"  # Remove last argument (dev)
    fi
    
    uv pip install "$@" && uv pip freeze > "$req_file"
}

