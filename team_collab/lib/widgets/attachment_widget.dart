import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/download_service.dart';

/// Enhanced widget for displaying and downloading files in chat
class AttachmentWidget extends StatefulWidget {
  final String filePath; // Local file path or data URL
  final String? fileName;
  final bool compact; // Compact mode for inline display

  const AttachmentWidget({
    Key? key,
    required this.filePath,
    this.fileName,
    this.compact = false,
  }) : super(key: key);

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final fileName = widget.fileName ?? 'File';
    final isImage = _isImageFile(fileName);

    if (isImage) {
      return _buildImageAttachment(fileName);
    } else {
      return _buildFileAttachment(fileName);
    }
  }

  Widget _buildImageAttachment(String fileName) {
    return GestureDetector(
      onTap: () => _showImageZoomModal(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildFileAttachment(String fileName) {
    final theme = Theme.of(context);
    final fileExtension = _getFileExtension(fileName);
    final fileIcon = _getFileIcon(fileExtension);

    if (widget.compact) {
      return GestureDetector(
        onTap: () async => await _handleFileAction(context, fileName),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
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
        ),
      );
    }

    return GestureDetector(
      onTap: () async => await _handleFileAction(context, fileName),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
              else
                Icon(
                  kIsWeb ? Icons.download : Icons.open_in_new,
                  size: 18,
                  color: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.filePath.startsWith('data:image')) {
      return _buildBase64Image();
    } else if (widget.filePath.startsWith('http://') ||
        widget.filePath.startsWith('https://')) {
      return Image.network(
        widget.filePath,
        width: 240,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    } else if (!kIsWeb && widget.filePath.isNotEmpty) {
      return Image.file(
        io.File(widget.filePath),
        width: 240,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    }
    return _buildErrorWidget();
  }

  Widget _buildBase64Image() {
    try {
      final base64String = widget.filePath.split(',').last;
      final bytes = Uint8List.fromList(
        Uri.parse('data:application/octet-stream;base64,$base64String')
            .data!
            .contentAsBytes(),
      );
      return Image.memory(
        bytes,
        width: 240,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 240,
      height: 240,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 40),
      ),
    );
  }

  void _showImageZoomModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImageZoomModal(
        imagePath: widget.filePath,
        fileName: widget.fileName,
        onDownload: () async {
          Navigator.pop(context);
          await _downloadImage();
        },
      ),
    );
  }

  Future<void> _handleFileAction(BuildContext context, String fileName) async {
    if (kIsWeb) {
      await _downloadFile(fileName);
    } else {
      await _openFileNative();
    }
  }

  Future<void> _downloadFile(String fileName) async {
    if (!mounted) return;
    setState(() => _isDownloading = true);

    try {
      if (widget.filePath.startsWith('data:')) {
        // Data URL
        final parts = widget.filePath.split(',');
        if (parts.length >= 2) {
          await DownloadService.downloadFileFromBase64(
            base64Data: parts[1],
            fileName: fileName,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$fileName downloaded successfully')),
            );
          }
        }
      } else if (widget.filePath.startsWith('http://') ||
          widget.filePath.startsWith('https://')) {
        if (await canLaunchUrl(Uri.parse(widget.filePath))) {
          await launchUrl(
            Uri.parse(widget.filePath),
            mode: LaunchMode.externalApplication,
          );
        }
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

  Future<void> _downloadImage() async {
    if (!mounted) return;
    setState(() => _isDownloading = true);

    try {
      if (widget.filePath.startsWith('data:')) {
        final parts = widget.filePath.split(',');
        if (parts.length >= 2) {
          await DownloadService.downloadFileFromBase64(
            base64Data: parts[1],
            fileName: widget.fileName ?? 'image.jpg',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image downloaded successfully')),
            );
          }
        }
      } else if (widget.filePath.startsWith('http://') ||
          widget.filePath.startsWith('https://')) {
        if (await canLaunchUrl(Uri.parse(widget.filePath))) {
          await launchUrl(
            Uri.parse(widget.filePath),
            mode: LaunchMode.externalApplication,
          );
        }
      } else if (!kIsWeb) {
        final file = io.File(widget.filePath);
        if (await file.exists()) {
          await launchUrl(Uri.file(widget.filePath));
        }
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _openFileNative() async {
    try {
      if (widget.filePath.startsWith('http://') ||
          widget.filePath.startsWith('https://')) {
        if (await canLaunchUrl(Uri.parse(widget.filePath))) {
          await launchUrl(
            Uri.parse(widget.filePath),
            mode: LaunchMode.externalApplication,
          );
        }
      } else if (!kIsWeb) {
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
    }
  }

  bool _isImageFile(String fileName) {
    final ext = _getFileExtension(fileName).toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'].contains(ext);
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

/// Full-screen image zoom modal
class ImageZoomModal extends StatefulWidget {
  final String imagePath;
  final String? fileName;
  final Future<void> Function() onDownload;

  const ImageZoomModal({
    Key? key,
    required this.imagePath,
    this.fileName,
    required this.onDownload,
  }) : super(key: key);

  @override
  State<ImageZoomModal> createState() => _ImageZoomModalState();
}

class _ImageZoomModalState extends State<ImageZoomModal> {
  late TransformationController _transformationController;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Image viewer with pinch-to-zoom
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 5.0,
            child: Center(
              child: _buildImageContent(),
            ),
          ),

          // Close button
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Download button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _handleDownload,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isDownloading ? 'Downloading...' : 'Download Image',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image info bar
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              widget.fileName ?? 'Image',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.imagePath.startsWith('data:image')) {
      return _buildBase64Image();
    } else if (widget.imagePath.startsWith('http://') ||
        widget.imagePath.startsWith('https://')) {
      return Image.network(
        widget.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    } else if (!kIsWeb && widget.imagePath.isNotEmpty) {
      return Image.file(
        io.File(widget.imagePath),
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    }
    return _buildErrorWidget();
  }

  Widget _buildBase64Image() {
    try {
      final base64String = widget.imagePath.split(',').last;
      final bytes = Uint8List.fromList(
        Uri.parse('data:application/octet-stream;base64,$base64String')
            .data!
            .contentAsBytes(),
      );
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _buildErrorWidget(),
      );
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.broken_image, size: 60, color: Colors.white),
        SizedBox(height: 12),
        Text(
          'Image failed to load',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);

    try {
      await widget.onDownload();
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}
