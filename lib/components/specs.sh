#!/bin/bash

# Component specifications
declare -A COMPONENT_SPECS=(
    ["zsh"]='
    {
        "name": "zsh",
        "description": "Z Shell",
        "version": "5.8",
        "dependencies": [],
        "verify": {
            "command": "zsh",
            "version_flag": "--version",
            "config": "$HOME/.zshrc"
        },
        "backup": [
            "$HOME/.zshrc",
            "$HOME/.zshenv",
            "$HOME/.zprofile",
            "$HOME/.oh-my-zsh"
        ],
        "post_install": [
            "chsh -s $(which zsh)",
            "sh -c \"$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"
        ]
    }'
    
    ["neovim"]='
    {
        "name": "neovim",
        "description": "Neovim Editor",
        "version": "0.9.0",
        "dependencies": ["git"],
        "verify": {
            "command": "nvim",
            "version_flag": "--version",
            "config": "$HOME/.config/nvim/init.lua"
        },
        "backup": [
            "$HOME/.config/nvim",
            "$HOME/.local/share/nvim",
            "$HOME/.cache/nvim"
        ],
        "post_install": [
            "mkdir -p ~/.config/nvim/{lua,autoload,backup,swap,undo}",
            "nvim --headless \"+Lazy! sync\" +qa"
        ]
    }'

    ["node"]='
    {
        "name": "node",
        "description": "Node.js and pnpm",
        "version": "18.0.0",
        "dependencies": [],
        "verify": {
            "command": "node",
            "version_flag": "--version",
            "config": "$HOME/.nvm/nvm.sh"
        },
        "backup": [
            "$HOME/.nvm",
            "$HOME/.npmrc",
            "$HOME/.node_repl_history"
        ],
        "post_install": [
            "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash",
            "source $HOME/.nvm/nvm.sh",
            "nvm install --lts",
            "npm install -g pnpm"
        ]
    }'

    ["julia"]='
    {
        "name": "julia",
        "description": "Julia Programming Language",
        "version": "1.8.5",
        "dependencies": [],
        "verify": {
            "command": "julia",
            "version_flag": "--version",
            "config": "$HOME/.julia/config/startup.jl"
        },
        "backup": [
            "$HOME/.julia/config",
            "$HOME/.julia/environments"
        ],
        "post_install": [
            "mkdir -p $HOME/.julia/config"
        ]
    }'

    ["alacritty"]='
    {
        "name": "alacritty",
        "description": "GPU-accelerated terminal emulator",
        "version": "0.12.0",
        "dependencies": [],
        "verify": {
            "command": "alacritty",
            "version_flag": "--version",
            "config": "$HOME/.config/alacritty/alacritty.yml"
        },
        "backup": [
            "$HOME/.config/alacritty"
        ],
        "post_install": [
            "mkdir -p $HOME/.config/alacritty"
        ]
    }'

    ["i3"]='
    {
        "name": "i3",
        "description": "i3 window manager",
        "version": "4.20.0",
        "dependencies": [],
        "verify": {
            "command": "i3",
            "version_flag": "--version",
            "config": "$HOME/.config/i3/config"
        },
        "backup": [
            "$HOME/.config/i3",
            "$HOME/.i3"
        ],
        "post_install": [
            "mkdir -p $HOME/.config/i3"
        ]
    }'

    ["cli_tools"]='
    {
        "name": "cli_tools",
        "description": "Command line utilities",
        "version": "1.0.0",
        "dependencies": [],
        "verify": {
            "commands": ["unzip", "eza", "ag", "bat", "fzf", "zoxide"]
        },
        "backup": [
            "$HOME/.config/bat",
            "$HOME/.fzf.zsh",
            "$HOME/.local/bin"
        ],
        "post_install": [
            "[ -f /usr/bin/batcat ] && mkdir -p ~/.local/bin && ln -sf /usr/bin/batcat ~/.local/bin/bat",
            "[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && cp /usr/share/doc/fzf/examples/key-bindings.zsh ~/.fzf.zsh"
        ]
    }'

    ["zig"]='
    {
        "name": "zig",
        "description": "Zig compiler and tools",
        "version": "0.11.0",
        "dependencies": [],
        "verify": {
            "command": "zig",
            "version_flag": "version",
            "config": ""
        },
        "backup": [
            "$HOME/.cache/zig"
        ],
        "post_install": []
    }'

    ["starship"]='
    {
        "name": "starship",
        "description": "Cross-shell prompt",
        "version": "1.15.0",
        "dependencies": [],
        "verify": {
            "command": "starship",
            "version_flag": "--version",
            "config": "$HOME/.config/starship.toml"
        },
        "backup": [
            "$HOME/.config/starship.toml"
        ],
        "post_install": [
            "mkdir -p $HOME/.config",
            "echo 'eval \"$(starship init bash)\"' >> $HOME/.bashrc",
            "echo 'eval \"$(starship init zsh)\"' >> $HOME/.zshrc"
        ]
    }'

    ["git"]='
    {
        "name": "git",
        "description": "Git version control",
        "version": "2.34.0",
        "dependencies": [],
        "verify": {
            "command": "git",
            "version_flag": "--version",
            "config": "$HOME/.gitconfig"
        },
        "backup": [
            "$HOME/.gitconfig",
            "$HOME/.ssh/id_ed25519",
            "$HOME/.ssh/config",
            "$HOME/.ssh/known_hosts"
        ],
        "post_install": [
            "mkdir -p $HOME/.ssh",
            "chmod 700 $HOME/.ssh"
        ]
    }'
)

get_component_spec() {
    local component=$1
    echo "${COMPONENT_SPECS[$component]}"
}

verify_component_spec() {
    local component=$1
    local spec=$(get_component_spec "$component")
    
    if [ -z "$spec" ]; then
        return 1
    fi
    
    # Verify required fields
    local required_fields=("name" "description" "version" "dependencies" "verify" "backup" "post_install")
    for field in "${required_fields[@]}"; do
        if ! echo "$spec" | jq -e "has(\"$field\")" >/dev/null; then
            log_error "Component $component missing required field: $field"
            return 1
        fi
    done
    
    # Verify verify field structure
    if ! echo "$spec" | jq -e '.verify | (has("command") and has("version_flag")) or has("commands")' >/dev/null; then
        log_error "Component $component has invalid verify specification"
        return 1
    fi
    
    return 0
}