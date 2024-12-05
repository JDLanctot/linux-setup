#!/bin/bash

install_neovim() {
    local spec=$(get_component_spec "neovim")
    local required_version=$(echo "$spec" | jq -r '.version // "0.9.0"')
    
    if ! $force && is_component_installed "neovim" "$required_version"; then
        log_info "Neovim already installed with required version"
        return 0
    }

    # Install build dependencies based on package manager
    local build_deps=()
    case $CURRENT_PKG_MANAGER in
        apt)
            build_deps=(
                "ninja-build"
                "gettext"
                "cmake"
                "unzip"
                "curl"
                "pkg-config"
            )
            add_repository "ppa" "neovim-ppa/unstable"
            ;;
        pacman)
            build_deps=(
                "base-devel"
                "cmake"
                "ninja"
                "curl"
                "unzip"
            )
            ;;
        dnf)
            build_deps=(
                "ninja-build"
                "cmake"
                "gettext"
                "curl"
                "unzip"
            )
            add_repository "rpm" "https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
            ;;
    esac

    # Install dependencies
    if ! pkg_install "${build_deps[@]}"; then
        log_error "Failed to install build dependencies"
        return 1
    }

    # Install Neovim
    if ! pkg_install neovim; then
        log_error "Failed to install neovim"
        return 1
    }

    # Verify installation
    if ! verify_package neovim; then
        log_error "Neovim installation verification failed"
        return 1
    }

    # Configure Neovim
    mkdir -p ~/.config/nvim/{lua,autoload,backup,swap,undo}

    # Install plugins
    if ! nvim --headless "+Lazy! sync" +qa; then
        log_error "Failed to install Neovim plugins"
        return 1
    }

    return 0
}