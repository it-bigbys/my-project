import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser;
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<String?> uploadToDrive(File file) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final httpClient = (await _googleSignIn.authenticatedClient())!;
      final driveApi = drive.DriveApi(httpClient);

      final driveFile = drive.File();
      driveFile.name = file.path.split('/').last;
      
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      // Make the file readable by anyone with the link
      await driveApi.permissions.create(
        drive.Permission(role: 'reader', type: 'anyone'),
        response.id!,
      );

      // Retrieve the webViewLink
      final sharedFile = await driveApi.files.get(response.id!, $fields: 'webViewLink') as drive.File;
      return sharedFile.webViewLink;
    } catch (e) {
      print('Google Drive Upload Error: $e');
      return null;
    }
  }
}
