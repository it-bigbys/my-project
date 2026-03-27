import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class LocalStorageService {
  /// Save a file to the local application documents directory
  /// Returns the local path of the saved file (or data URL for web)
  Future<String?> saveFileLocally(File file, String subFolder) async {
    debugPrint('[LocalStorage] saveFileLocally: ${file.path}');
    
    if (kIsWeb) {
      try {
        final bytes = await file.readAsBytes();
        final mimeType = _getMimeType(file.path);
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:$mimeType;base64,$base64';
        debugPrint('[LocalStorage] File saved as data URL for web with MIME: $mimeType');
        return dataUrl;
      } catch (e) {
        debugPrint('[LocalStorage] Error saving file as data URL: $e');
        return null;
      }
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = p.join(directory.path, 'TeamCollab', subFolder);
      final folder = Directory(folderPath);
      
      if (!await folder.exists()) {
        debugPrint('[LocalStorage] Creating folder: $folderPath');
        await folder.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final savedPath = p.join(folderPath, fileName);
      debugPrint('[LocalStorage] Copying file to: $savedPath');
      final savedFile = await file.copy(savedPath);
      
      debugPrint('[LocalStorage] File saved locally at: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('[LocalStorage] Error saving file locally: $e');
      return null;
    }
  }

  /// Get a file from a local path
  File? getLocalFile(String path) {
    if (kIsWeb) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// Save bytes to the local application documents directory (new file)
  /// Returns the local path of the saved file (or data URL for web)
  Future<String?> saveBytesLocally(Uint8List bytes, String filename, String subFolder) async {
    debugPrint('[LocalStorage] saveBytesLocally: $filename (${bytes.length} bytes)');
    
    // Check file size limit (5MB)
    if (bytes.length > 5242880) {
      debugPrint('[LocalStorage] ERROR: File exceeds 5MB limit (${bytes.length} bytes)');
      throw Exception('File size exceeds 5MB limit');
    }

    if (kIsWeb) {
      try {
        final mimeType = _getMimeType(filename);
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:$mimeType;base64,$base64';
        debugPrint('[LocalStorage] Bytes saved as data URL for web with MIME: $mimeType (base64 length: ${base64.length})');
        return dataUrl;
      } catch (e) {
        debugPrint('[LocalStorage] Error saving bytes as data URL: $e');
        return null;
      }
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = p.join(directory.path, 'TeamCollab', subFolder);
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        debugPrint('[LocalStorage] Creating folder: $folderPath');
        await folder.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$filename';
      final filePath = p.join(folderPath, fileName);
      final file = File(filePath);
      debugPrint('[LocalStorage] Writing bytes to: $filePath');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('[LocalStorage] Bytes saved locally at: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[LocalStorage] Error saving bytes locally: $e');
      return null;
    }
  }

  /// Delete a local file
  Future<void> deleteLocalFile(String path) async {
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local file: $e');
    }
  }

  /// Get MIME type based on file extension
  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'zip':
        return 'application/zip';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
