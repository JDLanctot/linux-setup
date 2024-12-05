#!/bin/bash

describe "Installation Arguments"

test_argument_parsing() {
    it "should correctly parse installation arguments"

    # Test default arguments
    local result=$(./install.sh --simulate)
    expect "$?" "0" "Should run with default arguments"

    # Test profile selection
    result=$(./install.sh --profile minimal --simulate)
    expect "$?" "0" "Should accept profile argument"

    # Test force flag
    result=$(./install.sh --force --simulate)
    expect "$?" "0" "Should accept force flag"

    # Test invalid profile
    result=$(./install.sh --profile invalid --simulate)
    expect "$?" "1" "Should fail with invalid profile"

    # Test incompatible flags
    result=$(./install.sh --profile minimal --profile standard --simulate)
    expect "$?" "1" "Should fail with incompatible flags"
}

test_help_output() {
    it "should display help information"

    local help_output=$(./install.sh --help)
    expect "$(echo "$help_output" | grep -c "Usage:")" "1" "Should show usage information"
    expect "$(echo "$help_output" | grep -c "Options:")" "1" "Should show options information"
}
