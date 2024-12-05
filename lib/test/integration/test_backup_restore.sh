#!/bin/bash

describe "Backup and Restore"

test_config_backup() {
    it "should backup existing configurations"

    # Create test configurations
    mkdir -p "$TEST_TMP_DIR/.config/test-app"
    echo "test config" > "$TEST_TMP_DIR/.config/test-app/config"

    # Run backup
    local backup_path=$(backup_configs "$TEST_TMP_DIR/.config")
    expect "$(test -d "$backup_path")" "0" "Backup directory should exist"
    expect "$(test -f "$backup_path/test-app/config")" "0" "Config should be backed up"
}

test_config_restore() {
    it "should restore configurations from backup"

    # Create backup
    local backup_dir="$TEST_TMP_DIR/backup"
    mkdir -p "$backup_dir/test-app"
    echo "backup config" > "$backup_dir/test-app/config"

    # Restore from backup
    restore_configs "$backup_dir" "$TEST_TMP_DIR/.config"

    expect "$(cat "$TEST_TMP_DIR/.config/test-app/config")" "backup config" "Config should be restored"
}
