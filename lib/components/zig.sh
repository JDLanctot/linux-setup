#!/bin/bash

install_zig() {
    local spec=$(get_component_spec "zig")
    local required_version=$(echo "$spec" | jq -r '.version // "0.11.0"')
    
    if ! $force && is_component_installed "zig" "$required_version"; then
        log_info "Zig already installed with required version"
        return 0
    }

    case $CURRENT_PKG_MANAGER in
        apt)
            # Install via snapshot as there's no official package
            local zig_url="https://ziglang.org/download/index.json"
            local download_url=$(curl -s "$zig_url" | jq -r ".master.\"x86_64-linux\".tarball")
            wget "$download_url" -O zig.tar.xz
            tar xf zig.tar.xz
            sudo mv zig-linux-* /usr/local/zig
            sudo ln -sf /usr/local/zig/zig /usr/local/bin/zig
            rm zig.tar.xz
            ;;
        pacman)
            pkg_install zig
            ;;
        dnf)
            # Install from copr repository
            add_repository "copr" "sentry/zig"
            pkg_install zig
            ;;
    esac

    if ! command -v zig >/dev/null; then
        log_error "Zig installation verification failed"
        return 1
    }

    return 0
}