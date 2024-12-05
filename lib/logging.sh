#!/bin/bash

# Log levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["FATAL"]=4
)

# Default log level
CURRENT_LOG_LEVEL=${LOG_LEVELS["INFO"]}

# Colors for terminal output
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[0;33m'
declare -r BLUE='\033[0;34m'
declare -r PURPLE='\033[0;35m'
declare -r CYAN='\033[0;36m'
declare -r GRAY='\033[0;90m'
declare -r NC='\033[0m'

init_logging() {
    local log_dir="${1:-$HOME/.dotfiles/logs}"
    local log_file="install_$(date +%Y%m%d_%H%M%S).log"
    LOG_FILE="$log_dir/$log_file"
    
    # Create log directory
    mkdir -p "$log_dir" || {
        echo "Failed to create log directory: $log_dir"
        exit 1
    }
    
    # Initialize log file with header
    {
        echo "=== Installation Log Started at $(date) ==="
        echo "System Information:"
        echo "- OS: $(uname -a)"
        echo "- Shell: $SHELL"
        echo "- User: $USER"
        echo "- Home: $HOME"
        echo "- PWD: $PWD"
        echo "=== Begin Log ==="
    } > "$LOG_FILE"
    
    # Set up error trapping
    trap '_handle_error ${LINENO} ${?}' ERR
}

set_log_level() {
    local level=$1
    if [ -n "${LOG_LEVELS[$level]}" ]; then
        CURRENT_LOG_LEVEL=${LOG_LEVELS[$level]}
    fi
}

should_log() {
    local level=$1
    [ ${LOG_LEVELS[$level]} -ge $CURRENT_LOG_LEVEL ]
}

log() {
    local level=$1
    local message=$2
    local context=${3:-}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if should_log "$level"; then
        # Format message with context if provided
        local formatted="[$timestamp] [$level] ${context:+($context) }$message"
        
        # Write to log file
        echo "$formatted" >> "$LOG_FILE"
        
        # Write to console with color if appropriate
        if [ -t 1 ]; then  # Check if stdout is a terminal
            local color=""
            case $level in
                "ERROR") color="$RED" ;;
                "WARN")  color="$YELLOW" ;;
                "INFO")  color="$BLUE" ;;
                "DEBUG") color="$GRAY" ;;
                "FATAL") color="$RED" ;;
                *)       color="$NC" ;;
            esac
            echo -e "${color}${formatted}${NC}"
        else
            echo "$formatted"
        fi
    fi
}

# Helper functions for different log levels
log_debug() { log "DEBUG" "$1" "$2"; }
log_info() { log "INFO" "$1" "$2"; }
log_warn() { log "WARN" "$1" "$2"; }
log_error() { log "ERROR" "$1" "$2"; }
log_fatal() { log "FATAL" "$1" "$2"; exit 1; }

# Error handler
_handle_error() {
    local line=$1
    local exit_code=$2
    local command="${BASH_COMMAND}"
    
    log_error "Command '${command}' failed with exit code ${exit_code} at line ${line}"
    
    # Get stack trace
    local frame=0
    local trace=""
    while caller $frame; do
        ((frame++))
    done | while read -r line sub file; do
        trace+="  at ${sub} (${file}:${line})\n"
    done
    
    log_error "Stack trace:\n${trace}"
    
    # Handle cleanup if needed
    if [ "$(type -t cleanup_and_exit)" == "function" ]; then
        cleanup_and_exit $exit_code
    else
        exit $exit_code
    fi
}

# Function to create a structured log entry
log_structured() {
    local level=$1
    local component=$2
    local operation=$3
    local message=$4
    local details=$5
    
    local json_entry=$(jq -n \
        --arg timestamp "$(date -Iseconds)" \
        --arg level "$level" \
        --arg component "$component" \
        --arg operation "$operation" \
        --arg message "$message" \
        --arg details "$details" \
        '{timestamp: $timestamp, level: $level, component: $component, operation: $operation, message: $message, details: $details}')
    
    echo "$json_entry" >> "${LOG_FILE}.json"
    log "$level" "$message" "$component"
}

# Signal handling
trap_signals() {
    trap 'log_warn "Received SIGINT - cleaning up..." "SignalHandler"; cleanup_and_exit 130' SIGINT
    trap 'log_warn "Received SIGTERM - cleaning up..." "SignalHandler"; cleanup_and_exit 143' SIGTERM
    trap 'log_error "Received SIGQUIT - forcing exit..." "SignalHandler"; cleanup_and_exit 131' SIGQUIT
}