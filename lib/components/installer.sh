#!/bin/bash

install_component() {
    local component=$1
    local force=${2:-false}
    
    # Set up error context and logging
    set_error_context "$component" "installation"
    log_structured "INFO" "$component" "start" "Beginning installation process"
    
    try {
        # Get and validate component specification
        local spec
        if ! spec=$(get_component_spec "$component"); then
            throw $E_CONFIG "Failed to get component specification"
        }
        
        # Pre-installation state capture
        local preinstall_state
        if preinstall_state=$(capture_system_state "$component"); then
            save_component_state "$component" "preinstall" "$preinstall_state"
        fi

        # Process dependencies first
        local deps=($(get_component_dependencies "$component"))
        for dep in "${deps[@]}"; do
            if ! is_component_installed "$dep"; then
                log_structured "INFO" "$component" "dependency" "Installing dependency: $dep"
                if ! install_component "$dep" "$force"; then
                    throw $E_DEPENDENCY "Failed to install dependency: $dep"
                fi
            fi
        }

        # Create backup point
        if ! create_restore_point "$component"; then
            throw $E_STATE "Failed to create restore point"
        }

        # Execute pre-install hooks
        if ! run_component_hooks "$component" "pre-install"; then
            throw $E_INSTALL "Pre-installation hooks failed"
        }

        # Execute main installation
        log_structured "INFO" "$component" "install" "Executing installation"
        if ! run_with_error_handling "$component" "install" install_"${component}"; then
            throw $E_INSTALL "Installation command failed"
        }

        # Execute post-install hooks
        if ! run_component_hooks "$component" "post-install"; then
            throw $E_INSTALL "Post-installation hooks failed"
        }

        # Verify installation
        if ! verify_component_installation "$component"; then
            throw $E_INSTALL "Installation verification failed"
        }

        # Update state
        local version=$(get_component_version "$component")
        save_component_state "$component" "installed" "$version"

        log_structured "SUCCESS" "$component" "complete" "Installation completed successfully"
        return 0

    } catch {
        local err_code=$?
        local err_msg=$1
        
        log_structured "ERROR" "$component" "failure" "$err_msg"
        
        # Attempt recovery
        if ! "$force"; then
            log_structured "INFO" "$component" "recovery" "Attempting to restore previous state"
            restore_component "$component"
        fi
        
        return $err_code
    }
}

verify_component_installation() {
    local component=$1
    local spec=$(get_component_spec "$component")
    
    log_structured "DEBUG" "$component" "verify" "Starting component verification"
    
    # Check for multiple commands first
    local commands=($(echo "$spec" | jq -r '.verify.commands[]' 2>/dev/null))
    if [ ${#commands[@]} -gt 0 ]; then
        log_structured "DEBUG" "$component" "verify" "Verifying multiple commands"
        verify_multiple_commands "${commands[@]}"
        return $?
    fi
    
    # Single command verification
    local cmd=$(echo "$spec" | jq -r '.verify.command')
    if [ -n "$cmd" ] && [ "$cmd" != "null" ]; then
        log_structured "DEBUG" "$component" "verify" "Verifying command: $cmd"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_structured "ERROR" "$component" "verify" "Command not found: $cmd"
            return 1
        fi
    fi
    
    # Configuration verification
    local config=$(echo "$spec" | jq -r '.verify.config')
    if [ -n "$config" ] && [ "$config" != "null" ]; then
        config=$(eval echo "$config")  # Expand variables
        log_structured "DEBUG" "$component" "verify" "Checking configuration at: $config"
        if [ ! -e "$config" ]; then
            log_structured "ERROR" "$component" "verify" "Configuration not found at: $config"
            return 1
        fi
    fi
    
    log_structured "DEBUG" "$component" "verify" "Verification completed successfully"
    return 0
}

get_component_version() {
    local component=$1
    local spec=$(get_component_spec "$component")
    
    local cmd=$(echo "$spec" | jq -r '.verify.command')
    local version_flag=$(echo "$spec" | jq -r '.verify.version_flag')
    
    if [ -n "$cmd" ] && [ -n "$version_flag" ]; then
        if output=$($cmd $version_flag 2>/dev/null | head -n1); then
            echo "$output"
            return 0
        fi
        return 1
    fi
    return 1
}

verify_multiple_commands() {
    local commands=("$@")
    
    for cmd in "${commands[@]}"; do
        log_structured "DEBUG" "verify" "command" "Checking command: $cmd"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_structured "ERROR" "verify" "command" "Command not found: $cmd"
            return 1
        fi
    done
    
    return 0
}