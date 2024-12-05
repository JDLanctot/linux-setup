#!/bin/bash

describe "Full Installation"

test_minimal_profile() {
    it "should complete minimal installation successfully"

    # Run installation with minimal profile
    ./install.sh --profile minimal --simulate

    # Verify core components
    expect "$(is_component_installed "git")" "true" "Git should be installed"
    expect "$(is_component_installed "zsh")" "true" "Zsh should be installed"
}

test_standard_profile() {
    it "should complete standard installation successfully"

    # Run installation with standard profile
    ./install.sh --profile standard --simulate

    # Verify additional components
    expect "$(is_component_installed "neovim")" "true" "Neovim should be installed"
    expect "$(is_component_installed "node")" "true" "Node.js should be installed"
}
