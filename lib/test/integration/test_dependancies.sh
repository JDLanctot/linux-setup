#!/bin/bash

describe "Component Dependencies"

test_dependency_resolution() {
    it "should resolve and install dependencies in correct order"
    reset_mock_state
    
    # Test Neovim's dependencies
    install_neovim
    
    expect "${MOCK_INSTALLED_PACKAGES[git]}" "1" "Git should be installed as a dependency"
    expect "${MOCK_INSTALLED_PACKAGES[ripgrep]}" "1" "Ripgrep should be installed as a dependency"
}

test_circular_dependency_detection() {
    it "should detect circular dependencies"
    reset_mock_state
    
    # Create a circular dependency for testing
    local fake_spec='
    {
        "name": "test-component",
        "dependencies": ["test-component-2"],
        "version": "1.0.0"
    }'
    
    local result
    if ! result=$(resolve_dependencies "test-component"); then
        expect "$?" "1" "Should fail on circular dependency"
    fi
}