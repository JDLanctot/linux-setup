#!/bin/bash

install_git() {
    local spec=$(get_component_spec "git")
    local required_version=$(echo "$spec" | jq -r '.version // "2.34.0"')
    
    if ! $force && is_component_installed "git" "$required_version"; then
        log_info "Git already installed with required version"
        return 0
    }

    case $CURRENT_PKG_MANAGER in
        apt)
            add_repository "ppa" "git-core/ppa"
            pkg_install git
            ;;
        pacman)
            pkg_install git
            ;;
        dnf)
            pkg_install git
            ;;
    esac

    if ! verify_package git; then
        log_error "Git installation verification failed"
        return 1
    }

    # Configure Git
    if [ -z "$GIT_EMAIL" ]; then
        read -p "Enter your Git email: " GIT_EMAIL
    fi
    
    if [ -z "$GIT_NAME" ]; then
        read -p "Enter your Git name: " GIT_NAME
    fi
    
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name "$GIT_NAME"
    git config --global init.defaultBranch main
    
    # Setup SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -C "${GIT_EMAIL}" -f ~/.ssh/id_ed25519 -N ""
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
    fi

    return 0
}