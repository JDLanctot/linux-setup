#!/bin/bash

describe "Installation Stress Testing"

test_concurrent_operations() {
    it "should handle multiple concurrent operations"
    
    # Create temporary directory for test outputs
    local test_dir=$(mktemp -d)
    local pids=()
    local results=()
    
    # Start multiple installation processes
    for i in {1..3}; do
        ./install.sh -p Minimal --simulate > "$test_dir/output_$i" 2>&1 &
        pids+=($!)
    done
    
    # Wait for all processes to complete
    for pid in "${pids[@]}"; do
        wait $pid
        results+=($?)
    done
    
    # Check results
    local all_succeeded=true
    for result in "${results[@]}"; do
        if [ $result -ne 0 ]; then
            all_succeeded=false
            break
        fi
    done
    
    expect "$all_succeeded" "true" "All concurrent installations should succeed"
    
    # Cleanup
    rm -rf "$test_dir"
}

test_interrupted_installation() {
    it "should handle interruptions gracefully"
    
    # Start installation in background
    ./install.sh -p Minimal --simulate &
    local pid=$!
    
    # Wait briefly then send interrupt
    sleep 1
    kill -INT $pid
    
    # Wait for process to handle interrupt
    wait $pid || true
    
    # Verify cleanup
    expect "$(test -d /tmp/installation-*)" "1" "Temporary files should be cleaned up"
}