#!/bin/bash

# Progress UI
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[0;33m'
declare -r NC='\033[0m'

init_progress() {
    TOTAL_STEPS=$1
    CURRENT_STEP=0
    COMPONENT_STATUS=()
    
    # Check if terminal supports Unicode
    if ! locale | grep -q "UTF-8"; then
        USE_ASCII=true
    fi
}

show_progress() {
    local phase=$1
    local component=$2
    local status=$3
    
    # Get terminal width
    local term_width
    if ! term_width=$(tput cols 2>/dev/null); then
        term_width=80
    fi
    
    # Adjust box width based on terminal width
    local box_width=$((term_width - 4))
    local content_width=$((box_width - 4))
    
    # Use ASCII or Unicode based on terminal support
    local top_border bottom_border vertical
    if [ "${USE_ASCII}" = true ]; then
        top_border="+-"
        bottom_border="+-"
        vertical="|"
    else
        top_border="╔═"
        bottom_border="╚═"
        vertical="║"
    fi
    
    # Calculate progress percentage
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local width=50
    local filled=$((width * CURRENT_STEP / TOTAL_STEPS))
    
    # Clear previous lines
    printf "\033[2K"  # Clear current line
    
    # Show progress bar
    printf "\r╔════════════════════════════════════════════════════════════════╗\n"
    printf "║ Installation Progress: %-41s║\n" "$phase"
    printf "║ ["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=filled; i<width; i++)); do printf "░"; done
    printf "] %3d%%║\n" "$percentage"
    printf "║                                                                ║\n"
    printf "║ Status:                                                       ║\n"
    
    # Show component status
    local sorted_components=($(echo "${!COMPONENT_STATUS[@]}" | tr ' ' '\n' | sort))
    for comp in "${sorted_components[@]}"; do
        printf "║ • %-60s ║\n" "${comp}: ${COMPONENT_STATUS[$comp]}"
    done
    
    printf "╚════════════════════════════════════════════════════════════════╝"
}

update_progress() {
    local component=$1
    local status=$2
    COMPONENT_STATUS[$component]=$status
    ((CURRENT_STEP++))
}