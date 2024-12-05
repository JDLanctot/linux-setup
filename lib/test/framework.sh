#!/bin/bash

# Test framework setup
declare -A TEST_RESULTS
declare -g CURRENT_TEST=""
declare -g TEST_ROOT_DIR
declare -g TEST_TMP_DIR
declare -g TEST_LOG_DIR

init_test_framework() {
    TEST_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEST_TMP_DIR=$(mktemp -d)
    TEST_LOG_DIR="$TEST_TMP_DIR/logs"
    
    mkdir -p "$TEST_LOG_DIR"
    
    # Source mock implementations
    source "$TEST_ROOT_DIR/mocks/package_manager.sh"
    source "$TEST_ROOT_DIR/mocks/system_state.sh"
}

describe() {
    local description=$1
    echo "Running test suite: $description"
}

it() {
    local description=$1
    CURRENT_TEST="$description"
    echo "  - $description"
}

expect() {
    local result=$1
    local expected=$2
    local message=${3:-""}
    
    if [ "$result" = "$expected" ]; then
        TEST_RESULTS["$CURRENT_TEST"]="pass"
        echo "    ✓ $message"
    else
        TEST_RESULTS["$CURRENT_TEST"]="fail"
        echo "    ✗ $message (expected: $expected, got: $result)"
    fi
}

run_tests() {
    local test_files=("$@")
    local failed=0
    
    init_test_framework
    
    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            echo "Running tests from: $test_file"
            source "$test_file"
        fi
    done
    
    # Print summary
    local total=${#TEST_RESULTS[@]}
    local passed=0
    
    for result in "${TEST_RESULTS[@]}"; do
        [ "$result" = "pass" ] && ((passed++))
    done
    
    echo "Test Summary:"
    echo "Total: $total"
    echo "Passed: $passed"
    echo "Failed: $((total - passed))"
    
    [ $passed -eq $total ]
}

# Cleanup function
cleanup_tests() {
    rm -rf "$TEST_TMP_DIR"
}

trap cleanup_tests EXIT