# Health Notes App

A Flutter app for tracking health notes with a chronological filing system, built with Cupertino design and Supabase backend. Features Google OAuth authentication for multi-user support.

## Features

- **Google OAuth Authentication**: Secure sign-in with Google accounts
- **Multi-User Support**: Each user has their own private health notes
- **Cupertino Design**: Native iOS-style interface with dark theme
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
   GOOGLE_CLIENT_ID=your_google_client_id
   ```

### 4. Run the App

```bash
flutter run
```

## Architecture

- **Models**: Uses Freezed for immutable data classes with JSON serialization
- **UI**: Cupertino widgets for native iOS feel
- **Backend**: Supabase for real-time database and authentication
- **State Management**: Riverpod for reactive state management
- **Authentication**: Google OAuth with Supabase Auth
- **Security**: Row Level Security (RLS) policies for data isolation

## Key Components

- `MainScreen`: Root app widget with CupertinoApp configuration
- `AuthWrapper`: Handles authentication state and routing
- `AuthScreen`: Google OAuth sign-in screen
- `HealthNotesHomePage`: Main screen displaying health notes list
- `AddNoteModal`: Form for adding new health notes with integrated date picker
- `AuthService`: Handles Google OAuth authentication with Supabase
- `HealthNote`: Freezed model for health note data

## Development

To regenerate models after changes:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```
