// QUICK REFERENCE CARD - Firebase + Google Drive Integration
// Keep this handy while implementing!

// ==============================================================================
// 1. MINIMAL SETUP (Just to get it working)
// ==============================================================================

// In main.dart:
import 'package:team_collab/services/google_drive_service.dart';
import 'package:team_collab/providers/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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

// ==============================================================================
// 2. SIGN IN TO GOOGLE DRIVE (In your AuthProvider or LoginScreen)
// ==============================================================================

Future<void> initializeGoogleDrive(String userId) async {
  final googleDriveService = GoogleDriveService();
  final user = await googleDriveService.signIn();
  
  if (user != null) {
    // Set user for file uploads
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.setCurrentUserId(userId);
    print('Google Drive ready for ${user.email}');
  }
}

// ==============================================================================
// 3. UPLOAD FILE (Exactly same as before - it now uses Google Drive!)
// ==============================================================================

// Mobile/Desktop (from FilePicker):
final result = await FilePicker.platform.pickFiles();
if (result != null) {
  final file = File(result.files.single.path!);
  final url = await taskProvider.uploadAttachment(file: file);
  print('Uploaded to: $url'); // Google Drive link
}

// Web (from FilePicker):
final result = await FilePicker.platform.pickFiles();
if (result != null) {
  final url = await taskProvider.uploadAttachment(
    bytes: result.files.single.bytes!,
    filename: result.files.single.name,
  );
  print('Uploaded to: $url'); // Google Drive link
}

// ==============================================================================
// 4. CREATE TASK WITH ATTACHMENT
// ==============================================================================

final task = Task(
  id: taskProvider.newId,
  title: 'Review Document',
  description: 'Please review this PDF',
  creatorId: userId,
  creatorName: 'John Doe',
  status: TaskStatus.todo,
  priority: TaskPriority.high,
  dueDate: DateTime.now().add(Duration(days: 7)),
);

// Auto-uploads file and saves task
await taskProvider.addTaskWithAttachment(task, selectedFile);

// Task.attachmentUrl is now: https://drive.google.com/file/d/.../view

// ==============================================================================
// 5. DELETE TASK (Also removes file from Google Drive!)
// ==============================================================================

await taskProvider.deleteTask(taskId);
// File auto-deleted from Google Drive
// Metadata auto-deleted from Firestore

// ==============================================================================
// 6. EXTRACT FILE ID FROM GOOGLE DRIVE LINK
// ==============================================================================

final fileId = GoogleDriveService.extractFileIdFromLink(
  'https://drive.google.com/file/d/ABC123DEF456/view'
);
print(fileId); // "ABC123DEF456"

// ==============================================================================
// 7. FIRESTORE RULES (Copy-paste into Firebase Console)
// ==============================================================================

/*
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /file_metadata/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.uid == resource.data.uploadedBy;
    }
    match /tasks/{document=**} {
      allow read: if request.auth != null;
      allow create,update,delete: if request.auth != null;
    }
  }
}
*/

// ==============================================================================
// 8. COMMON ISSUES & SOLUTIONS
// ==============================================================================

// Issue: Google Drive sign-in fails
// Solution:
if (!googleDriveService.isSignedIn) {
  await googleDriveService.signIn();
}

// Issue: Upload returns null
// Solution:
try {
  final url = await taskProvider.uploadAttachment(file: file);
  if (url == null) {
    print('Upload failed - check user ID is set');
    // Ensure setCurrentUserId was called!
  }
} catch (e) {
  print('Upload error: $e');
}

// Issue: File link doesn't work
// Solution: Link is shareable by default, but verify:
// 1. File exists in Google Drive (check "team_collab_attachments" folder)
// 2. File permissions are public (auto-set by service)
// 3. Test link directly in browser

// Issue: Metadata not in Firestore
// Solution: Check Firestore rules allow writing to file_metadata collection

// ==============================================================================
// 9. DEPENDENCIES ALREADY ADDED
// ==============================================================================

/*
✅ Already in pubspec.yaml:
- google_sign_in: ^6.2.1
- googleapis: ^13.2.0
- cloud_firestore: ^5.6.2
- firebase_core: ^3.10.1
- firebase_auth: ^5.5.1

No need to add any new dependencies!
*/

// ==============================================================================
// 10. NEW SERVICES ADDED (Don't modify these!)
// ==============================================================================

/*
- lib/services/google_drive_service.dart
  → Enhanced Google Drive API wrapper
  → Handles authentication, uploads, deletions
  
- lib/services/file_storage_service.dart
  → Abstraction layer for unified storage
  → Manages metadata in Firestore
  → Coordinates Drive + Firestore operations

- lib/providers/task_provider.dart  
  → Updated to use Google Drive service
  → Backward compatible with existing code
  → All upload methods now use Drive
*/

// ==============================================================================
// 11. SETUP PHASES OVERVIEW
// ==============================================================================

/*
Phase 1: Google Cloud Setup (20-30 min)
  ✓ Enable Google Drive API
  ✓ Create OAuth 2.0 credentials
  ✓ Save Client IDs

Phase 2-4: App Configuration (40 min)
  ✓ Update main.dart with new initialization
  ✓ Add Google Drive sign-in to auth flow
  ✓ Set user ID for uploads

Phase 5: Update UI (20 min)
  ✓ No changes needed! Use existing upload code

Phase 6-7: Firestore Setup (15 min)
  ✓ Verify file_metadata collection structure
  ✓ Update Firestore security rules

Phase 8: Testing (30-45 min)
  ✓ Manual testing checklist

*/

// ==============================================================================
// 12. FILES TO READ (IN ORDER)
// ==============================================================================

/*
1. SETUP_README.md - Overview
2. IMPLEMENTATION_CHECKLIST.md - Step-by-step guide (START HERE!)
3. FIREBASE_GOOGLE_DRIVE_SETUP.md - Detailed configuration
4. INTEGRATION_EXAMPLES.dart - Code examples
5. test/firebase_google_drive_integration_test.dart - Testing guide

Source files:
- lib/services/google_drive_service.dart
- lib/services/file_storage_service.dart
- lib/providers/task_provider.dart (updated)
*/

// ==============================================================================
// 13. COST SAVINGS
// ==============================================================================

/*
Before (Firebase Storage only):
- 100 GB files = $18/month
- 1 TB files = $180/month

After (Google Drive + Firebase metadata):
- 100 GB files = Free (within Drive quota)
- 1 TB files = Free (within Drive quota)

Savings: $18-180/month depending on usage!
*/

// ==============================================================================
// 14. QUICK COMMANDS
// ==============================================================================

// Run on web during development:
// flutter run -d chrome

// Run on Android:
// flutter run -d android

// Run tests:
// flutter test test/firebase_google_drive_integration_test.dart

// Format code:
// dart format lib/services/ lib/providers/

// Check for errors:
// flutter analyze

// ==============================================================================
// 15. GOOGLE DRIVE FOLDER STRUCTURE
// ==============================================================================

/*
Your Google Drive will automatically create:

team_collab_attachments/
  ├─ file1.pdf (Auto-shared, publicly accessible)
  ├─ file2.docx (Auto-shared, publicly accessible)
  └─ file3.png (Auto-shared, publicly accessible)

All files are automatically:
✓ Uploaded to this folder
✓ Made publicly readable
✓ Indexed in Firestore metadata
✓ Associated with tasks
*/

// ==============================================================================
// 16. MIGRATION FROM FIREBASE STORAGE
// ==============================================================================

/*
Old approach:
Task.attachmentUrl = "https://firebase_storage_url"

New approach:
Task.attachmentUrl = "https://drive.google.com/file/d/.../view"

Existing tasks continue to work!
New uploads use Google Drive.
Mix of old/new links is fine.
*/

// ==============================================================================
// 17. NEXT IMMEDIATE STEPS
// ==============================================================================

/*
Today:
1. Open IMPLEMENTATION_CHECKLIST.md
2. Complete Phase 1 (Google Cloud setup) - 20-30 min

This week:
3. Phases 2-4 (App configuration) - 40 min
4. Phase 8 (Testing) - 30-45 min

This month:
5. Phase 9 (Production deployment)
*/

// ==============================================================================
// QUICK LINKS
// ==============================================================================

/*
Google Cloud Console: https://console.cloud.google.com/
Firebase Console: https://console.firebase.google.com/
Google Drive Root: https://drive.google.com/

Documentation in this project:
- SETUP_README.md (Start here!)
- IMPLEMENTATION_CHECKLIST.md (Step-by-step)
- FIREBASE_GOOGLE_DRIVE_SETUP.md (Details)
- INTEGRATION_EXAMPLES.dart (Code)
- test/firebase_google_drive_integration_test.dart (Testing)
*/

// ==============================================================================
// You're all set! Start with IMPLEMENTATION_CHECKLIST.md 🚀
// ==============================================================================
