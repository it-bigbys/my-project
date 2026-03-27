import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

/// Service for handling file downloads across all platforms
/// Provides enhanced support for web downloads with blob/anchor tag approach
class DownloadService {
  /// Download file from base64 data on web platform
  /// On native platforms, this does nothing (files are handled by url_launcher)
  static Future<void> downloadFileFromBase64({
    required String base64Data,
    required String fileName,
  }) async {
    if (!kIsWeb) {
      debugPrint('Use url_launcher for native platform downloads');
      return;
    }

    try {
      _downloadFileWeb(base64Data, fileName);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }

  /// Download file from bytes
  static Future<void> downloadFileFromBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!kIsWeb) {
      debugPrint('Use url_launcher for native platform downloads');
      return;
    }

    try {
      final base64 = base64Encode(bytes);
      _downloadFileWeb(base64, fileName);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }

  /// Download file using web blob API
  static void _downloadFileWeb(String base64Data, String fileName) {
    try {
      // Create blob from base64
      final bytes = base64Decode(base64Data);
      final blob = html.Blob([bytes]);
      
      // Create blob URL
      final blobUrl = html.Url.createObjectUrl(blob);
      
      // Create and trigger download
      final anchor = html.AnchorElement(href: blobUrl)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      
      // Cleanup
      html.Url.revokeObjectUrl(blobUrl);
      
      debugPrint('File downloaded: $fileName');
    } catch (e) {
      debugPrint('Error with blob download: $e');
      rethrow;
    }
  }

  /// Get MIME type from file extension
  static String getMimeType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    
    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'aac': 'audio/aac',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'json': 'application/json',
      'xml': 'application/xml',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
    };
    
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  /// Check if file extension is viewable in browser
  static bool isViewableInBrowser(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    final viewableExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'txt', 'svg'];
    return viewableExtensions.contains(ext);
  }

  /// Check if file is an image
  static bool isImage(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'];
    return imageExtensions.contains(ext);
  }

  /// Check if file is a document
  static bool isDocument(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    final documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv'];
    return documentExtensions.contains(ext);
  }
}
