#!/bin/bash

describe "Component Installers"

# Test Neovim installation
test_neovim_installation() {
    it "should install Neovim and its dependencies"
    reset_mock_state
    
    install_neovim
    
    expect "${MOCK_INSTALLED_PACKAGES[neovim]}" "1" "Neovim should be installed"
    expect "${MOCK_INSTALLED_PACKAGES[ninja-build]}" "1" "Build dependencies should be installed"
    expect "$(test -d ~/.config/nvim)" "0" "Neovim config directory should exist"
}

# Test Node.js installation
test_node_installation() {
    it "should install Node.js and pnpm"
    reset_mock_state
    
    install_node
    
    expect "${MOCK_INSTALLED_PACKAGES[nodejs]}" "1" "Node.js should be installed"
    expect "$(command -v pnpm)" "0" "pnpm should be installed"
}

# Test Git installation
test_git_installation() {
    it "should install and configure Git"
    reset_mock_state
    
    # Mock git config
    GIT_EMAIL="test@example.com"
    GIT_NAME="Test User"
    
    install_git
    
    expect "${MOCK_INSTALLED_PACKAGES[git]}" "1" "Git should be installed"
    expect "$(test -f ~/.ssh/id_ed25519)" "0" "SSH key should be generated"
}

# Test CLI tools installation
test_cli_tools_installation() {
    it "should install all CLI tools"
    reset_mock_state
    
    install_cli_tools
    
    local tools=(
        "unzip"
        "bat"
        "fzf"
        "zoxide"
        "ripgrep"
        "fd-find"
    )
    
    local all_installed=true
    for tool in "${tools[@]}"; do
        if [ -z "${MOCK_INSTALLED_PACKAGES[$tool]}" ]; then
            all_installed=false
            break
        fi
    done
    
    expect "$all_installed" "true" "All CLI tools should be installed"
}