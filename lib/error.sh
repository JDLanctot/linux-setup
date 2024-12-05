#!/bin/bash

declare -r E_SUCCESS=0
declare -r E_GENERAL=1
declare -r E_DEPENDENCY=2
declare -r E_NETWORK=3
declare -r E_PERMISSION=4
declare -r E_CONFIG=5
declare -r E_SYSTEM=6
declare -r E_STATE=7

declare -A ERROR_CONTEXTS
declare -A ERROR_HANDLERS

init_error_handling() {
    trap 'handle_error ${LINENO} $?' ERR
    trap 'handle_exit' EXIT
    trap 'handle_interrupt' INT TERM

    # Register default handlers
    register_error_handler $E_DEPENDENCY handle_dependency_error
    register_error_handler $E_NETWORK handle_network_error
    register_error_handler $E_PERMISSION handle_permission_error
}

register_error_handler() {
    local error_code=$1
    local handler_function=$2
    ERROR_HANDLERS[$error_code]=$handler_function
}

set_error_context() {
    local component=$1
    local operation=$2
    ERROR_CONTEXTS[component]=$component
    ERROR_CONTEXTS[operation]=$operation
}

clear_error_context() {
    ERROR_CONTEXTS=()
}

handle_error() {
    local line=$1
    local code=$2
    local component=${ERROR_CONTEXTS[current_component]:-"unknown"}
    
    log_error "Error on line $line (exit code $code) in component $component"
    
    # Call registered handler if exists
    if [ -n "${ERROR_HANDLERS[$code]}" ]; then
        ${ERROR_HANDLERS[$code]} "$line" "$component"
    fi
    
    # Attempt recovery
    if [ -n "$component" ]; then
        restore_component_state "$component"
    fi
    
    return $code
}

# Default error handlers
handle_dependency_error() {
    local message=$1
    local component=$2
    
    log_error "Dependency error for $component: $message"
    
    # Try to install missing dependency if possible
    if [ -n "$component" ]; then
        log_info "Attempting to install missing dependency: $component"
        install_component "$component" || return $E_DEPENDENCY
    fi
}

handle_network_error() {
    local message=$1
    local component=$2
    local max_retries=3
    local retry_delay=5
    
    log_error "Network error for $component: $message"
    
    # Implement exponential backoff retry
    for ((i=1; i<=max_retries; i++)); do
        log_info "Retry attempt $i of $max_retries for $component"
        if test_network_connectivity; then
            return 0
        fi
        sleep $((retry_delay * i))
    done
    
    return $E_NETWORK
}

handle_permission_error() {
    local message=$1
    local component=$2
    
    log_error "Permission error for $component: $message"
    
    # Check if we can escalate privileges
    if [ "$EUID" -ne 0 ]; then
        log_info "Attempting to escalate privileges..."
        if sudo -v; then
            return 0
        fi
    fi
    
    return $E_PERMISSION
}

handle_config_error() {
    local message=$1
    local component=$2
    
    log_error "Configuration error for $component: $message"
    
    # Attempt to restore backup configuration if available
    if [ -n "$component" ]; then
        restore_component_backup "$component"
    fi
    
    return $E_CONFIG
}

handle_system_error() {
    local message=$1
    
    log_error "System error: $message"
    check_system_requirements
    return $E_SYSTEM
}

handle_install_error() {
    local message=$1
    local component=$2
    
    log_error "Installation error for $component: $message"
    
    # Attempt cleanup and restoration
    if [ -n "$component" ]; then
        restore_component_state "$component"
    fi
    
    return $E_INSTALL
}

handle_state_error() {
    local message=$1
    local component=$2
    
    log_error "State error for $component: $message"
    
    # Attempt to reinitialize state
    init_state
    
    return $E_STATE
}

# Function to wrap commands with error handling
run_with_error_handling() {
    local component=$1
    local operation=$2
    shift 2
    local command=("$@")
    
    set_error_context "$component" "$operation"
    
    if ! "${command[@]}"; then
        handle_error $? "Command failed: ${command[*]}"
        return $?
    fi
    
    clear_error_context
    return 0
}

try() {
    set +e
    local err_file=$(mktemp)
    # Execute in subshell to preserve error state
    ("$@") 2>"$err_file"
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        local error_msg=$(cat "$err_file")
        rm -f "$err_file"
        throw $exit_code "$error_msg"
    fi
    rm -f "$err_file"
    set -e
}

throw() {
    local code=$1
    local message=${2:-"An error occurred"}
    echo "$message" >&2
    exit $code
}

catch() {
    local exit_code=$?
    set -e
    "$@" "$exit_code"
    return $exit_code
}