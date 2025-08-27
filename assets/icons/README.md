# App Icon Assets

This directory contains the source files and generation scripts for the Health Notes app icons.

## Files

- `health_notes_icon.svg` - Source SVG file for the app icon
- `generate_ios_icons.sh` - Script to generate all iOS icon sizes
- `README.md` - This documentation file

## Icon Design

The app icon features:
- **Medical cross** - Large, prominent white cross representing healthcare
- **Note paper** - Large white paper with simple purple lines representing health notes
- **Heart icon** - Purple heart symbolizing health and wellness
- **Purple-blue gradient background** - Matches the app's primary color scheme

## Generating Icons

### Prerequisites

Install ImageMagick:
```bash
brew install imagemagick
```

### Generate iOS Icons

1. Navigate to this directory:
   ```bash
   cd assets/icons
   ```

2. Make the script executable (if needed):
   ```bash
   chmod +x generate_ios_icons.sh
   ```

3. Run the generation script:
   ```bash
   ./generate_ios_icons.sh
   ```

This will generate all required iOS icon sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

## Icon Sizes Generated

- **iPhone**: 20x20, 29x29, 40x40, 60x60 (1x, 2x, 3x scales)
- **iPad**: 20x20, 29x29, 40x40, 76x76, 83.5x83.5 (1x, 2x scales)
- **App Store**: 1024x1024

## Design Principles

The icon follows Apple's design guidelines:
- Large, simple shapes that are easily recognizable at small sizes
- High contrast for visibility
- Minimal detail that scales well
- Consistent with iOS app icon conventions
