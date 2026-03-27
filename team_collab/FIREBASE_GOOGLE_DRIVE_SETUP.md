# Firebase + Google Drive Integration Setup Guide

## Overview

Your Flutter app now uses a hybrid storage architecture:
- **Google Drive**: Primary file storage (images, PDFs, attachments)
- **Firebase Firestore**: Database for metadata and links
- **Firebase Storage**: Optional, kept for backward compatibility

## Architecture

```
User Upload
    ↓
    ├→ Google Drive Service (uploads file)
    │    ├→ Creates "team_collab_attachments" folder
    │    ├→ Uploads file
    │    ├→ Makes file publicly shareable
    │    └→ Returns shareable link
    │
    ├→ File Storage Service (stores metadata)
    │    └→ Saves link + metadata to Firestore
    │         (file_metadata collection)
    │
    └→ Task Provider (updates app state)
         └→ Associates attachment with task
```

## Setup Steps

### 1. Ensure Dependencies
All required packages are already in your `pubspec.yaml`:
- ✅ `google_sign_in: ^6.2.1`
- ✅ `googleapis: ^13.2.0`
- ✅ `cloud_firestore: ^5.6.2`
- ✅ `firebase_core: ^3.10.1`

### 2. Configure Google OAuth (Google Cloud Console)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Enable **Google Drive API**:
   - APIs & Services → Library
   - Search for "Google Drive API"
   - Click Enable

4. Create OAuth 2.0 credentials:
   - APIs & Services → Credentials
   - Create OAuth 2.0 Client ID
   - Application type: **Web** (for web platform)
   - Add redirect URIs:
     - For web: `http://localhost:3000` (development)
     - For production: your domain

5. For Android:
   - Create OAuth 2.0 Client ID (Android)
   - Follow the setup wizard with your SHA-1 fingerprint
   - Download JSON config (automatically handled by google-services.json)

6. For iOS:
   - Create OAuth 2.0 Client ID (iOS)
   - Add your Bundle ID

### 3. Configure Google Sign-In

#### For Web (`web/index.html`):
```html
<script src="https://accounts.google.com/gsi/client" async defer></script>
<script>
  function onLoad() {
    gapi.load('auth2', function() {
      gapi.auth2.init({
        client_id: 'YOUR_CLIENT_ID.apps.googleusercontent.com'
      });
    });
  }
</script>
```

#### For Android (`android/app/build.gradle`):
No additional configuration needed if `google-services.json` is properly configured.

#### For iOS (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

### 4. Initialize in Your App

#### In `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Google Drive Service (optional - can do on demand)
  final googleDriveService = GoogleDriveService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>(
          create: (_) => TaskProvider(
            googleDriveService: googleDriveService,
          ),
        ),
        // ... other providers
      ],
      child: const MyApp(),
    ),
  );
}
```

#### In your Auth Provider or Login Screen:
```dart
// After user logs in to your app
Future<void> signInWithGoogle() async {
  try {
    // 1. Sign in to Firebase
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    
    if (googleUser != null) {
      // 2. Sign in to Google Drive
      final googleDriveService = GoogleDriveService();
      await googleDriveService.signIn();
      
      // 3. Set user ID for file uploads
      final taskProvider = Provider.of<TaskProvider>(
        context,
        listen: false,
      );
      taskProvider.setCurrentUserId(googleUser.id);
    }
  } catch (e) {
    debugPrint('Error signing in: $e');
  }
}
```

### 5. Create Firestore Collections

#### Collection: `file_metadata`
Firestore will automatically create this. Documents have this structure:
```json
{
  "fileId": "Google Drive file ID",
  "filename": "example.pdf",
  "driveLink": "https://drive.google.com/file/d/.../view",
  "uploadedBy": "user_id",
  "uploadedAt": "2024-03-24T10:30:00Z",
  "fileSize": 1024000,
  "fileType": "pdf"
}
```

#### Collection: `tasks` (existing, updated)
```json
{
  "title": "Task name",
  "description": "Task description",
  "attachmentUrl": "https://drive.google.com/file/d/.../view",
  "attachmentName": "filename.pdf",
  "status": "todo",
  ...other fields
}
```

## Usage Examples

### Upload File from Mobile/Desktop
```dart
final taskProvider = Provider.of<TaskProvider>(context, listen: false);

// Ensure user ID is set
taskProvider.setCurrentUserId(userId);

// Upload file
final driveLink = await taskProvider.uploadAttachment(
  file: selectedFile,
);

if (driveLink != null) {
  // File uploaded successfully
  // driveLink is shareable Google Drive link
}
```

### Upload File from Web (bytes)
```dart
final fileBytes = await FilePicker.platform.pickFiles();

if (fileBytes != null) {
  final driveLink = await taskProvider.uploadAttachment(
    bytes: fileBytes.files.single.bytes,
    filename: fileBytes.files.single.name,
  );
}
```

### Create Task with Attachment
```dart
// Create task with file attachment
final task = Task(
  id: taskProvider.newId,
  title: 'Task with PDF',
  description: 'Review this PDF',
  creatorId: userId,
  creatorName: 'John Doe',
  status: TaskStatus.todo,
  priority: TaskPriority.high,
  dueDate: DateTime.now().add(Duration(days: 7)),
);

await taskProvider.addTaskWithAttachment(task, attachmentFile);
```

### Delete Task and Attachment
```dart
// Automatically deletes file from Google Drive too
await taskProvider.deleteTask(taskId);
```

### Get File Upload History
```dart
final fileStorageService = FileStorageService(googleDriveService);

// Get all files uploaded by user
final userFiles = await fileStorageService.getUserFiles(userId);

// Get recent files
final recentFiles = await fileStorageService.getRecentFiles(limit: 20);

// Get specific file metadata
final fileMetadata = await fileStorageService.getFileMetadata(fileId);
```

## Firebase Rules (Firestore Security)

Add these rules to allow authenticated users to access file metadata:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read file metadata
    match /file_metadata/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.uid == resource.data.uploadedBy;
    }
    
    // Tasks collection (existing rules)
    match /tasks/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Troubleshooting

### Google Drive Sign-In Not Working
1. Check Google OAuth credentials are properly configured
2. Verify `google-services.json` is in `android/app/`
3. Ensure `CFBundleURLTypes` is set correctly in iOS Info.plist
4. Check internet connection

### Files Not Uploading
1. Verify user is signed in to Google Drive:
   ```dart
   if (googleDriveService.isSignedIn) {
     // Safe to upload
   }
   ```
2. Check Firestore rules allow write access
3. Verify file size is reasonable (< 100MB recommended)
4. Check error logs with `debugPrint('Error: $e')`

### Links Not Working
1. Files are made publicly shareable - should work with link
2. If not accessible, check Google Drive permissions
3. Verify `file_metadata` is stored in Firestore
4. Test link directly in browser

### Performance Issues
1. Use pagination for large file lists
2. Cache file metadata locally with `SharedPreferences`
3. Implement lazy loading for file lists
4. Consider creating separate folders for different file types

## Migration from Firebase Storage

If you had existing files in Firebase Storage:

```dart
// 1. Fetch old files
final oldFiles = await oldStorage.ref('task_attachments').listAll();

// 2. Copy to Google Drive
for (var file in oldFiles.items) {
  final bytes = await file.getData();
  await googleDriveService.uploadBytes(
    bytes,
    filename: file.name,
  );
}

// 3. Update Firestore references
// 4. Keep old files for 30 days, then delete
```

## Costs Comparison

### Firebase Storage
- $0.18 per GB/month (standard)
- $0.026 per GB/month (after 1GB free)

### Google Drive
- Free: 15 GB (shared across Google services)
- Workspace plans: 1TB - unlimited
- No per-transaction costs

**Result**: Significant cost savings for large teams

## Security Best Practices

1. ✅ Always verify user authentication before upload
2. ✅ Validate file types on client and server
3. ✅ Implement file size limits
4. ✅ Use Firestore rules to restrict access
5. ✅ Audit file access logs
6. ✅ Consider marking sensitive files non-public

## Advanced Features (Future Enhancements)

- Create shared team folders in Google Drive
- Implement folder-based access control
- Add file version history
- Create file scanning with Google Drive's AI
- Implement collaborative editing
- Add advanced search via Firestore

## Support Resources

- [Google Drive API Documentation](https://developers.google.com/drive/api)
- [google_sign_in package](https://pub.dev/packages/google_sign_in)
- [googleapis package](https://pub.dev/packages/googleapis)
- [Firebase Documentation](https://firebase.flutter.dev/)

## Next Steps

1. ✅ Test Google Drive authentication with your OAuth credentials
2. ✅ Upload a test file and verify it appears in Google Drive
3. ✅ Check Firestore `file_metadata` collection to see stored metadata
4. ✅ Test file deletion (should remove from Drive + Firestore)
5. ✅ Deploy to production with appropriate OAuth scopes
