#!/bin/bash

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
COMPONENTS_DIR="$LIB_DIR/components"
LOG_DIR="$HOME/.dotfiles/logs"
TMP_DIR=$(mktemp -d)
declare -a FAILED_COMPONENTS=()

# Source required modules
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/error.sh"
source "$LIB_DIR/state.sh"
source "$LIB_DIR/components/specs.sh"
source "$LIB_DIR/components/installer.sh"
source "$LIB_DIR/package_manager.sh"
source "$LIB_DIR/profiles.sh"

# Initialize systems
init_logging
init_error_handling
trap_signals
init_state
init_package_manager

parse_args() {
    while getopts "p:fh" opt; do
        case $opt in
            p) PROFILE="$OPTARG" ;;
            f) FORCE=true ;;
            h) 
                echo "Usage: $0 [-p profile] [-f] [-h]"
                echo "Options:"
                echo "  -p  Installation profile (Minimal, Standard, Full)"
                echo "  -f  Force reinstallation"
                echo "  -h  Show this help"
                exit 0
                ;;
            *)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
        esac
    done
}

main() {
    local profile=${1:-"Standard"}
    local force=${2:-false}
    
    log_info "Starting installation with profile: $profile"
    
    # Get components for profile
    local components=($(get_profile_components "$profile"))
    init_progress ${#components[@]}
    
    # Process each component
    for component in "${components[@]}"; do
        show_progress "Installing $component..."
        
        if ! install_component "$component" "$force"; then
            FAILED_COMPONENTS+=("$component")
            if is_required "$component" "$profile"; then
                log_error "Required component $component failed to install"
                cleanup_and_exit 1
            else
                log_warn "Optional component $component failed to install"
            fi
        fi
    done
    
    if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
        log_warn "Installation completed with some failures: ${FAILED_COMPONENTS[*]}"
        cleanup_and_exit 1
    fi
    
    log_info "Installation completed successfully"
    cleanup_and_exit 0
}

# Run main installation
main "$@"