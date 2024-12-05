#!/bin/bash

install_i3() {
    local spec=$(get_component_spec "i3")
    local required_version=$(echo "$spec" | jq -r '.version // "4.20.0"')
    
    if ! $force && is_component_installed "i3" "$required_version"; then
        log_info "i3 already installed with required version"
        return 0
    }

    case $CURRENT_PKG_MANAGER in
        apt)
            pkg_install i3-wm i3status i3lock dunst
            ;;
        pacman)
            pkg_install i3-wm i3status i3lock dunst
            ;;
        dnf)
            pkg_install i3 i3status i3lock dunst
            ;;
    esac

    if ! verify_package i3; then
        log_error "i3 installation verification failed"
        return 1
    }

    # Configure i3
    mkdir -p "$HOME/.config/i3"
    if [ -d "$DOTFILES_PATH/.config/i3" ]; then
        cp -r "$DOTFILES_PATH/.config/i3/"* "$HOME/.config/i3/"
    else
        i3-config-wizard
    fi

    return 0
}