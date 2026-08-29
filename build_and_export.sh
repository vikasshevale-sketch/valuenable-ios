#!/bin/bash
set -e

echo "=========================================================="
echo "🚀 Building Valuenable Secure Workspace iOS App"
echo "=========================================================="

SCHEME="SecureWorkspace"
PROJECT="SecureWorkspace.xcodeproj"
ARCHIVE_PATH="./build/SecureWorkspace.xcarchive"
EXPORT_PATH="./build/ExportedApp"
EXPORT_OPTIONS_PLIST="./ExportOptions.plist"

mkdir -p ./build

# 1. Clean Build Directory
echo "🧹 Cleaning previous build..."
xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" -configuration Release

# 2. Build Archive
echo "📦 Creating Xcode Archive..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates

# 3. Export IPA
echo "📤 Exporting IPA package..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -allowProvisioningUpdates

echo "=========================================================="
echo "✅ Build Complete! IPA is located in: $EXPORT_PATH/SecureWorkspace.ipa"
echo "=========================================================="
