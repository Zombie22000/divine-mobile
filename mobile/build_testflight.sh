#!/bin/bash

# Build script for iOS TestFlight deployment with crash reporting
# ABOUTME: Builds iOS release for TestFlight with proper configuration and auto-increments build number

set -e

echo "🚀 Building OpenVine for TestFlight deployment..."

# Increment build number in pubspec.yaml
echo "📈 Incrementing build number..."
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | cut -d'+' -f2)
NEW_BUILD_NUMBER=$((CURRENT_VERSION + 1))
sed -i.bak "s/^version: \(.*\)+.*/version: \1+${NEW_BUILD_NUMBER}/" pubspec.yaml
rm pubspec.yaml.bak
echo "   Build number: ${CURRENT_VERSION} → ${NEW_BUILD_NUMBER}"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
rm -rf build/ios/archive build/ios/ipa
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run code generation if needed
echo "⚙️ Running code generation..."
dart run build_runner build --delete-conflicting-outputs

# Build iOS archive
echo "🏗️ Building iOS archive..."
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist \
  --dart-define=ENVIRONMENT=testflight \
  --dart-define=ENABLE_CRASHLYTICS=true

# Export IPA from archive
echo "📦 Exporting IPA for App Store distribution..."
mkdir -p build/ios/ipa
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist

# Verify IPA was created
if [ -f "build/ios/ipa/divine.ipa" ]; then
  IPA_SIZE=$(du -h "build/ios/ipa/divine.ipa" | cut -f1)
  echo ""
  echo "✅ Build complete!"
  echo ""
  echo "📱 IPA Details:"
  echo "   File: build/ios/ipa/divine.ipa"
  echo "   Size: ${IPA_SIZE}"
  echo "   Build: ${NEW_BUILD_NUMBER}"
  echo ""
  echo "📤 Upload to TestFlight with Transporter:"
  echo "   open -a Transporter build/ios/ipa/divine.ipa"
  echo ""
  echo "   Or use command line upload with altool:"
  echo "   xcrun altool --upload-app --type ios --file build/ios/ipa/divine.ipa \\"
  echo "     --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
  echo ""
  echo "🔍 Crash reports will appear in Firebase Console:"
  echo "   https://console.firebase.google.com/project/openvine-placeholder/crashlytics"
else
  echo ""
  echo "❌ Error: IPA file not found at build/ios/ipa/divine.ipa"
  exit 1
fi