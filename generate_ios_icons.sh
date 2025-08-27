#!/bin/bash

# Generate iOS app icons from PNG base image
# This script requires ImageMagick to be installed

echo "Generating iOS app icons from PNG base image..."

# Create output directory
mkdir -p ../../ios/Runner/Assets.xcassets/AppIcon.appiconset

# Generate all required iOS icon sizes
echo "Generating 1024x1024 App Store icon..."
magick base_icon_img.png -resize 1024x1024 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

echo "Generating iPhone icons..."
magick base_icon_img.png -resize 40x40 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
magick base_icon_img.png -resize 60x60 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
magick base_icon_img.png -resize 29x29 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
magick base_icon_img.png -resize 58x58 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
magick base_icon_img.png -resize 87x87 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
magick base_icon_img.png -resize 80x80 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
magick base_icon_img.png -resize 120x120 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
magick base_icon_img.png -resize 120x120 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
magick base_icon_img.png -resize 180x180 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png

echo "Generating iPad icons..."
magick base_icon_img.png -resize 20x20 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
magick base_icon_img.png -resize 40x40 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
magick base_icon_img.png -resize 29x29 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
magick base_icon_img.png -resize 58x58 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
magick base_icon_img.png -resize 40x40 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
magick base_icon_img.png -resize 80x80 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
magick base_icon_img.png -resize 76x76 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
magick base_icon_img.png -resize 152x152 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
magick base_icon_img.png -resize 167x167 ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png

echo "All iOS app icons generated successfully!"
echo "Icons saved to: ../../ios/Runner/Assets.xcassets/AppIcon.appiconset/"
