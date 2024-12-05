#!/bin/bash

# Define installation profiles with dependencies and requirements
declare -A INSTALLATION_PROFILES=(
    ["Minimal"]='
    {
        "description": "Basic development environment setup",
        "groups": ["Core"],
        "required": true,
        "order": 1
    }'
    ["Standard"]='
    {
        "description": "Complete development environment with common tools",
        "groups": ["Core", "Shell", "Development", "Tools"],
        "required": false,
        "order": 2,
        "inherit": "Minimal"
    }'
    ["Full"]='
    {
        "description": "Complete development environment with all tools",
        "groups": ["Core", "Shell", "Development", "Tools", "Optional"],
        "required": false,
        "order": 3,
        "inherit": "Standard",
        "make_all_required": true
    }'
)

# Define component groups with dependencies
declare -A COMPONENT_GROUPS=(
    ["Core"]='
    {
        "components": ["git", "zsh", "starship"],
        "required": true,
        "order": 1
    }'
    ["Shell"]='
    {
        "components": ["alacritty", "i3"],
        "required": false,
        "order": 2,
        "dependencies": ["Core"]
    }'
    ["Development"]='
    {
        "components": ["neovim", "node", "julia", "zig"],
        "required": false,
        "order": 3,
        "dependencies": ["Core"]
    }'
    ["Tools"]='
    {
        "components": ["ag", "bat", "fzf", "zoxide", "ripgrep"],
        "required": false,
        "order": 4
    }'
    ["Optional"]='
    {
        "components": ["conda"],
        "required": false,
        "order": 5
    }'
)

declare -A PROFILE_CACHE

# Get profile information
get_profile_info() {
    local profile=$1
    echo "${INSTALLATION_PROFILES[$profile]}"
}

# Get group information
get_group_info() {
    local group=$1
    echo "${COMPONENT_GROUPS[$group]}"
}

# Get components for a profile
get_profile_components() {
    local profile=$1
    local profile_info=$(get_profile_info "$profile")
    local components=()
    
    # Get base profile components if inheriting
    local inherit=$(echo "$profile_info" | jq -r '.inherit // empty')
    if [ -n "$inherit" ]; then
        components+=($(get_profile_components "$inherit"))
    fi
    
    # Get groups for this profile
    local groups=($(echo "$profile_info" | jq -r '.groups[]'))
    
    # Add components from each group
    for group in "${groups[@]}"; do
        local group_info=$(get_group_info "$group")
        components+=($(echo "$group_info" | jq -r '.components[]'))
    done
    
    # Remove duplicates and return
    echo "${components[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

# Check if a component is required for a profile
is_required() {
    local component=$1
    local profile=$2
    
    local profile_info=$(get_profile_info "$profile")
    local make_all_required=$(echo "$profile_info" | jq -r '.make_all_required // false')
    
    if [ "$make_all_required" = "true" ]; then
        return 0
    fi
    
    # Check if component's group is required
    local group=$(find_component_group "$component")
    if [ -n "$group" ]; then
        local group_info=$(get_group_info "$group")
        local group_required=$(echo "$group_info" | jq -r '.required')
        [ "$group_required" = "true" ] && return 0
    fi
    
    return 1
}

# Find which group a component belongs to
find_component_group() {
    local component=$1
    for group in "${!COMPONENT_GROUPS[@]}"; do
        local group_info="${COMPONENT_GROUPS[$group]}"
        if echo "$group_info" | jq -r '.components[]' | grep -q "^$component$"; then
            echo "$group"
            return 0
        fi
    done
    return 1
}

# Get installation order for components
get_installation_order() {
    local profile=$1
    local components=($(get_profile_components "$profile"))
    local ordered_components=()
    
    # Sort components by their group's order
    for component in "${components[@]}"; do
        local group=$(find_component_group "$component")
        local order=999
        if [ -n "$group" ]; then
            order=$(echo "${COMPONENT_GROUPS[$group]}" | jq -r '.order')
        fi
        ordered_components+=("$order:$component")
    done
    
    # Sort by order and strip order number
    echo "${ordered_components[@]}" | tr ' ' '\n' | sort -n | cut -d: -f2 | tr '\n' ' '
}

# Get total number of steps for progress tracking
get_total_steps() {
    local profile=$1
    local components=($(get_profile_components "$profile"))
    echo "${#components[@]}"
}

init_profiles() {
    # Load and validate all profiles
    for profile in "${!INSTALLATION_PROFILES[@]}"; do
        if ! validate_profile "$profile"; then
            log_error "Invalid profile configuration: $profile"
            return 1
        fi
    done
    
    # Build profile inheritance chain
    build_profile_inheritance
}

validate_profile() {
    local profile=$1
    local profile_data="${INSTALLATION_PROFILES[$profile]}"
    
    # Validate JSON structure
    if ! echo "$profile_data" | jq empty 2>/dev/null; then
        return 1
    }
    
    # Validate required fields
    local required_fields=("description" "groups" "order")
    for field in "${required_fields[@]}"; do
        if ! echo "$profile_data" | jq -e "has(\"$field\")" >/dev/null; then
            return 1
        fi
    done
    
    # Validate group references
    local groups=($(echo "$profile_data" | jq -r '.groups[]'))
    for group in "${groups[@]}"; do
        if [ -z "${COMPONENT_GROUPS[$group]}" ]; then
            return 1
        fi
    done
    
    return 0
}

build_profile_inheritance() {
    for profile in "${!INSTALLATION_PROFILES[@]}"; do
        local inherited_components=($(resolve_profile_inheritance "$profile"))
        PROFILE_CACHE[$profile]="${inherited_components[*]}"
    done
}

resolve_profile_inheritance() {
    local profile=$1
    local profile_data="${INSTALLATION_PROFILES[$profile]}"
    local components=()
    
    # Get base profile components if inheriting
    local base_profile=$(echo "$profile_data" | jq -r '.inherit // empty')
    if [ -n "$base_profile" ]; then
        components+=($(resolve_profile_inheritance "$base_profile"))
    fi
    
    # Add components from this profile's groups
    local groups=($(echo "$profile_data" | jq -r '.groups[]'))
    for group in "${groups[@]}"; do
        local group_components=($(get_group_components "$group"))
        components+=("${group_components[@]}")
    done
    
    # Remove duplicates and return
    echo "$(echo "${components[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
}

get_profile_components() {
    local profile=$1
    
    # Return cached result if available
    if [ -n "${PROFILE_CACHE[$profile]}" ]; then
        echo "${PROFILE_CACHE[$profile]}"
        return 0
    fi
    
    # Calculate components if not cached
    local components=($(resolve_profile_inheritance "$profile"))
    PROFILE_CACHE[$profile]="${components[*]}"
    echo "${components[*]}"
}

is_component_required() {
    local component=$1
    local profile=$2
    
    local profile_data="${INSTALLATION_PROFILES[$profile]}"
    
    # Check if profile makes all components required
    if [ "$(echo "$profile_data" | jq -r '.make_all_required // false')" = "true" ]; then
        return 0
    fi
    
    # Check component's group requirement
    local group=$(find_component_group "$component")
    if [ -n "$group" ]; then
        local group_data="${COMPONENT_GROUPS[$group]}"
        if [ "$(echo "$group_data" | jq -r '.required // false')" = "true" ]; then
            return 0
        fi
    fi
    
    return 1
}