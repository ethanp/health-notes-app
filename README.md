# Health Notes App

A Flutter app for tracking health notes with a chronological filing system, built with Cupertino design and Supabase backend. Features Google OAuth authentication for multi-user support.

## Features

- **Google OAuth Authentication**: Secure sign-in with Google accounts
- **Multi-User Support**: Each user has their own private health notes
- **Cupertino Design**: Native iOS-style interface with dark theme
- **Bottom Tab Navigation**: Standard iOS tab bar with Home and Trends views
- **Health Analytics**: Track symptom frequency, drug usage, and monthly trends
- **Date/Time Picker**: Integrated scroll wheel picker directly in the form
- **Health Note Tracking**: Record symptoms, medications, and notes with timestamps
- **Supabase Integration**: Real-time data persistence and synchronization
- **Row Level Security**: Database-level security ensuring user data privacy
- **Freezed Models**: Type-safe data models with JSON serialization

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Freezed Models

```bash
flutter packages pub run build_runner build
```

### 3. Configure Supabase and Google OAuth

1. Follow the comprehensive setup guide in `GOOGLE_OAUTH_SETUP.md`
2. Run the SQL commands from `supabase_setup.sql` in your Supabase SQL Editor
3. Create a `.env` file with your credentials:
   ```
   URL=your_supabase_url
   ANON_KEY=your_supabase_anon_key
   GOOGLE_WEB_CLIENT_ID=your_google_client_id
   ```

### 4. Run the App

```bash
flutter run
```

## Deployment

### iPhone Deployment

Deploy to your connected iPhone:

```bash
# Using the wrapper script (recommended)
./deploy_to_iphone

# Or directly with Python
python3 scripts/deploy_to_iphone.py
```

**Features:**
- ✅ Smart USB device detection
- ✅ VPN interference handling
- ✅ iPhone trust status checking
- ✅ Better error messages and troubleshooting

### iOS Simulator Deployment

Deploy to iOS Simulator for testing:

```bash
# Using the wrapper script
./deploy_to_simulator

# Or directly with Python
python3 scripts/deploy_to_simulator.py
```

### Troubleshooting

- **VPN Issues**: The script detects VPN interference and provides workarounds
- **Device Trust**: Guides you through trusting your Mac on your iPhone
- **Developer Mode**: Ensures Developer Mode is enabled on your device

See `scripts/README.md` for detailed troubleshooting and advanced usage.

## Architecture

- **Models**: Uses Freezed for immutable data classes with JSON serialization
- **UI**: Cupertino widgets for native iOS feel
- **Backend**: Supabase for real-time database and authentication
- **State Management**: Riverpod for reactive state management
- **Authentication**: Google OAuth with Supabase Auth
- **Security**: Row Level Security (RLS) policies for data isolation

## Key Components

- `MainScreen`: Root app widget with CupertinoApp configuration
- `MainTabScreen`: Bottom tab navigation with Home and Trends views
- `AuthScreen`: Google OAuth sign-in screen
- `HealthNotesHomePage`: Main screen displaying health notes list
- `TrendsScreen`: Analytics view showing symptom frequency and health trends
- `AddNoteModal`: Form for adding new health notes with integrated date picker
- `AuthService`: Handles Google OAuth authentication with Supabase
- `HealthNote`: Freezed model for health note data

## Development

To regenerate models after changes:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

# App Icon Assets

This directory contains the source files and generation scripts for the Health Notes app icons.

## Files

- `base_icon_img.png` - Source PNG image for the app icon (1024x1024 recommended)
- `generate_ios_icons.sh` - Script to generate all iOS icon sizes
- `health_notes_icon.svg` - Previous SVG source file (kept for reference)
- `README.md` - This documentation file

## Icon Design

The app icon is based on the `base_icon_img.png` file, which should be:
- **1024x1024 pixels** for best quality
- **Square format** with rounded corners (iOS will apply the corner radius)
- **High contrast** for visibility at small sizes
- **Simple, bold shapes** that work well when scaled down

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

## Updating the Icon

To update the app icon:
1. Replace `base_icon_img.png` with your new 1024x1024 PNG image
2. Run `./generate_ios_icons.sh` to regenerate all icon sizes
3. The new icons will automatically replace the existing ones
