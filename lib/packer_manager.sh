#!/bin/bash

# Package manager configuration
declare -A PKG_MANAGERS
declare -g CURRENT_PKG_MANAGER=""
declare -g PKG_MANAGER_INITIALIZED=false

# Package manager definitions
init_package_managers() {
    # APT (Debian/Ubuntu)
    PKG_MANAGERS[apt]='
    {
        "check": "command -v apt-get",
        "distributions": ["debian", "ubuntu"],
        "commands": {
            "update": "sudo apt-get update",
            "upgrade": "sudo apt-get upgrade -y",
            "install": "sudo apt-get install -y",
            "remove": "sudo apt-get remove -y",
            "purge": "sudo apt-get purge -y",
            "clean": "sudo apt-get autoremove -y && sudo apt-get clean",
            "search": "apt-cache search",
            "list": "dpkg -l",
            "verify": "dpkg -s",
            "add_repo": "sudo add-apt-repository -y",
            "add_key": "sudo apt-key add -",
            "refresh": "sudo apt-get update"
        },
        "repo_types": {
            "ppa": {
                "add": "sudo add-apt-repository -y ppa:%s",
                "verify": "grep -h ^deb /etc/apt/sources.list /etc/apt/sources.list.d/*"
            },
            "deb": {
                "add": "echo \"deb %s\" | sudo tee -a /etc/apt/sources.list.d/%s.list",
                "verify": "grep -h ^deb /etc/apt/sources.list /etc/apt/sources.list.d/*"
            }
        }
    }'

    # DNF (Fedora/RHEL)
    PKG_MANAGERS[dnf]='
    {
        "check": "command -v dnf",
        "distributions": ["fedora", "rhel", "centos"],
        "commands": {
            "update": "sudo dnf check-update",
            "upgrade": "sudo dnf upgrade -y",
            "install": "sudo dnf install -y",
            "remove": "sudo dnf remove -y",
            "purge": "sudo dnf remove -y",
            "clean": "sudo dnf clean all",
            "search": "dnf search",
            "list": "dnf list installed",
            "verify": "rpm -q",
            "add_repo": "sudo dnf config-manager --add-repo",
            "add_key": "sudo rpm --import",
            "refresh": "sudo dnf makecache"
        },
        "repo_types": {
            "rpm": {
                "add": "sudo dnf config-manager --add-repo %s",
                "verify": "dnf repolist"
            }
        }
    }'

    # Pacman (Arch)
    PKG_MANAGERS[pacman]='
    {
        "check": "command -v pacman",
        "distributions": ["arch", "manjaro"],
        "commands": {
            "update": "sudo pacman -Sy",
            "upgrade": "sudo pacman -Syu --noconfirm",
            "install": "sudo pacman -S --noconfirm",
            "remove": "sudo pacman -R --noconfirm",
            "purge": "sudo pacman -Rns --noconfirm",
            "clean": "sudo pacman -Sc --noconfirm",
            "search": "pacman -Ss",
            "list": "pacman -Q",
            "verify": "pacman -Qi",
            "add_repo": "echo Adding repository to /etc/pacman.conf",
            "refresh": "sudo pacman -Syy"
        },
        "repo_types": {
            "aur": {
                "helper": "yay",
                "install": "yay -S --noconfirm",
                "verify": "yay -Qi"
            }
        }
    }'
}

# Initialize package manager system
init_package_manager() {
    if $PKG_MANAGER_INITIALIZED; then
        return 0
    }

    init_package_managers

    # Detect distribution and package manager
    local distro=$(detect_distribution)
    CURRENT_PKG_MANAGER=$(detect_package_manager "$distro")

    if [ -z "$CURRENT_PKG_MANAGER" ]; then
        log_error "No supported package manager found"
        return 1
    }

    log_info "Using package manager: $CURRENT_PKG_MANAGER for distribution: $distro"
    PKG_MANAGER_INITIALIZED=true
    return 0
}

# Detect Linux distribution
detect_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "$ID"
    elif [ -f /etc/lsb-release ]; then
        source /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Detect appropriate package manager
detect_package_manager() {
    local distro=$1
    
    for pm in "${!PKG_MANAGERS[@]}"; do
        local pm_data="${PKG_MANAGERS[$pm]}"
        local supported_distros=($(echo "$pm_data" | jq -r '.distributions[]'))
        
        for supported in "${supported_distros[@]}"; do
            if [ "$distro" = "$supported" ]; then
                # Verify package manager is actually available
                if eval "$(echo "$pm_data" | jq -r '.check')"; then
                    return "$pm"
                fi
            fi
        done
    done
    
    return 1
}

# Package management functions
pkg_cmd() {
    local cmd=$1
    shift
    local pm_data="${PKG_MANAGERS[$CURRENT_PKG_MANAGER]}"
    local cmd_template=$(echo "$pm_data" | jq -r ".commands.$cmd")
    
    if [ -z "$cmd_template" ]; then
        log_error "Unknown command: $cmd for package manager: $CURRENT_PKG_MANAGER"
        return 1
    }
    
    # Format command with arguments if necessary
    local final_cmd="$cmd_template"
    if [ $# -gt 0 ]; then
        final_cmd="$cmd_template $*"
    fi
    
    log_debug "Executing: $final_cmd"
    eval "$final_cmd"
}

# Repository management
add_repository() {
    local type=$1
    local repo=$2
    local name=$3
    
    local pm_data="${PKG_MANAGERS[$CURRENT_PKG_MANAGER]}"
    local repo_config=$(echo "$pm_data" | jq -r ".repo_types.$type // empty")
    
    if [ -z "$repo_config" ]; then
        log_error "Unsupported repository type: $type for package manager: $CURRENT_PKG_MANAGER"
        return 1
    }
    
    # Check if repository is already added
    local verify_cmd=$(echo "$repo_config" | jq -r '.verify')
    if eval "$verify_cmd" | grep -q "$repo"; then
        log_info "Repository already added: $repo"
        return 0
    }
    
    # Add repository
    local add_cmd=$(echo "$repo_config" | jq -r '.add')
    printf -v cmd "$add_cmd" "$repo" "$name"
    
    log_info "Adding repository: $repo"
    if ! eval "$cmd"; then
        log_error "Failed to add repository: $repo"
        return 1
    fi
    
    # Refresh package lists
    pkg_cmd "refresh"
    return 0
}

# Package installation with retry
pkg_install() {
    local packages=("$@")
    local max_retries=3
    local retry_delay=5
    local attempt=1
    
    while [ $attempt -le $max_retries ]; do
        if pkg_cmd "install" "${packages[@]}"; then
            return 0
        fi
        
        log_warn "Installation attempt $attempt failed, retrying in $retry_delay seconds..."
        sleep $retry_delay
        attempt=$((attempt + 1))
        retry_delay=$((retry_delay * 2))
    done
    
    log_error "Failed to install packages after $max_retries attempts: ${packages[*]}"
    return 1
}

# Verify package installation
verify_package() {
    local package=$1
    pkg_cmd "verify" "$package" >/dev/null 2>&1
}

# Clean package manager state
clean_package_manager() {
    pkg_cmd "clean"
}