#!/bin/bash

describe "Installation Recovery"

setup() {
    # Save initial system state
    export INITIAL_STATE=$(mktemp)
    save_system_state > "$INITIAL_STATE"
}

teardown() {
    # Cleanup
    rm -f "$INITIAL_STATE"
}

test_failed_component_recovery() {
    it "should recover from failed component installation"
    
    # Force a component to fail
    MOCK_FAIL_COMPONENT="neovim"
    export MOCK_FAIL_COMPONENT
    
    # Attempt installation
    ./install.sh -p Minimal --simulate || true
    
    # Verify system state matches initial state
    local current_state=$(mktemp)
    save_system_state > "$current_state"
    
    local states_match=$(diff "$INITIAL_STATE" "$current_state")
    expect "$states_match" "" "System state should be restored after failure"
    
    rm -f "$current_state"
}

test_interrupted_installation_recovery() {
    it "should recover from interrupted installation"
    
    # Start installation in background
    ./install.sh -p Minimal --simulate &
    local pid=$!
    
    # Wait briefly then interrupt
    sleep 1
    kill -INT $pid
    
    # Wait for cleanup
    wait $pid || true
    
    # Verify system state
    local current_state=$(mktemp)
    save_system_state > "$current_state"
    
    local states_match=$(diff "$INITIAL_STATE" "$current_state")
    expect "$states_match" "" "System state should be restored after interruption"
    
    rm -f "$current_state"
}