#!/bin/bash

install_node() {
    local spec=$(get_component_spec "node")
    local required_version=$(echo "$spec" | jq -r '.version // "18.0.0"')
    
    if ! $force && is_component_installed "node" "$required_version"; then
        log_info "Node.js already installed with required version"
        return 0
    }

    # Install Node.js based on package manager
    case $CURRENT_PKG_MANAGER in
        apt)
            # Add NodeSource repository
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            pkg_install nodejs
            ;;
        pacman)
            pkg_install nodejs npm
            ;;
        dnf)
            # Add NodeSource repository
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            pkg_install nodejs
            ;;
    esac

    if ! verify_package nodejs; then
        log_error "Node.js installation verification failed"
        return 1
    }

    # Install pnpm
    if ! command -v pnpm >/dev/null; then
        npm install -g pnpm
        if ! command -v pnpm >/dev/null; then
            log_error "pnpm installation failed"
            return 1
        fi
    fi

    return 0
}