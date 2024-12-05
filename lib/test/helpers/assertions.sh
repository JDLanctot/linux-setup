#!/bin/bash

assert_file_exists() {
    local file=$1
    local message=${2:-"File should exist: $file"}
    test -f "$file" || fail "$message"
}

assert_directory_exists() {
    local dir=$1
    local message=${2:-"Directory should exist: $dir"}
    test -d "$dir" || fail "$message"
}

assert_package_installed() {
    local package=$1
    local message=${2:-"Package should be installed: $package"}
    verify_package "$package" || fail "$message"
}

assert_command_exists() {
    local cmd=$1
    local message=${2:-"Command should exist: $cmd"}
    command -v "$cmd" >/dev/null || fail "$message"
}
