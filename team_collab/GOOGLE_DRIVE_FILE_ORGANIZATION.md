# Google Drive File Organization Guide

## Overview

Your Flutter app now uses an **optimized hybrid storage architecture** that saves files to Google Drive and stores only links in Firebase. Files are organized into specific folders by type for better management.

## 📁 Folder Structure

```
team_collab_data/ (Main app folder)
├── profile_pictures/    (User profile photos)
├── attachments/         (Task attachments, documents)
└── documents/           (Reports, PDFs, general documents)
```

### Folder Purposes

| Folder | Purpose | Stored in Firebase |
|--------|---------|-------------------|
| **profile_pictures** | User avatar images | ✅ Link only (`photoUrl`) |
| **attachments** | Task files and images | ✅ Link only (`attachmentUrl`) |
| **documents** | Reports, PDFs, general docs | ✅ Link only + metadata |

## 🚀 Implementation Details

### 1. Automatic Folder Organization

When you initialize Google Drive for the first time:
- ✅ Main folder `team_collab_data` is created
- ✅ Subfolders are automatically created
- ✅ All folders are made publicly readable
- ✅ Structure is reused on subsequent runs

```dart
// Automatic initialization happens in GoogleDriveService.signIn()
final user = await googleDriveService.signIn();
// All folders created automatically ✨
```

### 2. Profile Pictures (✨ NEW)

**Saved to:** `team_collab_data/profile_pictures/`
**Firebase storage:** Only the link

```dart
// In AuthProvider.updateProfilePicture()
final driveLink = await _fileStorageService.uploadFileFromPath(
  file: file,
  userId: userId,
  fileType: FileType.profilePicture,  // ← Specifies folder
);

// Firebase stores:
// users/{userId}/photoUrl = "https://drive.google.com/file/d/..."
```

**Benefits:**
- 📦 Organized in dedicated folder
- 🔗 Only link stored in Firebase
- 👍 Reduces Firebase storage costs
- 🔄 Easy to backup and manage

### 3. Task Attachments

**Saved to:** `team_collab_data/attachments/`
**Firebase storage:** Link + metadata

```dart
// In TaskProvider.uploadAttachment()
final driveLink = await _fileStorageService.uploadFileFromBytes(
  bytes: bytes,
  filename: filename,
  userId: userId,
  fileType: FileType.attachment,  // ← Default
);

// Firebase stores in file_metadata collection:
// {
//   fileId: "...",
//   filename: "report.pdf",
//   driveLink: "https://drive.google.com/file/d/...",
//   uploadedBy: "user123",
//   uploadedAt: "2024-03-24T10:30:00Z",
//   fileSize: 2048576,
//   fileType: "pdf",
//   category: "attachments"  // ← File category
// }
```

### 4. Documents (General)

**Saved to:** `team_collab_data/documents/`
**Firebase storage:** Link + metadata

```dart
// For general document uploads
final driveLink = await _fileStorageService.uploadFileFromPath(
  file: file,
  userId: userId,
  fileType: FileType.document,
);
```

## 💾 Storage Architecture

### Google Drive (Files)
```
✓ Profile pictures - actual image files
✓ Attachments - PDFs, documents, images
✓ Documents - reports, exports
```

### Firebase Firestore (Links & Metadata)

**Collection: `file_metadata`**
```
{
  fileId: "abc123xyz...",
  filename: "report.pdf",
  driveLink: "https://drive.google.com/...",
  uploadedBy: "user_id",
  uploadedAt: "2024-03-24...",
  fileSize: 2048576,
  fileType: "pdf",
  category: "attachments"  // profile_pictures, attachments, documents
}
```

**Collection: `users`**
```
{
  photoUrl: "https://drive.google.com/file/d/.../view"  // ← Link only
  // ... other user fields
}
```

**Collection: `tasks`**
```
{
  attachmentUrl: "https://drive.google.com/file/d/.../view"  // ← Link only
  attachmentName: "filename.pdf"
  // ... other task fields
}
```

## 🔧 API Reference

### FileStorageService Methods

#### Upload Profile Picture
```dart
Future<String?> uploadFileFromPath({
  required File file,
  required String userId,
  String? parentFolderId,
  FileType fileType = FileType.attachment, // ← Change to profilePicture
})
```

#### Upload via Bytes (Web)
```dart
Future<String?> uploadFileFromBytes({
  required Uint8List bytes,
  required String filename,
  required String userId,
  String? parentFolderId,
  FileType fileType = FileType.attachment, // ← Specify file type
})
```

#### Get File Metadata
```dart
Future<FileMetadata?> getFileMetadata(String fileId)
```

#### Delete File
```dart
Future<bool> deleteFile(String fileId, {bool removeMetadata = true})
```

### FileType Enum

```dart
enum FileType {
  profilePicture,  // → Saves to profile_pictures/
  attachment,      // → Saves to attachments/
  document,        // → Saves to documents/
}
```

## 📊 Usage Examples

### Example 1: Update User Profile Picture
```dart
Future<void> updateProfilePicture(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );

  if (result != null) {
    final file = File(result.files.single.path!);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Automatically saved to profile_pictures/ folder
    await authProvider.updateProfilePicture(file);
  }
}
```

### Example 2: Upload Task Attachment
```dart
Future<void> uploadTaskAttachment(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles();

  if (result != null) {
    final file = File(result.files.single.path!);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Automatically saved to attachments/ folder
    final url = await taskProvider.uploadAttachment(file: file);
    
    if (url != null) {
      print('File saved to Google Drive: $url');
    }
  }
}
```

### Example 3: Upload from Web
```dart
Future<void> uploadFromWeb(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles();

  if (result != null) {
    final bytes = result.files.single.bytes!;
    final filename = result.files.single.name;
    
    final fileStorageService = FileStorageService(googleDriveService);
    
    // Specify file type for proper folder organization
    final link = await fileStorageService.uploadFileFromBytes(
      bytes: bytes,
      filename: filename,
      userId: userId,
      fileType: FileType.document, // ← For documents folder
    );
  }
}
```

## 🔐 Access Control

### File Permissions
- ✅ All files are **publicly readable** via shareable links
- ✅ Users access files only through stored links
- ✅ Google Drive file ownership preserved
- ✅ Deletion cascades from Firestore

### Link Sharing
```dart
// Links are automatically created as:
// https://drive.google.com/file/d/{fileId}/view
```

## 🗑️ File Deletion

Deletion is automatic and includes cleanup:

```dart
// In TaskProvider.deleteTask()
await googleDriveService.deleteFile(fileId);
// ✓ Removes from Google Drive
// ✓ Removes metadata from Firebase
// ✓ Removes from tasks collection
```

## 📈 Cost Benefits

| Storage | Before | After |
|---------|--------|-------|
| Firebase Storage | $0.18/GB | Reduced ✅ |
| Google Drive | Free (up to quota) | Primary storage ✅ |
| **Total Cost** | High | **Low** ✅ |

## 🔍 Monitoring & Debugging

### Check Folder IDs
```dart
final profilePicturesFolderId = 
  googleDriveService.getProfilePicturesFolderId();
  
final attachmentsFolderId = 
  googleDriveService.getAttachmentsFolderId();
  
final documentsFolderId = 
  googleDriveService.getDocumentsFolderId();
```

### View File Metadata
```dart
final metadata = await fileStorageService.getFileMetadata(fileId);
print('File: ${metadata?.filename}');
print('Size: ${metadata?.fileSize} bytes');
print('Uploaded: ${metadata?.uploadedAt}');
print('Category: ${metadata?.category}');
```

### Debug Logs
Enable debug logging to see folder operations:
```
✓ Successfully signed in to Google Drive: user@gmail.com
✓ Found existing app folder: folder_id_1
✓ Initialized all subfolders
Starting upload for file: photo.jpg (type: profilePicture)
File metadata stored: file_id_123 (category: profile_pictures)
```

## ✅ Verification Checklist

After implementation:

- [ ] Run app and sign in with Google
- [ ] Upload a profile picture
  - [ ] Check: File appears in Google Drive's `team_collab_data/profile_pictures/`
  - [ ] Check: Link stored in Firebase `users/{userId}/photoUrl`
- [ ] Upload a task attachment
  - [ ] Check: File appears in `team_collab_data/attachments/`
  - [ ] Check: Metadata stored in Firebase `file_metadata` collection
- [ ] Verify links work by visiting them
- [ ] Test file deletion cascades properly

## 📚 Related Files

- [FIREBASE_GOOGLE_DRIVE_SETUP.md](FIREBASE_GOOGLE_DRIVE_SETUP.md) - Initial setup
- [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) - Implementation steps
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Quick code examples
- [lib/services/google_drive_service.dart](lib/services/google_drive_service.dart) - Google Drive API
- [lib/services/file_storage_service.dart](lib/services/file_storage_service.dart) - File storage abstraction

## 🚀 Next Steps

1. ✅ Implementation complete - your system is ready!
2. Test profile picture uploads and verify folder organization
3. Monitor file metadata in Firebase Console
4. Share feedback on organization structure

---

**Note:** This system automatically creates folders on first use. No manual setup needed! 🎉
