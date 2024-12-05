#!/bin/bash

describe "System Requirements"

test_disk_space_check() {
    it "should verify sufficient disk space"

    # Mock df output
    mock_df_output() {
        echo "Filesystem     1K-blocks      Used Available Use% Mounted on"
        echo "/dev/sda1      41152812   8123456  31029356  21% /"
    }

    local result=$(mock_df_output | check_disk_space)
    expect "$result" "0" "Should pass with sufficient disk space"

    # Mock insufficient space
    mock_df_output() {
        echo "Filesystem     1K-blocks      Used Available Use% Mounted on"
        echo "/dev/sda1      10152812   8123456   2029356  80% /"
    }

    result=$(mock_df_output | check_disk_space)
    expect "$result" "1" "Should fail with insufficient disk space"
}

test_required_commands() {
    it "should verify required commands exist"

    # Test with all required commands
    mock_command git true
    mock_command curl true
    result=$(check_required_commands)
    expect "$result" "0" "Should pass with all required commands"

    # Test with missing command
    mock_command git false
    result=$(check_required_commands)
    expect "$result" "1" "Should fail with missing command"
}

test_system_compatibility() {
    it "should verify system compatibility"

    # Mock Linux version
    mock_os_info() {
        echo "Linux version 5.15.0-generic"
    }

    local result=$(mock_os_info | check_system_compatibility)
    expect "$result" "0" "Should pass on compatible system"
}
