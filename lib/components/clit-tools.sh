#!/bin/bash

install_cli_tools() {
    local spec=$(get_component_spec "cli_tools")
    
    if ! $force && is_component_installed "cli_tools"; then
        log_info "CLI tools already installed"
        return 0
    }

    local tools
    case $CURRENT_PKG_MANAGER in
        apt)
            tools=(
                "unzip"
                "silversearcher-ag"
                "bat"
                "fzf"
                "zoxide"
                "ripgrep"
                "fd-find"
            )
            # Handle bat->batcat symlink for Debian/Ubuntu
            if pkg_install "${tools[@]}" && command -v batcat >/dev/null; then
                mkdir -p ~/.local/bin
                ln -sf /usr/bin/batcat ~/.local/bin/bat
            fi
            ;;
        pacman)
            tools=(
                "unzip"
                "the_silver_searcher"
                "bat"
                "fzf"
                "zoxide"
                "ripgrep"
                "fd"
            )
            pkg_install "${tools[@]}"
            ;;
        dnf)
            tools=(
                "unzip"
                "the_silver_searcher"
                "bat"
                "fzf"
                "zoxide"
                "ripgrep"
                "fd-find"
            )
            pkg_install "${tools[@]}"
            ;;
    esac

    # Verify installations
    local failed=()
    for tool in "${tools[@]}"; do
        if ! verify_package "$tool"; then
            failed+=("$tool")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        log_error "Failed to install: ${failed[*]}"
        return 1
    fi

    # Configure tools
    configure_cli_tools

    return 0
}

configure_cli_tools() {
    # Configure fzf
    if [ -f /usr/share/fzf/key-bindings.zsh ]; then
        cp /usr/share/fzf/key-bindings.zsh ~/.fzf.zsh
        echo "[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh" >> ~/.zshrc
    fi

    # Configure zoxide
    if ! grep -q "zoxide init" ~/.zshrc; then
        echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
    fi
    if ! grep -q "zoxide init" ~/.bashrc; then
        echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    fi
}