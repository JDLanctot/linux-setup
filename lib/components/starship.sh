#!/bin/bash

install_starship() {
    local spec=$(get_component_spec "starship")
    local required_version=$(echo "$spec" | jq -r '.version // "1.15.0"')
    
    if ! $force && is_component_installed "starship" "$required_version"; then
        log_info "Starship already installed with required version"
        return 0
    }

    case $CURRENT_PKG_MANAGER in
        apt)
            # Install via cargo as there's no official package
            pkg_install cargo
            cargo install starship
            ;;
        pacman)
            pkg_install starship
            ;;
        dnf)
            # Install via cargo as there's no official package
            pkg_install cargo
            cargo install starship
            ;;
    esac

    if ! command -v starship >/dev/null; then
        log_error "Starship installation verification failed"
        return 1
    }

    # Configure Starship
    mkdir -p "$HOME/.config"
    if [ -f "$DOTFILES_PATH/.config/starship.toml" ]; then
        cp "$DOTFILES_PATH/.config/starship.toml" "$HOME/.config/"
    fi

    # Add to shell configurations
    for shell_rc in ".bashrc" ".zshrc"; do
        if [ -f "$HOME/$shell_rc" ]; then
            if ! grep -q "eval \"\$(starship init" "$HOME/$shell_rc"; then
                echo 'eval "$(starship init ${shell_rc%.rc})"' >> "$HOME/$shell_rc"
            fi
        fi
    done

    return 0
}