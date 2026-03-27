/// Integration Examples for Firebase + Google Drive Storage
/// 
/// This file contains examples of how to integrate the new file storage system
/// with Google Drive and Firebase in your Flutter app.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/google_drive_service.dart';
import 'services/file_storage_service.dart';
import 'providers/task_provider.dart';

// ============================================================================
// EXAMPLE 1: Initialize Google Drive Service (in main.dart or app initialization)
// ============================================================================

void initializeGoogleDriveIntegration(BuildContext context) {
  // Create GoogleDriveService
  final googleDriveService = GoogleDriveService();
  
  // Sign in to Google Drive (ideally after user logs in to your app)
  _signInToGoogleDrive(googleDriveService);
}

Future<void> _signInToGoogleDrive(GoogleDriveService googleDriveService) async {
  try {
    final user = await googleDriveService.signIn();
    if (user != null) {
      debugPrint('Google Drive signed in: ${user.email}');
    }
  } catch (e) {
    debugPrint('Error signing in to Google Drive: $e');
  }
}

// ============================================================================
// EXAMPLE 2: Update TaskProvider with Current User ID
// ============================================================================

void setupTaskProviderWithUser(BuildContext context, String userId) {
  // Get TaskProvider and set the current user for file uploads
  final taskProvider = Provider.of<TaskProvider>(context, listen: false);
  taskProvider.setCurrentUserId(userId);
}

// ============================================================================
// EXAMPLE 3: Upload File From Mobile/Desktop
// ============================================================================

// Note: Task import is in models/task.dart
import 'models/task.dart';

Future<void> uploadTaskAttachmentFromFile(
  BuildContext context,
  File file,
) async {
  final taskProvider = Provider.of<TaskProvider>(context, listen: false);
  
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
  );

  try {
    // Upload attachment
    final attachmentUrl = await taskProvider.uploadAttachment(file: file);
    
    Navigator.pop(context); // Close loading dialog

    if (attachmentUrl != null) {
      // File uploaded successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload file')),
      );
    }
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Upload File From Bytes (Web)
// ============================================================================

Future<void> uploadTaskAttachmentFromBytes(
  BuildContext context,
  Uint8List bytes,
  String filename,
) async {
  final taskProvider = Provider.of<TaskProvider>(context, listen: false);

  try {
    // Upload attachment
    final attachmentUrl = await taskProvider.uploadAttachment(
      bytes: bytes,
      filename: filename,
    );

    if (attachmentUrl != null) {
      // File uploaded successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $e')),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Provider Setup (in main.dart MultiProvider)
// ============================================================================

/*
MultiProvider(
  providers: [
    ChangeNotifierProvider<TaskProvider>(
      create: (_) => TaskProvider(
        // Inject GoogleDriveService if you want custom configuration
        googleDriveService: GoogleDriveService(),
      ),
    ),
    // ... other providers
  ],
  child: MyApp(),
)
*/

// ============================================================================
// EXAMPLE 6: Complete Task Upload Flow
// ============================================================================

Future<void> createTaskWithAttachment(
  BuildContext context,
  String title,
  String description,
  File? attachmentFile,
  String assigneeId,
  String creatorId,
) async {
  final taskProvider = Provider.of<TaskProvider>(context, listen: false);

  try {
    // Create task object
    final newTask = Task(
      id: taskProvider.newId,
      title: title,
      description: description,
      branch: 'Main',
      dateRequested: DateTime.now(),
      assigneeId: assigneeId,
      creatorId: creatorId,
      creatorName: 'Current User', // Get from auth provider
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      dueDate: DateTime.now().add(const Duration(days: 7)),
    );

    // Upload with attachment if provided
    if (attachmentFile != null) {
      await taskProvider.addTaskWithAttachment(newTask, attachmentFile);
    } else {
      await taskProvider.addTask(newTask);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task created successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating task: $e')),
    );
  }
}

// ============================================================================
// EXAMPLE 7: Download/Access File
// ============================================================================

void openAttachment(BuildContext context, String attachmentUrl, String filename) {
  // For web: Open in new tab
  if (filename.endsWith('.pdf')) {
    // Handle PDF preview
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(filename),
        content: const Text('PDF preview functionality can be added'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Use url_launcher to open the link
              // launchUrl(Uri.parse(attachmentUrl));
            },
            child: const Text('Open in Drive'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 8: Firebase Collections Structure
// ============================================================================

/*
Firestore Collections:

1. tasks (existing)
   - title: string
   - description: string
   - attachmentUrl: string (Google Drive link)
   - attachmentName: string
   - ... other fields

2. file_metadata (new)
   - fileId: string (Document ID - from Google Drive)
   - filename: string
   - driveLink: string (Shareable link)
   - uploadedBy: string (User ID)
   - uploadedAt: timestamp
   - fileSize: integer
   - fileType: string (file extension)

3. tasks_files (optional - for tracking task-file relationships)
   - taskId: string
   - fileId: string
   - filename: string
   - uploadedAt: timestamp
*/

// ============================================================================
// EXAMPLE 9: Google Drive API Scopes
// ============================================================================

/*
The GoogleDriveService uses the following scope:
- drive.DriveApi.driveScope: Full access to Google Drive

This allows:
✓ Creating folders and files
✓ Reading and writing files
✓ Sharing files (making them public)
✓ Deleting files
✓ Managing permissions

*/

// ============================================================================
// EXAMPLE 10: Error Handling and Fallback
// ============================================================================

Future<String?> uploadWithFallback(
  BuildContext context,
  File file,
  FileStorageService fileStorageService,
  String userId,
) async {
  try {
    // Try Google Drive first
    final driveLink = await fileStorageService.uploadFileFromPath(
      file: file,
      userId: userId,
    );

    if (driveLink != null) {
      return driveLink;
    }

    // If Google Drive fails, show error or implement fallback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Google Drive upload failed. Please ensure you are signed in.',
        ),
      ),
    );
    return null;
  } catch (e) {
    debugPrint('Upload error: $e');
    return null;
  }
}

// ============================================================================
// Additional Notes:
// ============================================================================
/*
1. Storage Architecture:
   - Images: Google Drive (primary storage) + Firebase links -> Reduced costs
   - Metadata: Firebase Firestore -> Quick access and search
   - Links: Firebase Firestore -> Used to access files

2. Benefits:
   ✓ Lower Firebase Storage costs
   ✓ Unlimited Google Drive storage (within user's quota)
   ✓ Better file organization via Google Drive folders
   ✓ Automatic Google Drive backup
   ✓ Easy file sharing through Drive links

3. Security Considerations:
   ✓ Google Drive files are only accessible via shareable links
   ✓ File metadata is stored in Firestore with access control
   ✓ Consider implementing additional access control checks
   ✓ Audit logs via Firebase and Google Activity

4. Performance:
   ✓ Google Drive CDN distributes files
   ✓ Firebase Firestore Caching for metadata
   ✓ Consider pagination for large file lists

5. Migration from Firebase Storage:
   - Create data migration script to move existing files
   - Update references in Firestore
   - Keep old files for backward compatibility during transition
*/
