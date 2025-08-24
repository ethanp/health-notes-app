#!/bin/bash

# Health Notes - iPhone Deployment Script
# This script builds and installs the latest version of the app to your connected iPhone

set -e  # Exit on any error

echo "🚀 Health Notes - iPhone Deployment Script"
echo "=========================================="

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root directory."
    exit 1
fi

echo "📱 Checking for connected devices..."
flutter devices

echo ""
echo "🧹 Cleaning previous build..."
flutter clean

echo ""
echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "🔨 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo ""
echo "🏗️  Building iOS release version..."
flutter build ios --release

echo ""
echo "📱 Installing to iPhone..."
echo "Please select your iPhone when prompted:"
flutter install --release

echo ""
echo "✅ Deployment complete! 🎉"
echo ""
echo "Your Health Notes app has been updated on your iPhone."
echo "You can now disconnect your phone and use the app anywhere."
