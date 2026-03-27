import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

/// Enhanced Google Drive Service with folder management and multi-platform support
class GoogleDriveService {
  late final GoogleSignIn _googleSignIn;
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  String? _appFolderId;
  
  // Debug logging control
  static const bool _enableDebugLogging = kDebugMode;
  
  // Session cache to check if user was previously signed in
  bool _sessionCheckDone = false;

  GoogleDriveService() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    // For web, clientId triggers proper redirect flow
    // For mobile, uses native sign-in
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? '1015708422039-uik2ehutdgj9ophrts6s2ihfgd7i9icc.apps.googleusercontent.com' : null,
      scopes: [drive.DriveApi.driveScope],
      // Force refresh token to maintain session
      forceCodeForRefreshToken: true,
      // Don't automatically sign in on app startup (prevents prompts)
      hostedDomain: null,
    );
  }

  /// Get access token from Firebase Auth's Google provider credential
  Future<String?> _getGoogleAccessToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        debugPrint('No Firebase user logged in');
        return null;
      }

      // Get the ID token credential
      final credential = await user.getIdTokenResult();
      
      // For Firebase Auth with Google, we can get the token from the underlying auth code
      // However, the better approach is to use the user's Firebase token to access Drive
      // Actually, we need to reauthenticate with Google to get a usable token
      
      debugPrint('Fire base user: ${user.email}');
      return credential.token;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  /// Sign in to Google Drive (with session persistence)
  Future<GoogleSignInAccount?> signIn({bool silent = true, bool forceInteractive = false}) async {
    try {
      // If already signed in, return cached user
      if (_currentUser != null && _driveApi != null) {
        debugPrint('✓ Using cached session: ${_currentUser!.email}');
        return _currentUser;
      }

      // Try silent sign in first (uses cached session)
      if (silent && !forceInteractive) {
        debugPrint('Attempting silent sign-in (no popup)...');
        _currentUser = await _googleSignIn.signInSilently();
        
        if (_currentUser != null) {
          final httpClient = (await _googleSignIn.authenticatedClient())!;
          _driveApi = drive.DriveApi(httpClient);
          await _initializeAppFolder();
          debugPrint('✓ Silent sign-in successful: ${_currentUser!.email}');
          return _currentUser;
        }
        
        debugPrint('Silent sign-in failed, will try interactive if needed');
      }

      // Interactive sign-in (shows popup/dialog)
      if (forceInteractive || _currentUser == null) {
        debugPrint('Attempting interactive sign-in (may show popup)...');
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser != null) {
        final httpClient = (await _googleSignIn.authenticatedClient())!;
        _driveApi = drive.DriveApi(httpClient);
        await _initializeAppFolder();
        debugPrint('✓ Successfully signed in to Google Drive: ${_currentUser!.email}');
      } else {
        debugPrint('⚠ Google Sign-In was cancelled or failed.');
        debugPrint('   If popup was blocked: Check browser popup settings');
        debugPrint('   If it timed out: Check your internet connection');
      }
      return _currentUser;
    } catch (e) {
      debugPrint('❌ Google Drive Sign In Error: $e');
      
      if (e.toString().contains('invalid_request') || 
          e.toString().contains('redirect_uri') ||
          e.toString().contains('unauthorized')) {
        debugPrint('This is an OAuth configuration issue.');
        debugPrint('Make sure redirect URIs are registered in Google Cloud Console');
      }
      return null;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _appFolderId = null;
  }

  /// Ensure user is authenticated (silent attempt first)
  Future<bool> _ensureAuthenticated({bool allowInteractive = false}) async {
    if (_currentUser != null && _driveApi != null) {
      return true; // Already authenticated
    }

    // Try silent sign-in first
    final user = await signIn(silent: true, forceInteractive: false);
    
    if (user != null) {
      return true; // Successfully signed in
    }

    // If silent fails and interactive is allowed, show login prompt
    if (allowInteractive) {
      final interactiveUser = await signIn(forceInteractive: true);
      return interactiveUser != null;
    }

    return false;
  }

  /// Check current sign-in status without initiating login
  Future<bool> checkSignInStatus() async {
    if (_currentUser != null) {
      return true;
    }

    // Try to restore session without user interaction
    _currentUser = await _googleSignIn.signInSilently();
    
    if (_currentUser != null) {
      final httpClient = (await _googleSignIn.authenticatedClient())!;
      _driveApi = drive.DriveApi(httpClient);
      return true;
    }

    return false;
  }

  /// Initialize or retrieve the app data folder in Google Drive and create subfolders
  Future<void> _initializeAppFolder() async {
    if (_driveApi == null) return;

    try {
      // Search for existing app folder
      final query = "name='$_appDataFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        pageSize: 1,
      );

      if (result.files != null && result.files!.isNotEmpty) {
        _appFolderId = result.files!.first.id;
        debugPrint('Found existing app folder: $_appFolderId');
      } else {
        // Create new app folder
        final folder = drive.File()
          ..name = _appDataFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _appFolderId = createdFolder.id;
        debugPrint('Created new app folder: $_appFolderId');

        // Share folder with app service account for access
        await _makeFilePublic(_appFolderId!);
      }

      // Initialize subfolders for organizing files by type
      if (_appFolderId != null) {
        _profilePicturesFolderId = await _getOrCreateSubfolder(
          _profilePicturesFolderName,
          _appFolderId!,
        );
        _attachmentsFolderId = await _getOrCreateSubfolder(
          _attachmentsFolderName,
          _appFolderId!,
        );
        _documentsFolderId = await _getOrCreateSubfolder(
          _documentsFolderName,
          _appFolderId!,
        );
        debugPrint('✓ Initialized all subfolders');
      }
    } catch (e) {
      debugPrint('Error initializing app folder: $e');
    }
  }

  /// Get or create a subfolder with the specified name
  Future<String?> _getOrCreateSubfolder(String folderName, String parentFolderId) async {
    if (_driveApi == null) return null;

    try {
      // Search for existing subfolder
      final query = "name='$folderName' and mimeType='application/vnd.google-apps.folder' and parents='$parentFolderId' and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        pageSize: 1,
      );

      if (result.files != null && result.files!.isNotEmpty) {
        debugPrint('Found existing subfolder: $folderName (${result.files!.first.id})');
        return result.files!.first.id;
      }

      // Create new subfolder
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parentFolderId];

      final createdFolder = await _driveApi!.files.create(folder);
      await _makeFilePublic(createdFolder.id!);
      debugPrint('Created new subfolder: $folderName (${createdFolder.id})');
      return createdFolder.id;
    } catch (e) {
      debugPrint('Error getting/creating subfolder $folderName: $e');
      return null;
    }
  }

  static const String _appDataFolderName = 'team_collab_data';
  static const String _profilePicturesFolderName = 'attachment';
  static const String _attachmentsFolderName = 'attachment';
  static const String _documentsFolderName = 'attachment';

  String? _profilePicturesFolderId;
  String? _attachmentsFolderId;
  String? _documentsFolderId;

  /// Create a subfolder for organizing files
  Future<String?> createSubfolder(String folderName) async {
    if (!await _ensureAuthenticated(allowInteractive: true)) return null;
    if (_driveApi == null || _appFolderId == null) return null;

    try {
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [_appFolderId!];

      final createdFolder = await _driveApi!.files.create(folder);
      debugPrint('Created subfolder: ${createdFolder.id}');
      return createdFolder.id;
    } catch (e) {
      debugPrint('Error creating subfolder: $e');
      return null;
    }
  }

  /// Get the profile pictures folder ID
  String? getProfilePicturesFolderId() => _profilePicturesFolderId;

  /// Get the attachments folder ID
  String? getAttachmentsFolderId() => _attachmentsFolderId;

  /// Get the documents folder ID
  String? getDocumentsFolderId() => _documentsFolderId;

  /// Upload file from File object (mobile/desktop)
  Future<String?> uploadFile(
    File file, {
    String? parentFolderId,
  }) async {
    // Ensure authenticated with silent attempt first, then allow interactive if needed
    if (!await _ensureAuthenticated(allowInteractive: true)) {
      debugPrint('Failed to authenticate for file upload');
      return null;
    }
    if (_driveApi == null) return null;

    try {
      final driveFile = drive.File()
        ..name = file.path.split('/').last
        ..parents = [parentFolderId ?? _appFolderId ?? 'root'];

      final fileSize = await file.length();
      final response = await _driveApi!.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), fileSize),
      );

      if (response.id != null) {
        // Make file public/shareable
        await _makeFilePublic(response.id!);

        // Get shareable link
        final linkFile = await _driveApi!.files.get(
          response.id!,
          $fields: 'webViewLink,id',
        ) as drive.File;

        debugPrint('File uploaded successfully: ${linkFile.webViewLink}');
        return linkFile.webViewLink;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  /// Upload file from bytes (web support)
  Future<String?> uploadBytes(
    Uint8List bytes, {
    required String filename,
    String? parentFolderId,
  }) async {
    // Ensure authenticated with silent attempt first, then allow interactive if needed
    if (!await _ensureAuthenticated(allowInteractive: true)) {
      debugPrint('Failed to authenticate for bytes upload');
      return null;
    }
    if (_driveApi == null) return null;

    try {
      final driveFile = drive.File()
        ..name = filename
        ..parents = [parentFolderId ?? _appFolderId ?? 'root'];

      final response = await _driveApi!.files.create(
        driveFile,
        uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
      );

      if (response.id != null) {
        // Make file public/shareable
        await _makeFilePublic(response.id!);

        // Get shareable link
        final linkFile = await _driveApi!.files.get(
          response.id!,
          $fields: 'webViewLink,id',
        ) as drive.File;

        debugPrint('File uploaded successfully: ${linkFile.webViewLink}');
        return linkFile.webViewLink;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading bytes: $e');
      return null;
    }
  }

  /// Make file publicly accessible
  Future<void> _makeFilePublic(String fileId) async {
    if (_driveApi == null) return;

    try {
      await _driveApi!.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        fileId,
      );
      debugPrint('File made public: $fileId');
    } catch (e) {
      debugPrint('Error making file public: $e');
    }
  }

  /// Delete a file from Google Drive
  Future<bool> deleteFile(String fileId) async {
    if (!await _ensureAuthenticated(allowInteractive: true)) return false;
    if (_driveApi == null) return false;

    try {
      await _driveApi!.files.delete(fileId);
      debugPrint('File deleted: $fileId');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Extract file ID from Google Drive sharing link
  static String? extractFileIdFromLink(String link) {
    try {
      // Handle different Google Drive link formats
      if (link.contains('/d/')) {
        return link.split('/d/')[1].split('/')[0];
      } else if (link.contains('id=')) {
        return link.split('id=')[1].split('&')[0];
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting file ID from link: $e');
      return null;
    }
  }

  /// Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if signed in
  bool get isSignedIn => _currentUser != null;
}
