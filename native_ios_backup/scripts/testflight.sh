#!/bin/zsh
# Archives the Release build and uploads it to App Store Connect / TestFlight.
# Requires: the Apple ID for team UZMK9VPGZ7 signed in to Xcode, and an App Store Connect
# app record with bundle ID com.raemulanlands.tahanan.
set -euo pipefail
cd "$(dirname "$0")/.."
xcodegen generate
xcodebuild -project Tahanan.xcodeproj -scheme Tahanan -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Tahanan.xcarchive -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath build/Tahanan.xcarchive \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath build/export -allowProvisioningUpdates
