# Google Drive OAuth Setup Guide

## Issue: "You can't sign in because this app sent an invalid request"

This error occurs when the localhost redirect URI used by Flutter isn't registered in your Google Cloud Console.

## Quick Fix for Development

### Option 1: Add Localhost URIs to Google Cloud Console (Recommended)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **bigbys-management**
3. Navigate to **APIs & Services** → **Credentials**
4. Find and click your OAuth 2.0 Client ID: `1015708422039-uik2ehutdgj9ophrts6s2ihfgd7i9icc.apps.googleusercontent.com`
5. Under **Authorized redirect URIs**, add these localhost variants:
   ```
   http://localhost:5000/
   http://localhost:8080/
   http://localhost:3000/
   http://localhost:65000/
   http://localhost:65001/
   http://localhost:65002/
   http://localhost:65003/
   http://localhost:65004/
   http://localhost:65005/
   http://localhost:65100/
   http://localhost:65200/
   http://localhost:65300/
   http://localhost:65400/
   http://localhost:65500/
   http://localhost:65600/
   http://127.0.0.1:5000/
   http://127.0.0.1:8080/
   ```
6. Click **Save**
7. Run your app again: `flutter run -d chrome`

### Option 2: Use a Fixed Port

Run Flutter on a fixed port to avoid the authorization issue:

```bash
flutter run -d chrome --web-port=5000
```

Then add only `http://localhost:5000/` and `http://127.0.0.1:5000/` to the Google Cloud Console authorized redirect URIs.

## OAuth Scopes

Your app requests the **Google Drive full access scope** (`https://www.googleapis.com/auth/drive`):
- Allows reading, creating, and deleting files in Google Drive
- Used for uploading attachments and profile pictures

## Verify OAuth Consent Screen

1. In Google Cloud Console, go to **APIs & Services** → **OAuth consent screen**
2. Ensure it's configured with:
   - **App name**: TeamCollab
   - **User support email**: Your email
   - **Developer contact**: Your email
3. Add these scopes if not present:
   - `https://www.googleapis.com/auth/drive` (Google Drive)
4. In the **Test users** section, add your Google account

## Files Modified

- `web/index.html` - Web OAuth client ID configuration
- `lib/services/google_drive_service.dart` - Google Drive API initialization
- `pubspec.yaml` - Dependencies (google_sign_in, googleapis)

## Troubleshooting

| Error | Solution |
|-------|----------|
| "invalid request" | Add localhost URI to Google Cloud Console authorized redirect URIs |
| "popup_closed" | User closed the sign-in popup or browser blocked it |
| "access_denied" | User hasn't granted the app permission to access Google Drive |
| "invalid_scope" | Scope not approved in OAuth consent screen |

## Testing

Once configured:
1. Run the app: `flutter run -d chrome`
2. Upload a profile picture → Should appear in Google Drive `team_collab_attachments` folder
3. Upload an attachment to a task → Should also appear in the same folder
4. Check Firestore `file_metadata` collection for upload records

