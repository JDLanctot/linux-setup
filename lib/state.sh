#!/bin/bash

declare -r STATE_FILE="$HOME/.dotfiles_state.json"
declare -r BACKUP_DIR="$HOME/.dotfiles_backup"
declare -A INSTALLED_COMPONENTS
declare -A INSTALLATION_STATE
declare -r STATE_VERSION="1.0.0"
declare -r STATE_FILE="$HOME/.dotfiles/state.json"
declare -r STATE_BACKUP_DIR="$HOME/.dotfiles/backups"

init_state() {
    mkdir -p "$(dirname "$STATE_FILE")" "$STATE_BACKUP_DIR"
    
    # Create or validate state file
    if [ ! -f "$STATE_FILE" ]; then
        echo '{
            "version": "'$STATE_VERSION'",
            "components": {},
            "groups": {},
            "session": {
                "id": "'$(uuidgen)'",
                "startTime": "'$(date -Iseconds)'",
                "profile": null,
                "backupPath": "'$STATE_BACKUP_DIR'"
            },
            "metadata": {
                "platform": "linux",
                "lastUpdate": null,
                "installedVersions": {}
            }
        }' > "$STATE_FILE"
    else
        # Validate and potentially migrate existing state
        local current_version=$(jq -r '.version // "0.0.0"' "$STATE_FILE")
        if ! version_gte "$current_version" "$STATE_VERSION"; then
            migrate_state "$current_version"
        fi
    fi
}
save_component_state() {
    local name=$1
    local version=$2
    local group=${3:-""}
    local required=${4:-false}
    local path=${5:-""}
    local deps=${6:-"[]"}
    
    local json=$(cat "$STATE_FILE")
    local component=$(jq -n \
        --arg v "$version" \
        --arg d "$(date -Iseconds)" \
        --arg g "$group" \
        --argjson r "$required" \
        --arg p "$path" \
        --argjson deps "$deps" \
        '{
            version: $v,
            installedDate: $d,
            group: $g,
            required: $r,
            path: $p,
            dependencies: $deps,
            verificationStatus: true,
            lastVerified: now
        }')
    
    echo "$json" | jq ".components[\"$name\"] = $component" > "$STATE_FILE"
    INSTALLED_COMPONENTS[$name]=1
}

verify_component_state() {
    local name=$1
    local force=${2:-false}
    
    if [ -z "$name" ]; then
        return 1
    fi

    local state_data=$(jq -r ".components[\"$name\"] // empty" "$STATE_FILE")
    if [ -z "$state_data" ] && [ "$force" != "true" ]; then
        return 1
    fi

    # Verify installation based on component type
    local verify_cmd=$(jq -r ".components[\"$name\"].verify.command // empty" "$STATE_FILE")
    if [ -n "$verify_cmd" ] && ! command -v "$verify_cmd" >/dev/null 2>&1; then
        return 1
    fi

    # Verify configuration files
    local config_path=$(jq -r ".components[\"$name\"].verify.config // empty" "$STATE_FILE")
    if [ -n "$config_path" ] && [ ! -f "$config_path" ]; then
        return 1
    fi

    # Verify version if specified
    local required_version=$(jq -r ".components[\"$name\"].version // empty" "$STATE_FILE")
    if [ -n "$required_version" ]; then
        local current_version=$(get_component_version "$name")
        if ! version_gte "$current_version" "$required_version"; then
            return 1
        fi
    fi

    return 0
}

backup_component() {
    local name=$1
    local path=$2
    
    if [ -e "$path" ]; then
        local backup_path="$BACKUP_DIR/${name}_$(date +%Y%m%d_%H%M%S)"
        cp -r "$path" "$backup_path"
        echo "$backup_path"
    fi
}

restore_component() {
    local backup_path=$1
    local target_path=$2
    
    if [ -e "$backup_path" ]; then
        rm -rf "$target_path"
        cp -r "$backup_path" "$target_path"
        return 0
    fi
    return 1
}

restore_component_state() {
    local name=$1
    local backup_path=$(get_latest_backup "$name")
    
    if [ -n "$backup_path" ] && [ -d "$backup_path" ]; then
        local target_path=$(jq -r ".components[\"$name\"].path // empty" "$STATE_FILE")
        if [ -n "$target_path" ]; then
            rm -rf "$target_path"
            cp -r "$backup_path" "$target_path"
            return 0
        fi
    fi
    return 1
}

get_latest_backup() {
    local component=$1
    local backup_pattern="$BACKUP_DIR/${component}_*"
    ls -t $backup_pattern 2>/dev/null | head -n1
}

cleanup_and_exit() {
    local error_code=$1
    
    # Restore any failed components
    if [ $error_code -ne 0 ]; then
        log_warn "Installation failed, attempting to restore backups..."
        for component in "${FAILED_COMPONENTS[@]}"; do
            restore_component_backup "$component"
        done
    fi
    
    # Clean up temporary files
    rm -rf "$TMP_DIR"
    
    exit $error_code
}

is_component_installed() {
    local component=$1
    local version=$2
    
    if ! verify_installation "$component"; then
        return 1
    fi
    
    if [ -n "$version" ]; then
        local current_version=$(get_component_version "$component")
        if ! version_gte "$current_version" "$version"; then
            return 1
        fi
    fi
    
    return 0
}

version_gte() {
    local v1=$1
    local v2=$2
    
    if [[ "$v1" == "$v2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($v1) ver2=($v2)
    
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 1
        fi
    done
    return 0
}

check_version() {
    local current=$1
    local required=$2
    
    if [ -z "$required" ]; then
        return 0
    fi
    
    version_gte "$current" "$required"
}