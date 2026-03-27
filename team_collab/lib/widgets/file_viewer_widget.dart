import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/download_service.dart';

/// Widget for displaying and downloading files in chat or other contexts.
/// Handles all platforms: web, mobile, and desktop.
class FileViewerWidget extends StatefulWidget {
  final String filePath; // Local file path or data URL
  final String? fileName;
  final VoidCallback? onTap;
  final bool allowDownload;
  final bool compact; // Compact mode for inline display

  const FileViewerWidget({
    Key? key,
    required this.filePath,
    this.fileName,
    this.onTap,
    this.allowDownload = true,
    this.compact = false,
  }) : super(key: key);

  @override
  State<FileViewerWidget> createState() => _FileViewerWidgetState();
}

class _FileViewerWidgetState extends State<FileViewerWidget> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = widget.fileName ?? 'File';
    final fileExtension = _getFileExtension(fileName);
    final fileIcon = _getFileIcon(fileExtension);

    if (widget.compact) {
      return GestureDetector(
        onTap: () async {
          widget.onTap?.call();
          if (widget.allowDownload) {
            await _handleFileAction(context, fileName);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fileIcon, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                fileName,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        widget.onTap?.call();
        if (widget.allowDownload) {
          await _handleFileAction(context, fileName);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fileIcon, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.allowDownload && kIsWeb)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tap to download',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isDownloading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (widget.allowDownload)
              Icon(
                kIsWeb ? Icons.download : Icons.open_in_new,
                size: 18,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileAction(BuildContext context, String fileName) async {
    if (kIsWeb) {
      await _downloadFileWeb(fileName);
    } else {
      await _openFileNative();
    }
  }

  Future<void> _downloadFileWeb(String fileName) async {
    if (!mounted) return;
    setState(() => _isDownloading = true);

    try {
      if (widget.filePath.startsWith('data:')) {
        // Data URL - extract base64 and download
        await _downloadDataUrl(widget.filePath, fileName);
      } else if (widget.filePath.startsWith('http://') ||
          widget.filePath.startsWith('https://')) {
        // Remote URL - use url_launcher to download
        if (await canLaunchUrl(Uri.parse(widget.filePath))) {
          await launchUrl(
            Uri.parse(widget.filePath),
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open file')),
            );
          }
        }
      } else {
        // Local file path on web
        _showNotSupported(context);
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _downloadDataUrl(String dataUrl, String fileName) async {
    try {
      // Parse data URL and extract base64
      final parts = dataUrl.split(',');
      if (parts.length < 2) {
        throw Exception('Invalid data URL format');
      }

      final base64String = parts[1];
      
      // Use DownloadService for cross-platform download
      await DownloadService.downloadFileFromBase64(
        base64Data: base64String,
        fileName: fileName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName downloaded successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error processing data URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _openFileNative() async {
    try {
      // Handle local file on native platforms
      if (widget.filePath.startsWith('http://') ||
          widget.filePath.startsWith('https://')) {
        if (await canLaunchUrl(Uri.parse(widget.filePath))) {
          await launchUrl(
            Uri.parse(widget.filePath),
            mode: LaunchMode.externalApplication,
          );
        }
      } else if (!kIsWeb) {
        // Local file path
        final file = io.File(widget.filePath);
        if (await file.exists()) {
          await launchUrl(Uri.file(widget.filePath));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File not found')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showNotSupported(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File download not available for this file type'),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.music_note;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_library;
      case 'txt':
        return Icons.text_fields;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileExtension(String fileName) {
    if (!fileName.contains('.')) return '';
    return fileName.split('.').last;
  }
}

/// Image viewer widget for displaying images from chat
class ImageViewerWidget extends StatelessWidget {
  final String imagePath; // Local path or data URL
  final String? label;
  final VoidCallback? onTap;
  final double width;
  final BoxFit fit;

  const ImageViewerWidget({
    Key? key,
    required this.imagePath,
    this.label,
    this.onTap,
    this.width = 240,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (imagePath.startsWith('data:image')) {
      // Handle base64 image
      return _buildBase64Image();
    } else if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      // Handle remote image
      return Image.network(
        imagePath,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    } else if (!kIsWeb && imagePath.isNotEmpty) {
      // Handle local file
      return Image.file(
        io.File(imagePath),
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    }
    return _buildErrorWidget();
  }

  Widget _buildBase64Image() {
    try {
      final base64String = imagePath.split(',').last;
      final bytes = Uint8List.fromList(
        Uri.parse('data:application/octet-stream;base64,$base64String')
            .data!
            .contentAsBytes(),
      );
      return Image.memory(
        bytes,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: width,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 40),
      ),
    );
  }
}
