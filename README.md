# Health Notes App

A Flutter app for tracking health notes with a chronological filing system, built with Cupertino design and Supabase backend.

## Features

- **Cupertino Design**: Native iOS-style interface with dark theme
- **Date/Time Picker**: Integrated scroll wheel picker directly in the form
- **Health Note Tracking**: Record symptoms, medications, and notes with timestamps
- **Supabase Integration**: Real-time data persistence and synchronization
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

### 3. Configure Supabase

1. Follow the instructions in `SUPABASE_SETUP.md`
2. Create a `.env` file with your Supabase credentials:
   ```
   URL=your_supabase_url
   ANON_KEY=your_supabase_anon_key
   ```

### 4. Run the App

```bash
flutter run
```

## Architecture

- **Models**: Uses Freezed for immutable data classes with JSON serialization
- **UI**: Cupertino widgets for native iOS feel
- **Backend**: Supabase for real-time database and authentication
- **State Management**: Flutter's built-in StatefulWidget for local state

## Key Components

- `MainScreen`: Root app widget with CupertinoApp configuration
- `HealthNotesHomePage`: Main screen displaying health notes list
- `AddNoteModal`: Form for adding new health notes with integrated date picker
- `HealthNote`: Freezed model for health note data

## Development

To regenerate models after changes:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```
