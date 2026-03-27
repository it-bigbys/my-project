import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_storage_service.dart';

/// File type enum for organizing files in different storage folders
enum FileType {
  profilePicture,
  attachment,
  document,
}

extension FileTypeExtension on FileType {
  String get folderName {
    switch (this) {
      case FileType.profilePicture:
        return 'attachment';
      case FileType.attachment:
        return 'attachment';
      case FileType.document:
        return 'attachment';
    }
  }
}

/// File storage metadata stored in Firebase
class FileMetadata {
  final String fileId;
  final String filename;
  final String localPath;
  final String uploadedBy;
  final DateTime uploadedAt;
  final int fileSize;
  final String fileType;
  final String? category; // Profile picture, attachment, document, etc.

  FileMetadata({
    required this.fileId,
    required this.filename,
    required this.localPath,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.fileSize,
    required this.fileType,
    this.category,
  });

  Map<String, dynamic> toMap() => {
        'fileId': fileId,
        'filename': filename,
        'localPath': localPath,
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt.toIso8601String(),
        'fileSize': fileSize,
        'fileType': fileType,
        'category': category,
      };

  factory FileMetadata.fromMap(Map<String, dynamic> map) => FileMetadata(
        fileId: map['fileId'] ?? '',
        filename: map['filename'] ?? '',
        localPath: map['localPath'] ?? '',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedAt: map['uploadedAt'] != null
            ? DateTime.parse(map['uploadedAt'])
            : DateTime.now(),
        fileSize: map['fileSize'] ?? 0,
        fileType: map['fileType'] ?? '',
        category: map['category'],
      );
}

/// File storage service using local storage and Firestore metadata.
class FileStorageService {
  final LocalStorageService _localStorageService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FileStorageService(this._localStorageService);

  /// Upload a File and store local path metadata in Firestore
  Future<String?> uploadFileFromPath({
    required File file,
    required String userId,
    FileType fileType = FileType.attachment,
  }) async {
    try {
      final localPath = await _localStorageService.saveFileLocally(file, fileType.folderName);
      if (localPath == null) return null;
      final fileName = file.path.split(Platform.pathSeparator).last;
      final fileSize = await file.length();
      await _storeFileMetadata(
        fileId: DateTime.now().millisecondsSinceEpoch.toString(),
        filename: fileName,
        localPath: localPath,
        uploadedBy: userId,
        fileSize: fileSize,
        fileType: _getFileType(fileName),
        category: fileType.folderName,
      );
      return localPath;
    } catch (e) {
      debugPrint('Error uploading local file: $e');
      return null;
    }
  }

  Future<String?> uploadFileFromBytes({
    required Uint8List bytes,
    required String filename,
    required String userId,
    FileType fileType = FileType.attachment,
  }) async {
    try {
      final localPath = await _localStorageService.saveBytesLocally(bytes, filename, fileType.folderName);
      if (localPath == null) return null;
      await _storeFileMetadata(
        fileId: DateTime.now().millisecondsSinceEpoch.toString(),
        filename: filename,
        localPath: localPath,
        uploadedBy: userId,
        fileSize: bytes.length,
        fileType: _getFileType(filename),
        category: fileType.folderName,
      );
      return localPath;
    } catch (e) {
      debugPrint('Error uploading bytes to local storage: $e');
      return null;
    }
  }

  Future<void> _storeFileMetadata({
    required String fileId,
    required String filename,
    required String localPath,
    required String uploadedBy,
    required int fileSize,
    required String fileType,
    String? category,
  }) async {
    try {
      final metadata = FileMetadata(
        fileId: fileId,
        filename: filename,
        localPath: localPath,
        uploadedBy: uploadedBy,
        uploadedAt: DateTime.now(),
        fileSize: fileSize,
        fileType: fileType,
        category: category,
      );

      await _firestore
          .collection('file_metadata')
          .doc(fileId)
          .set(metadata.toMap());
    } catch (e) {
      debugPrint('Error storing file metadata: $e');
    }
  }

  Future<FileMetadata?> getFileMetadata(String fileId) async {
    try {
      final doc = await _firestore.collection('file_metadata').doc(fileId).get();
      if (doc.exists) {
        return FileMetadata.fromMap(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      debugPrint('Error retrieving file metadata: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String fileId) async {
    try {
      final metadata = await getFileMetadata(fileId);
      if (metadata != null) {
        final file = File(metadata.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        await _firestore.collection('file_metadata').doc(fileId).delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  Future<List<FileMetadata>> getUserFiles(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('file_metadata')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => FileMetadata.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error retrieving user files: $e');
      return [];
    }
  }

  Future<List<FileMetadata>> getRecentFiles({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('file_metadata')
          .orderBy('uploadedAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => FileMetadata.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error retrieving recent files: $e');
      return [];
    }
  }

  String _getFileType(String filename) {
    if (!filename.contains('.')) return 'unknown';
    return filename.split('.').last.toLowerCase();
  }
}
