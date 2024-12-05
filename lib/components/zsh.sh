#!/bin/bash

install_zsh() {
    local spec=$(get_component_spec "zsh")
    local required_version=$(echo "$spec" | jq -r '.version // "5.8"')
    
    if ! $force && is_component_installed "zsh" "$required_version"; then
        log_info "Zsh already installed with required version"
        return 0
    }

    # Install Zsh based on package manager
    case $CURRENT_PKG_MANAGER in
        apt)
            pkg_install zsh
            ;;
        pacman)
            pkg_install zsh
            ;;
        dnf)
            pkg_install zsh util-linux-user
            ;;
    esac

    if ! verify_package zsh; then
        log_error "Zsh installation verification failed"
        return 1
    }

    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended
    fi

    # Install plugins
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    # Install zsh-autosuggestions
    if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    fi
    
    # Install zsh-completions
    if [ ! -d "$plugins_dir/zsh-completions" ]; then
        git clone https://github.com/zsh-users/zsh-completions "$plugins_dir/zsh-completions"
    fi

    # Set as default shell if it isn't already
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
    fi

    return 0
}