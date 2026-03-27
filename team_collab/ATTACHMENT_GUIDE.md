# Attachment Viewing & Downloading Guide

## Overview

Your Team Collaboration app now has enhanced attachment viewing and downloading capabilities. Attachments can be sent in chat, attached to tasks, and are now viewable/downloadable across all platforms (web, mobile, desktop).

## Features

### 1. **Chat Attachments**
- **Images**: Display inline with tap-to-view functionality
- **Files**: Show with file type icon and name
- **Web Support**: Click to download files
- **Mobile Support**: Tap to open with default application

### 2. **Task Attachments**
- **Inline Preview**: See attachment info in task summary
- **Edit Form**: Preview before saving
- **Download Support**: Access attachments when viewing tasks

### 3. **Cross-Platform Support**
- **Web**: Blob-based downloads with proper file names
- **Mobile (iOS/Android)**: Open with default app or save to device
- **Desktop**: Open with associated application

## How to Use

### **Sending Attachments in Chat**

1. Click the **+ icon** in the chat input area
2. Choose one of these options:
   - **Camera** - Take a photo (mobile only)
   - **Gallery** - Select an image from your device
   - **File** - Select any document type

3. Supported file types:
   - **Images**: JPG, PNG, GIF, BMP
   - **Documents**: PDF, DOC, DOCX
   - **Spreadsheets**: XLS, XLSX
   - **Presentations**: PPT, PPTX
   - **Archives**: ZIP, RAR
   - **Audio**: MP3, WAV, AAC
   - **Video**: MP4, AVI, MOV
   - **Other**: TXT, any file up to 5MB

### **Viewing Chat Attachments**

#### *On Web*
- **Images**: Click to view full size
- **Files**: Click to download

#### *On Mobile/Desktop*
- **Images**: Tap to view
- **Files**: Tap to open with default app (or downloads to device)

### **Adding Attachments to Tasks**

1. Create or edit a task
2. Go to **Attachments** section
3. Click **Add Attachment**
4. Select file from your device
5. File will be saved and associated with the task
6. Click **Submit** to save the task

### **Viewing Task Attachments**

- **In Task List**: Hover over task to see attachment icon
- **In Task Details**: Click attachment to download/open
- **Compact View**: Attachment shown with icon and filename

## Technical Implementation

### **New Components**

1. **FileViewerWidget** - Main widget for displaying and downloading files
   - Location: `lib/widgets/file_viewer_widget.dart`
   - Handles both images and documents
   - Supports compact and full size modes

2. **ImageViewerWidget** - Specialized widget for image display
   - Shows images from local files, data URLs, or remote URLs
   - Error handling with fallback UI

3. **DownloadService** - Cross-platform download handling
   - Location: `lib/services/download_service.dart`
   - Blob API for web downloads
   - URL launcher for native platforms
   - MIME type detection

### **Files Modified**

- **chat_screen.dart**: Updated to use FileViewerWidget for attachments
- **tasks_screen.dart**: Used FileViewerWidget for task attachment display
- **file_viewer_widget.dart**: New comprehensive file viewer/downloader
- **download_service.dart**: New service for handling downloads

### **Dependencies Added**

```yaml
universal_html: ^2.2.3
```

This enables cross-platform HTML API access needed for web blob downloads.

## File Size Limits

- **Maximum file size**: 5MB per file
- **Compression**: Images are automatically compressed to 50% quality when uploaded

## Supported MIME Types

The system automatically detects file types and assigns appropriate icons:

| File Type | Icon |
|-----------|------|
| PDF | 📄 |
| Documents (DOC, DOCX) | 📝 |
| Spreadsheets (XLS, XLSX) | 📊 |
| Presentations (PPT, PPTX) | 📽️ |
| Images (JPG, PNG, GIF) | 🖼️ |
| Archives (ZIP, RAR) | 📦 |
| Audio (MP3, WAV) | 🎵 |
| Video (MP4, AVI, MOV) | 🎬 |
| Text (TXT) | 📋 |
| Generic File | 📎 |

## Platform-Specific Behavior

### **Web Platform**
- Files stored as base64 in Firestore
- Downloads use blob API for direct download
- Automatic MIME type detection
- Success notification after download

### **iOS Platform**
- Files saved to app documents directory
- Long-press to get open options
- Can share files with other apps
- Default app opens based on file type

### **Android Platform**
- Files saved to app cache/documents
- Tap to open with appropriate app
- Downloads can be accessed via file manager
- Supports sharing to other applications

### **Windows/macOS Platform**
- Files saved locally
- Tap to open with default application
- File manager integration

## Troubleshooting

### **File Not Downloading**
- Check file size (must be ≤ 5MB)
- Verify browser has storage permissions
- Try a different browser on web

### **Image Not Displaying**
- Ensure image format is supported
- Check file isn't corrupted
- Verify sufficient device storage

### **File Type Icon Not Showing**
- File extension may be unrecognized
- Falls back to generic file icon
- Contact admin to add support for new types

## Future Enhancements

Potential improvements for future versions:
- File preview modal (PDF viewer, image gallery)
- Direct file sharing functionality
- Attachment history/search
- Attachment size warnings
- File expiration policies
- Encryption for sensitive files
- Cloud storage integration (Google Drive, OneDrive)

## Security Notes

- Files are stored locally on device first
- Firestore stores only file metadata and paths
- File access is restricted to app users
- Consider encrypting sensitive data before uploading
- For production, implement additional access controls

---

**For technical support** or questions about attachments, contact your system administrator.
