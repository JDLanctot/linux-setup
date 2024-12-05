#!/bin/bash

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Add lib directory to PATH
export PATH="$REPO_ROOT/lib:$PATH"

# Source the test framework
source "$REPO_ROOT/tests/framework.sh"

# Create temporary test directory
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# Find all test files
test_files=(
    "$REPO_ROOT/tests/integration/test_installers.sh"
    "$REPO_ROOT/tests/integration/test_dependencies.sh"
    "$REPO_ROOT/tests/integration/test_rollback.sh"
)

# Run the tests
run_tests "${test_files[@]}"