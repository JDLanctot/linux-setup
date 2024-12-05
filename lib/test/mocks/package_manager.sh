#!/bin/bash

# Mock package manager state
declare -A MOCK_INSTALLED_PACKAGES
declare -A MOCK_REPOSITORIES
declare -g MOCK_PKG_MANAGER="apt"

# Mock package manager functions
pkg_install() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        MOCK_INSTALLED_PACKAGES[$pkg]=1
    done
    return 0
}

pkg_remove() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        unset MOCK_INSTALLED_PACKAGES[$pkg]
    done
    return 0
}

verify_package() {
    local package=$1
    [ -n "${MOCK_INSTALLED_PACKAGES[$package]}" ]
}

add_repository() {
    local type=$1
    local repo=$2
    MOCK_REPOSITORIES["$type:$repo"]=1
    return 0
}

# Mock system commands
command_exists() {
    local cmd=$1
    [ -n "${MOCK_INSTALLED_PACKAGES[$cmd]}" ]
}

reset_mock_state() {
    MOCK_INSTALLED_PACKAGES=()
    MOCK_REPOSITORIES=()
}