#!/bin/bash

describe "Release Verification"

test_package_contents() {
    it "should have all required files"
    
    # Build package
    ./build.sh "1.0.0"
    
    # Create temp dir for extraction
    local test_dir=$(mktemp -d)
    tar -xzf "./dist/linux-setup-1.0.0.tar.gz" -C "$test_dir"
    
    # Verify required files
    local required_files=(
        "install.sh"
        "lib/components/installer.sh"
        "lib/state.sh"
        "lib/logging.sh"
        "LICENSE"
        "README.md"
    )
    
    local all_files_present=true
    for file in "${required_files[@]}"; do
        if [ ! -f "$test_dir/$file" ]; then
            all_files_present=false
            break
        fi
    done
    
    expect "$all_files_present" "true" "All required files should be present"
    
    # Verify executables
    expect "$(test -x "$test_dir/install.sh")" "0" "install.sh should be executable"
    
    # Cleanup
    rm -rf "$test_dir"
}

test_version_consistency() {
    it "should have consistent version information"
    
    local version="1.0.0"
    ./build.sh "$version"
    
    local test_dir=$(mktemp -d)
    tar -xzf "./dist/linux-setup-$version.tar.gz" -C "$test_dir"
    
    # Check version file
    local package_version=$(cat "$test_dir/VERSION")
    expect "$package_version" "$version" "Version file should match build version"
    
    # Cleanup
    rm -rf "$test_dir"
}