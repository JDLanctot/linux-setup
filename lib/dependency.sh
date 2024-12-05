#!/bin/bash

# Dependency graph representation
declare -A DEPENDENCY_GRAPH
declare -A REVERSE_DEPENDENCIES
declare -A INSTALLATION_ORDER

init_dependency_management() {
    local components=($(get_all_components))
    
    # Build dependency graph
    for component in "${components[@]}"; do
        local deps=($(get_component_dependencies "$component"))
        DEPENDENCY_GRAPH[$component]="${deps[*]}"
        
        # Build reverse dependencies
        for dep in "${deps[@]}"; do
            REVERSE_DEPENDENCIES[$dep]+=" $component"
        done
    done
    
    # Calculate installation order
    calculate_installation_order
}

calculate_installation_order() {
    local -A visited
    local -a order
    
    for component in "${!DEPENDENCY_GRAPH[@]}"; do
        if [ -z "${visited[$component]}" ]; then
            visit_component "$component" visited order
        fi
    done
    
    # Store final order
    INSTALLATION_ORDER=(${order[@]})
}

visit_component() {
    local component=$1
    local -n visited=$2
    local -n order=$3
    
    # Mark as temporarily visited (for cycle detection)
    visited[$component]="visiting"
    
    # Process dependencies
    local deps=(${DEPENDENCY_GRAPH[$component]})
    for dep in "${deps[@]}"; do
        case "${visited[$dep]:-}" in
            "")
                visit_component "$dep" visited order
                ;;
            "visiting")
                log_error "Circular dependency detected: $component -> $dep"
                return 1
                ;;
        esac
    done
    
    # Mark as fully visited and add to order
    visited[$component]="visited"
    order+=("$component")
}

verify_dependencies() {
    local component=$1
    local deps=(${DEPENDENCY_GRAPH[$component]})
    local missing=()
    local version_mismatch=()
    
    for dep in "${deps[@]}"; do
        if ! is_component_installed "$dep"; then
            missing+=("$dep")
            continue
        fi
        
        # Version compatibility check
        local required_version=$(get_required_version "$component" "$dep")
        if [ -n "$required_version" ]; then
            local installed_version=$(get_component_version "$dep")
            if ! version_satisfies "$installed_version" "$required_version"; then
                version_mismatch+=("$dep")
            fi
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ] || [ ${#version_mismatch[@]} -gt 0 ]; then
        log_error "Dependency check failed for $component:"
        [ ${#missing[@]} -gt 0 ] && log_error "Missing: ${missing[*]}"
        [ ${#version_mismatch[@]} -gt 0 ] && log_error "Version mismatch: ${version_mismatch[*]}"
        return 1
    fi
    
    return 0
}

get_required_version() {
    local component=$1
    local dependency=$2
    local spec=$(get_component_spec "$component")
    echo "$spec" | jq -r ".dependencies[\"$dependency\"].version // empty"
}

resolve_dependencies() {
    local component=$1
    local order=()
    
    # Reset tracking arrays for new resolution
    RESOLVED_DEPS=()
    VISITING_DEPS=()
    
    _resolve_deps_recursive "$component" order
    echo "${order[*]}"
}

_resolve_deps_recursive() {
    local component=$1
    local -n order=$2
    
    # Check if already resolved
    if [ "${RESOLVED_DEPS[$component]}" = "1" ]; then
        return 0
    fi
    
    # Check for circular dependencies
    if [ "${VISITING_DEPS[$component]}" = "1" ]; then
        log "ERROR" "Circular dependency detected for $component"
        return 1
    fi
    
    # Mark as being visited
    VISITING_DEPS[$component]=1
    
    # Get component dependencies
    local deps=($(get_component_dependencies "$component"))
    
    # Recursively resolve dependencies
    for dep in "${deps[@]}"; do
        _resolve_deps_recursive "$dep" order
    done
    
    # Remove from visiting and add to resolved
    unset VISITING_DEPS[$component]
    RESOLVED_DEPS[$component]=1
    
    # Add to ordered list
    order+=("$component")
}

get_component_dependencies() {
    local component=$1
    local spec=$(get_component_spec "$component")
    if [ -n "$spec" ]; then
        echo "$spec" | jq -r '.dependencies[]' 2>/dev/null || true
    fi
}

verify_installation() {
    local component=$1
    local spec=$(get_component_spec "$component")
    
    # System check
    if ! check_system_requirements; then
        return 1
    }
    
    # Command verification
    local verify_cmd=$(echo "$spec" | jq -r '.verify.command')
    if [ -n "$verify_cmd" ] && ! command -v "$verify_cmd" >/dev/null 2>&1; then
        return 1
    }
    
    # Configuration verification
    local config_path=$(echo "$spec" | jq -r '.verify.config')
    if [ -n "$config_path" ] && [ "$config_path" != "null" ]; then
        config_path=$(eval echo "$config_path")
        if [ ! -e "$config_path" ]; then
            return 1
        }
        
        # Content verification if specified
        local verify_content=$(echo "$spec" | jq -r '.verify.content')
        if [ -n "$verify_content" ] && [ "$verify_content" != "null" ]; then
            if ! grep -q "$verify_content" "$config_path"; then
                return 1
            }
        }
    }
    
    # Version verification
    local required_version=$(echo "$spec" | jq -r '.version')
    if [ -n "$required_version" ] && [ "$required_version" != "null" ]; then
        local current_version=$(get_component_version "$component")
        if ! version_gte "$current_version" "$required_version"; then
            return 1
        }
    }
    
    # Custom verification script
    local verify_script=$(echo "$spec" | jq -r '.verify.script')
    if [ -n "$verify_script" ] && [ "$verify_script" != "null" ]; then
        if ! eval "$verify_script"; then
            return 1
        }
    }
    
    return 0
}

verify_dependencies() {
    local component=$1
    local deps=($(get_component_dependencies "$component"))
    local missing=()
    
    for dep in "${deps[@]}"; do
        local dep_spec=$(get_component_spec "$dep")
        local required_version=$(echo "$dep_spec" | jq -r '.version // empty')
        
        if ! is_component_installed "$dep" "$required_version"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log "ERROR" "Missing dependencies for $component: ${missing[*]}"
        return 1
    fi
    
    return 0
}

check_system_requirements() {
    # Check Linux distribution
    if ! command -v lsb_release >/dev/null 2>&1; then
        if ! sudo apt-get update || ! sudo apt-get install -y lsb-release; then
            log_error "Failed to install lsb-release"
            return 1
        fi
    }
    
    # Check disk space (now in MB for more precision)
    local free_space=$(df -BM / | awk 'NR==2 {print $4}' | sed 's/M//')
    if [ "$free_space" -lt 10240 ]; then # 10GB in MB
        log_error "Insufficient disk space. Required: 10GB, Available: $(($free_space/1024))GB"
        return 1
    }
    
    # Check memory (now in MB for more precision)
    local total_mem=$(free -m | awk 'NR==2 {print $2}')
    if [ "$total_mem" -lt 4096 ]; then # 4GB in MB
        log_error "Insufficient memory. Required: 4GB, Available: $(($total_mem/1024))GB"
        return 1
    }
    
    # Check required tools with proper error handling
    local required_tools=(curl wget git jq)
    local missing_tools=()
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    }
    
    return 0
}