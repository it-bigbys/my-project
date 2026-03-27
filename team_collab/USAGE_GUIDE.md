# File Storage - Quick Usage Guide

## 🚀 Most Common Tasks

### 1. Upload Profile Picture
```dart
// In your profile update screen
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.updateProfilePicture(imageFile);

// ✅ Automatically saves to: team_collab_data/profile_pictures/
// ✅ Link stored in: Firebase users.photoUrl
```

### 2. Upload Task Attachment
```dart
// In your task creation/editing screen
final taskProvider = Provider.of<TaskProvider>(context, listen: false);
final link = await taskProvider.uploadAttachment(file: attachmentFile);

// ✅ Automatically saves to: team_collab_data/attachments/
// ✅ Link stored in: Firebase tasks.attachmentUrl
```

### 3. Upload from Web (Bytes)
```dart
// In your web-based upload
final fileStorageService = FileStorageService(googleDriveService);

final link = await fileStorageService.uploadFileFromBytes(
  bytes: fileBytes,
  filename: "document.pdf",
  userId: userId,
  fileType: FileType.document, // ← Specify type
);
```

### 4. Get File Information
```dart
final metadata = await fileStorageService.getFileMetadata(fileId);

print('File: ${metadata?.filename}');           // "photo.jpg"
print('Size: ${metadata?.fileSize}');           // 2048576
print('Type: ${metadata?.fileType}');           // "jpg"
print('Category: ${metadata?.category}');       // "profile_pictures"
print('Uploaded by: ${metadata?.uploadedBy}');  // "user_123"
print('Link: ${metadata?.driveLink}');          // Full Google Drive link
```

### 5. Delete File
```dart
// Deletes from Google Drive AND Firebase metadata
const fileId = 'abc123def456';
await fileStorageService.deleteFile(fileId);

// ✅ Removed from Google Drive
// ✅ Metadata deleted from Firestore
```

---

## 📂 Folder Organization

| File Type | Folder | Use Case |
|-----------|--------|----------|
| **Profile Pictures** | `profile_pictures/` | User avatars |
| **Attachments** | `attachments/` | Task files (PDFs, docs, images) |
| **Documents** | `documents/` | Reports, exports, general docs |

---

## 🔧 Folder IDs (For Advanced Use)

```dart
// Get folder IDs if you need them directly
String? profilePicturesFolderId = 
  googleDriveService.getProfilePicturesFolderId();

String? attachmentsFolderId = 
  googleDriveService.getAttachmentsFolderId();

String? documentsFolderId = 
  googleDriveService.getDocumentsFolderId();
```

---

## 💾 What's Stored Where

### Google Drive (Actual Files)
```
✓ All file content resides here
✓ Organized into folders by type
✓ Automatically shared/public
✓ Backed up by Google
```

### Firebase Firestore (Links Only)
```
✓ users.photoUrl → "https://drive.google.com/file/d/.../view"
✓ tasks.attachmentUrl → "https://drive.google.com/file/d/.../view"
✓ file_metadata.driveLink → "https://drive.google.com/file/d/.../view"

✗ No actual file content stored
✗ Minimal storage usage
✗ Maximum cost efficiency
```

---

## 📋 FileType Enum Reference

```dart
import 'package:team_collab/services/file_storage_service.dart';

// Available types:
FileType.profilePicture  // → profile_pictures/
FileType.attachment      // → attachments/
FileType.document       // → documents/

// Usage:
await fileStorageService.uploadFileFromPath(
  file: myFile,
  userId: userId,
  fileType: FileType.profilePicture, // ← Choose appropriate type
);
```

---

## 🎯 Common Scenarios

### Scenario 1: User Changes Profile Picture
```dart
// 1. User picks image from gallery
final result = await FilePicker.platform.pickFiles(type: FileType.image);

// 2. Get AuthProvider
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// 3. Upload (handles everything)
await authProvider.updateProfilePicture(File(result.files.first.path!));

// ✅ File uploaded to Google Drive
// ✅ Link stored in Firebase users.photoUrl
// ✅ Metadata saved for audit trail
```

### Scenario 2: Attach File to Task
```dart
// 1. User picks file
final result = await FilePicker.platform.pickFiles();

// 2. Get TaskProvider
final taskProvider = Provider.of<TaskProvider>(context, listen: false);

// 3. Upload
final link = await taskProvider.uploadAttachment(
  file: File(result.files.first.path!),
);

if (link != null) {
  // 4. Create/update task with attachment
  final task = Task(
    // ... other fields
    attachmentUrl: link,
    attachmentName: File(result.files.first.path!).path.split('/').last,
  );
}
```

### Scenario 3: Web Upload (Bytes)
```dart
// 1. Pick file from web
final result = await FilePicker.platform.pickFiles();

if (result != null) {
  // 2. Get bytes
  final bytes = result.files.first.bytes!;
  final filename = result.files.first.name;

  // 3. Upload
  final link = await fileStorageService.uploadFileFromBytes(
    bytes: bytes,
    filename: filename,
    userId: userId,
    fileType: FileType.attachment,
  );

  // ✅ File now on Google Drive
}
```

---

## 🔍 Verify File Was Uploaded

```dart
Future<void> verifyUpload(String fileId) async {
  final metadata = await fileStorageService.getFileMetadata(fileId);
  
  if (metadata != null) {
    print('✅ File uploaded successfully');
    print('   Name: ${metadata.filename}');
    print('   Size: ${metadata.fileSize} bytes');
    print('   Location: ${metadata.category}');
    print('   Link: ${metadata.driveLink}');
  } else {
    print('❌ File not found');
  }
}
```

---

## ⚡ Performance Tips

### For Mobile/Desktop
```dart
// ✅ Direct file upload (fast)
final link = await fileStorageService.uploadFileFromPath(
  file: file,
  userId: userId,
  fileType: FileType.attachment,
);
```

### For Web
```dart
// ✅ Bytes upload (recommended for web)
final link = await fileStorageService.uploadFileFromBytes(
  bytes: bytes,
  filename: filename,
  userId: userId,
  fileType: FileType.attachment,
);
```

---

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Files going to wrong folder | Ensure correct `FileType` is specified |
| Links not working | Check Google Drive sharing settings |
| Upload is slow | Use bytes instead of file path |
| Can't access file metadata | Check `file_metadata` collection exists |
| Old files still in Firebase Storage | They continue to work - no migration needed |

---

## 📊 Example: Complete Upload Flow

```dart
Future<void> completeUploadExample(BuildContext context) async {
  try {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = File(result.files.single.path!);
    final userId = getCurrentUserId(); // Your method

    // 2. Get service
    final fileStorageService = FileStorageService(googleDriveService);

    // 3. Upload with type
    final link = await fileStorageService.uploadFileFromPath(
      file: file,
      userId: userId,
      fileType: FileType.attachment,
    );

    if (link == null) {
      throw Exception('Upload failed');
    }

    // 4. Extract file ID
    final fileId = GoogleDriveService.extractFileIdFromLink(link);

    // 5. Get metadata
    final metadata = await fileStorageService.getFileMetadata(fileId!);

    // 6. Use link (e.g., save to task)
    await updateTaskWithAttachment(
      taskId: 'task_123',
      attachmentUrl: link,
      attachmentName: metadata?.filename ?? 'file',
    );

    // ✅ Done!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File uploaded: ${metadata?.filename}')),
    );
  } catch (e) {
    debugPrint('Error: $e');
    showErrorSnackbar(context, 'Upload failed');
  }
}
```

---

## 📲 Before Deploying

Checklist:
- [ ] Test profile picture upload (desktop/mobile/web)
- [ ] Test task attachment upload (desktop/mobile/web)
- [ ] Verify files appear in Google Drive folders
- [ ] Verify links work when clicked
- [ ] Test deletion (should remove drive file AND Firebase metadata)
- [ ] Check file metadata in Firebase Console
- [ ] Verify category field shows correct folder name

---

## 🎓 Key Concepts

```
┌─────────────────────────────────────────────────┐
│         File Upload Flow (New System)            │
├─────────────────────────────────────────────────┤
│                                                  │
│  User selects file                              │
│         ↓                                        │
│  Specify FileType (optional, defaults to        │
│  attachment)                                     │
│         ↓                                        │
│  File Storage Service                           │
│         ↓                                        │
│  ┌─ Uploads to Google Drive                     │
│  │  └─ In correct folder (profile_pictures,     │
│  │     attachments, or documents)               │
│  │                                              │
│  └─ Stores metadata in Firestore                │
│     └─ Includes: link, filename, size,          │
│        category, uploadedBy, etc.               │
│         ↓                                        │
│  Return shareable Google Drive link             │
│         ↓                                        │
│  Use link in Firebase (users, tasks, etc.)      │
│                                                  │
└─────────────────────────────────────────────────┘
                    ✅ Complete!
```

---

## 🌐 Cloud Infrastructure

```
Client (Flutter App)
  ├─→ Google Sign-In
  │    └─→ User Grants Permission
  │
  ├─→ Google Drive API
  │    └─→ Upload File to Correct Folder
  │
  ├─→ Firebase Firestore
  │    └─→ Store Link + Metadata
  │
  └─→ User can access file via link
       └─→ Internet → Google Drive CDN → File
```

---

**Ready to use! 🚀**
