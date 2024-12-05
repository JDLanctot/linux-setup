#!/bin/bash

install_alacritty() {
    local spec=$(get_component_spec "alacritty")
    local required_version=$(echo "$spec" | jq -r '.version // "0.12.0"')
    
    if ! $force && is_component_installed "alacritty" "$required_version"; then
        log_info "Alacritty already installed with required version"
        return 0
    }

    case $CURRENT_PKG_MANAGER in
        apt)
            add_repository "ppa" "aslatter/ppa"
            pkg_install alacritty
            ;;
        pacman)
            pkg_install alacritty
            ;;
        dnf)
            # For Fedora, Alacritty is in the main repositories
            pkg_install alacritty
            ;;
    esac

    if ! verify_package alacritty; then
        log_error "Alacritty installation verification failed"
        return 1
    }

    # Configure Alacritty
    mkdir -p "$HOME/.config/alacritty"
    if [ -d "$DOTFILES_PATH/.config/alacritty" ]; then
        cp -r "$DOTFILES_PATH/.config/alacritty/"* "$HOME/.config/alacritty/"
    fi

    return 0
}