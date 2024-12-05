#!/bin/bash

describe "Installation Performance"

test_minimal_installation_performance() {
    it "should complete minimal installation within acceptable time"
    
    # Record start time
    start_time=$(date +%s)
    
    # Run minimal installation in simulation mode
    ./install.sh -p Minimal --simulate
    
    # Calculate duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Test should complete within 5 minutes
    expect $duration -lt 300 "Installation should complete within 5 minutes"
}

test_memory_usage() {
    it "should maintain acceptable memory usage"
    
    # Get initial memory usage
    initial_memory=$(ps -o rss= -p $$)
    
    # Run standard installation in simulation mode
    ./install.sh -p Standard --simulate
    
    # Get final memory usage
    final_memory=$(ps -o rss= -p $$)
    
    # Calculate memory increase in MB
    memory_increase=$(( (final_memory - initial_memory) / 1024 ))
    
    # Should use less than 500MB additional memory
    expect $memory_increase -lt 500 "Memory usage increase should be less than 500MB"
}