#!/bin/bash

# Copy Narro.app to ~/Applications after successful build
# This script runs automatically as part of the Xcode build process

APP_NAME="Narro.app"
BUILD_APP="${BUILT_PRODUCTS_DIR}/${APP_NAME}"
DEST_DIR="${HOME}/Applications"

echo "========================================"
echo "Copying ${APP_NAME} to Applications..."
echo "========================================"

# Create ~/Applications if it doesn't exist
mkdir -p "${DEST_DIR}"

# Kill any running instances
killall Narro 2>/dev/null || true

# Copy the built app
if [ -d "${BUILD_APP}" ]; then
    echo "Source: ${BUILD_APP}"
    echo "Destination: ${DEST_DIR}/${APP_NAME}"

    # Remove old version if it exists
    rm -rf "${DEST_DIR}/${APP_NAME}"

    # Copy new version
    cp -R "${BUILD_APP}" "${DEST_DIR}/"

    if [ $? -eq 0 ]; then
        echo "✓ Successfully copied ${APP_NAME} to ${DEST_DIR}"
        echo "✓ You can now launch Narro from Applications"
    else
        echo "✗ Failed to copy ${APP_NAME}"
        exit 1
    fi
else
    echo "✗ Error: Built app not found at ${BUILD_APP}"
    exit 1
fi

echo "========================================"
