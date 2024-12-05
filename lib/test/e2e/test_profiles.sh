#!/bin/bash

describe "Installation Profiles"

test_minimal_profile_components() {
    it "should install correct components for minimal profile"

    ./install.sh --profile minimal --simulate

    # Check core components
    local required_components=("git" "zsh")
    for component in "${required_components[@]}"; do
        expect "$(is_component_installed "$component")" "true" "Required component $component should be installed"
    done

    # Check optional components aren't installed
    local optional_components=("neovim" "node")
    for component in "${optional_components[@]}"; do
        expect "$(is_component_installed "$component")" "false" "Optional component $component should not be installed"
    done
}

test_standard_profile_dependencies() {
    it "should resolve dependencies correctly for standard profile"

    ./install.sh --profile standard --simulate

    # Check dependency chain
    expect "$(is_component_installed "git")" "true" "Git should be installed before Neovim"
    expect "$(is_component_installed "neovim")" "true" "Neovim should be installed after dependencies"
}

test_full_profile_optional_components() {
    it "should install optional components in full profile"

    ./install.sh --profile full --simulate

    # Check optional components are installed
    local optional_components=("alacritty" "i3")
    for component in "${optional_components[@]}"; do
        expect "$(is_component_installed "$component")" "true" "Optional component $component should be installed"
    done
}
