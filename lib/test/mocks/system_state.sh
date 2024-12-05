#!/bin/bash

# Mock system state
declare -A MOCK_SYSTEM_STATE
declare -A MOCK_FILE_SYSTEM
declare -A MOCK_PERMISSIONS

# Mock system state functions
capture_system_state() {
    local component=$1
    local state_id="state_$(date +%s)"
    
    MOCK_SYSTEM_STATE[$component]=$state_id
    return 0
}

restore_system_state() {
    local component=$1
    local state_id=${MOCK_SYSTEM_STATE[$component]}
    
    [ -n "$state_id" ]
    return $?
}

# Mock filesystem operations
mock_file_exists() {
    local path=$1
    [ -n "${MOCK_FILE_SYSTEM[$path]}" ]
}

mock_create_file() {
    local path=$1
    local content=${2:-""}
    MOCK_FILE_SYSTEM[$path]=$content
}

mock_delete_file() {
    local path=$1
    unset MOCK_FILE_SYSTEM[$path]
}

# Mock permission operations
mock_set_permissions() {
    local path=$1
    local perms=$2
    MOCK_PERMISSIONS[$path]=$perms
}

mock_check_permissions() {
    local path=$1
    local required_perms=$2
    [ "${MOCK_PERMISSIONS[$path]}" = "$required_perms" ]
}

# Reset mock state
reset_system_state() {
    MOCK_SYSTEM_STATE=()
    MOCK_FILE_SYSTEM=()
    MOCK_PERMISSIONS=()
}