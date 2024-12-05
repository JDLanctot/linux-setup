#!/bin/bash

describe "Installation Rollback"

test_failed_installation_rollback() {
    it "should rollback on failed installation"
    reset_mock_state
    
    # Create a backup of current state
    local backup_dir="$TEST_TMP_DIR/backup"
    mkdir -p "$backup_dir"
    cp -r ~/.config "$backup_dir/"
    
    # Force an installation failure
    MOCK_FORCE_FAIL=true
    install_neovim
    
    # Check if state was restored
    local config_diff=$(diff -r ~/.config "$backup_dir/.config" 2>/dev/null)
    expect "$config_diff" "" "Configuration should be restored after failed installation"
}

test_partial_installation_cleanup() {
    it "should clean up partial installations"
    reset_mock_state
    
    # Create temporary files that should be cleaned up
    mkdir -p "$TEST_TMP_DIR/partial"
    touch "$TEST_TMP_DIR/partial/test-file"
    
    # Force a failure mid-installation
    MOCK_FORCE_FAIL=true
    install_neovim
    
    expect "$(test -d "$TEST_TMP_DIR/partial")" "1" "Partial installation files should be cleaned up"
}