# Google OAuth Setup Guide for Health Notes App

This guide will help you set up Google OAuth authentication for your Health Notes Flutter app using Supabase.

## Prerequisites

- A Supabase project
- A Google Cloud Console project
- Flutter development environment

## Step 1: Google Cloud Console Setup

### 1.1 Create a Google Cloud Project (done)
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API and Google Identity API

### 1.2 Configure OAuth Consent Screen (done)
1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type
3. Fill in the required information:
   - App name: "Health Notes"
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes: `email`, `profile`, `openid`
5. Add test users (your email addresses)

### 1.3 Create OAuth 2.0 Credentials

**For Flutter App with Supabase:**
1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client IDs"
3. Choose **"Web application"** (not iOS)
4. Add authorized redirect URIs:
   - `https://xqkxzlsyqsnebxzfyvrt.supabase.co/auth/v1/callback`
5. Note down the Client ID and Client Secret

**Important**: For Supabase OAuth flow, you must use a "Web application" OAuth client, not an iOS client.



## Step 2: Supabase Configuration

### 2.1 Enable Google OAuth in Supabase
1. Go to your Supabase project dashboard
2. Navigate to "Authentication" > "Providers"
3. Enable Google provider
4. Enter your Google Client ID and Client Secret
5. Set the redirect URL to: `https://xqkxzlsyqsnebxzfyvrt.supabase.co/auth/v1/callback`

### 2.2 Configure Site URL
1. In Supabase dashboard, go to "Authentication" > "Settings"
2. Set Site URL to your app's URL (for development: `http://localhost:3000`)
3. Add additional redirect URLs if needed

### 2.3 Run Database Schema
1. Go to "SQL Editor" in your Supabase dashboard
2. Run the SQL commands from `supabase_setup.sql` file
3. This will set up:
   - Row Level Security (RLS) policies
   - User profiles table
   - Proper database indexes
   - User creation triggers

## Step 3: Flutter App Configuration

### 3.1 Environment Variables
Create a `.env` file in your project root:
```
URL=https://xqkxzlsyqsnebxzfyvrt.supabase.co
ANON_KEY=your-anon-key
GOOGLE_CLIENT_ID=514002384587-6kc0ksj5lmc3d92okoovqkflnv50v80j.apps.googleusercontent.com
```

**Important**: Replace the values with your actual credentials. The `.env` file is already in `.gitignore` to keep your secrets secure.

### 3.2 iOS Configuration
1. **No special iOS configuration needed**:
   - Supabase handles the OAuth flow through web redirects
   - No custom URL schemes or AppDelegate modifications required
   - The app uses Supabase's built-in OAuth flow

**Note**: The app uses Supabase's OAuth flow, which handles all platform-specific configurations automatically.

### 3.3 Android Configuration
1. Open `android/app/build.gradle`
2. Add your Google Services configuration
3. Download `google-services.json` from Google Cloud Console
4. Place it in `android/app/`

## Step 4: Testing the Setup

### 4.1 Test Authentication Flow
1. Run your Flutter app
2. Tap "Sign in with Google"
3. Complete the Google OAuth flow
4. Verify you're redirected back to the app
5. Check that user data is created in Supabase

### 4.2 Verify Database Security
1. Check that RLS policies are working
2. Verify users can only access their own data
3. Test that unauthenticated users cannot access data

## Step 5: Production Deployment

### 5.1 Update OAuth Configuration
1. Update Google OAuth consent screen to "Production"
2. Add your production domain to authorized redirect URIs
3. Update Supabase site URL to your production domain

### 5.2 Security Considerations
1. Ensure all RLS policies are properly configured
2. Review and test authentication flows
3. Monitor authentication logs in Supabase
4. Set up proper error handling and user feedback

## Troubleshooting

### Common Issues

1. **"Invalid redirect URI" error**
   - Check that redirect URIs match exactly in both Google Console and Supabase
   - Ensure no trailing slashes or extra characters

2. **"Client ID not found" error**
   - Verify Google Client ID is correct in Supabase
   - Check that Google+ API is enabled

3. **"User not authenticated" error**
   - Check that RLS policies are properly configured
   - Verify user_id is being set correctly in database operations

4. **iOS/Android specific issues**
   - Ensure platform-specific configurations are correct
   - Check that bundle IDs match your Google OAuth configuration

### Debug Steps

1. Check Supabase authentication logs
2. Verify Google OAuth consent screen configuration
3. Test with different Google accounts
4. Check network requests in browser developer tools

## Security Best Practices

1. **Never expose sensitive credentials** in client-side code
2. **Use environment variables** for configuration
3. **Implement proper error handling** for authentication failures
4. **Regularly review and update** OAuth consent screen settings
5. **Monitor authentication logs** for suspicious activity
6. **Implement session management** and automatic token refresh
7. **Use HTTPS** in production environments

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Flutter Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Supabase and Google Cloud Console logs
3. Verify all configuration steps were completed correctly
4. Test with a fresh Google account
5. Check for any recent changes in OAuth policies or requirements
