#!/bin/bash

# Load config paths
source "$(dirname "${BASH_SOURCE[0]}")/paths.sh"

# Configuration handling
validate_config() {
    local component=$1
    
    # Check if component exists in CONFIG_PATHS
    local source_path=$(get_config_path "$component" "source")
    local target_path=$(get_config_path "$component" "target")
    local type=$(get_config_path "$component" "type")
    
    if [[ -z "$source_path" || -z "$target_path" || -z "$type" ]]; then
        print_error "Invalid configuration for component: $component"
        return 1
    fi
    
    # Validate configuration type
    if [[ "$type" != "file" && "$type" != "directory" ]]; then
        print_error "Invalid configuration type for $component: $type"
        return 1
    }
    
    return 0
}

backup_config() {
    local component=$1
    local target_path=$(get_config_path "$component" "target")
    local type=$(get_config_path "$component" "type")
    local backup_path=""
    
    if [ -e "$target_path" ]; then
        backup_path="${target_path}.backup_$(date +%Y%m%d_%H%M%S)"
        
        if [ "$type" = "directory" ]; then
            cp -r "$target_path" "$backup_path"
        else
            cp "$target_path" "$backup_path"
        fi
        
        if [ $? -eq 0 ]; then
            print_success "Backed up $target_path to $backup_path"
            echo "$backup_path"
        else
            print_error "Failed to backup $target_path"
            return 1
        fi
    fi
}

install_config() {
    local component=$1
    local source_base=$2
    
    if ! validate_config "$component"; then
        return 1
    }
    
    local source_path="$source_base/$(get_config_path "$component" "source")"
    local target_path=$(get_config_path "$component" "target")
    local type=$(get_config_path "$component" "type")
    
    # Create target directory if needed
    mkdir -p "$(dirname "$target_path")"
    
    # Backup existing configuration
    local backup_path=$(backup_config "$component")
    
    # Install new configuration
    if [ -e "$source_path" ]; then
        if [ "$type" = "directory" ]; then
            rm -rf "$target_path"
            cp -r "$source_path" "$target_path"
        else
            cp "$source_path" "$target_path"
        fi
        
        if [ $? -eq 0 ]; then
            print_success "$component configuration installed"
            return 0
        else
            print_error "Failed to install $component configuration"
            if [ -n "$backup_path" ]; then
                restore_config "$backup_path" "$target_path" "$type"
            fi
            return 1
        fi
    else
        print_error "$component configuration not found: $source_path"
        return 1
    fi
}

restore_config() {
    local backup_path=$1
    local target_path=$2
    local type=$3
    
    if [ -e "$backup_path" ]; then
        if [ "$type" = "directory" ]; then
            rm -rf "$target_path"
            cp -r "$backup_path" "$target_path"
        else
            cp "$backup_path" "$target_path"
        fi
        
        if [ $? -eq 0 ]; then
            print_success "Restored $target_path from backup"
            return 0
        else
            print_error "Failed to restore from backup"
            return 1
        fi
    fi
    return 1
}