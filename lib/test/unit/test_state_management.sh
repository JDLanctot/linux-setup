#!/bin/bash

describe "Package Manager"

test_package_manager_detection() {
    it "should detect correct package manager"

    # Mock /etc/os-release for different distributions
    mock_os_release() {
        local content=$1
        echo "$content" > "$TEST_TMP_DIR/os-release"
        export MOCK_OS_RELEASE_PATH="$TEST_TMP_DIR/os-release"
    }

    # Test Ubuntu detection
    mock_os_release "ID=ubuntu"
    local pm=$(detect_package_manager)
    expect "$pm" "apt" "Should detect apt for Ubuntu"

    # Test Fedora detection
    mock_os_release "ID=fedora"
    pm=$(detect_package_manager)
    expect "$pm" "dnf" "Should detect dnf for Fedora"

    # Test Arch detection
    mock_os_release "ID=arch"
    pm=$(detect_package_manager)
    expect "$pm" "pacman" "Should detect pacman for Arch"
}
