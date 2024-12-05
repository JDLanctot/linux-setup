#!/bin/bash

set -euo pipefail

# Configuration
VERSION=${1:-"1.0.0"}
OUTPUT_DIR="./dist"
PACKAGE_NAME="linux-setup"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Clean any previous builds
rm -rf "$OUTPUT_DIR/*"

# Copy necessary files
cp -r \
    install.sh \
    lib \
    LICENSE \
    README.md \
    "$OUTPUT_DIR/"

# Create version file
echo "$VERSION" > "$OUTPUT_DIR/VERSION"

# Make scripts executable
chmod +x "$OUTPUT_DIR/install.sh"
find "$OUTPUT_DIR/lib" -type f -name "*.sh" -exec chmod +x {} \;

# Create tarball
tar -czf "$OUTPUT_DIR/$PACKAGE_NAME-$VERSION.tar.gz" -C "$OUTPUT_DIR" .

echo "Build completed: $OUTPUT_DIR/$PACKAGE_NAME-$VERSION.tar.gz"