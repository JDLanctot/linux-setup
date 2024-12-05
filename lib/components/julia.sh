#!/bin/bash

install_julia() {
    local spec=$(get_component_spec "julia")
    local required_version=$(echo "$spec" | jq -r '.version // "1.8.5"')
    
    if ! $force && is_component_installed "julia" "$required_version"; then
        log_info "Julia already installed with required version"
        return 0
    }

    case $CURRENT_PKG_MANAGER in
        apt)
            # Add Julia repository
            wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-${required_version}-linux-x86_64.tar.gz
            tar xf julia-${required_version}-linux-x86_64.tar.gz
            sudo mv julia-${required_version} /opt/
            sudo ln -sf /opt/julia-${required_version}/bin/julia /usr/local/bin/julia
            ;;
        pacman)
            pkg_install julia
            ;;
        dnf)
            # Add COPR repository for Julia
            add_repository "copr" "nalimilan/julia"
            pkg_install julia
            ;;
    esac

    if ! verify_package julia || ! command -v julia >/dev/null; then
        log_error "Julia installation verification failed"
        return 1
    }

    # Setup Julia configuration
    mkdir -p "$HOME/.julia/config"
    if [ -f "$DOTFILES_PATH/.julia/config/startup.jl" ]; then
        cp "$DOTFILES_PATH/.julia/config/startup.jl" "$HOME/.julia/config/"
    fi

    return 0
}