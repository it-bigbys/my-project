import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;
import '../models/task.dart';
import '../services/local_storage_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService;
  
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _lastAttachmentLocalPath;

  String? get lastAttachmentLocalPath => _lastAttachmentLocalPath;

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  DateTime get _sevenDaysAgo => DateTime.now().subtract(const Duration(days: 7));

  List<Task> get todoTasks => _tasks.where((t) => t.status == TaskStatus.todo).toList();
  List<Task> get inProgressTasks => _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<Task> get doneTasks => _tasks.where((t) => t.status == TaskStatus.done).toList();
  List<Task> get recentDoneTasks => _tasks.where((t) => t.status == TaskStatus.done && (t.completedDate != null ? t.completedDate!.isAfter(_sevenDaysAgo) : true)).toList();
  List<Task> get pendingTasks => _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get awaitingApprovalTasks => _tasks.where((t) => t.status == TaskStatus.awaitingApproval).toList();
  List<Task> get visibleTasks => _tasks.where((t) => t.status != TaskStatus.done || (t.completedDate != null ? t.completedDate!.isAfter(_sevenDaysAgo) : true)).toList();

  TaskProvider({
    required LocalStorageService localStorageService,
  }) : _localStorageService = localStorageService {
    _listenToTasks();
  }

  void _listenToTasks() {
    _db.collection('tasks').orderBy('dueDate').snapshots().listen((snapshot) {
      _tasks = snapshot.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Process attachment: Save locally and return metadata for Firestore
  Future<Map<String, String>?> processAttachment({
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    try {
      String? localPath;
      String actualName = filename ?? (file != null ? p.basename(file.path) : 'attachment_${DateTime.now().millisecondsSinceEpoch}');

      debugPrint('Processing attachment: $actualName (file: ${file != null}, bytes: ${bytes != null})');

      if (file != null) {
        // Check file size limit (5MB)
        final fileSize = await file.length();
        if (fileSize > 5242880) {
          debugPrint('ERROR: File exceeds 5MB limit');
          return null;
        }

        // Save locally
        debugPrint('Saving file locally...');
        localPath = await _localStorageService.saveFileLocally(file, 'attachment');
        if (localPath == null) {
          debugPrint('ERROR: saveFileLocally returned null');
          return null;
        }
        debugPrint('File saved at: $localPath');
      } else if (bytes != null) {
        if (bytes.length > 5242880) {
          debugPrint('ERROR: Bytes exceed 5MB limit');
          return null;
        }

        // Save byte contents locally
        debugPrint('Saving bytes locally...');
        localPath = await _localStorageService.saveBytesLocally(bytes, actualName, 'attachment');
        if (localPath == null) {
          debugPrint('ERROR: saveBytesLocally returned null');
          return null;
        }
        debugPrint('Bytes saved at: $localPath');
      } else {
        debugPrint('ERROR: Neither file nor bytes provided');
        return null;
      }

      if (localPath != null) {
        return {
          'name': actualName,
          'localPath': localPath,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error processing task attachment: $e');
      return null;
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _db.collection('tasks').add(task.toMap());
    } catch (e) {
      debugPrint("Error adding task: $e");
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _db.collection('tasks').doc(taskId).update(data);
    } catch (e) {
      debugPrint("Error updating task: $e");
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final Map<String, dynamic> data = {'status': status.name};
      if (status == TaskStatus.done) {
        data['completedDate'] = DateTime.now().toIso8601String();
      } else {
        data['completedDate'] = FieldValue.delete();
      }
      await _db.collection('tasks').doc(taskId).update(data);
    } catch (e) {
      debugPrint("Error updating task status: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _db.collection('tasks').doc(taskId).delete();
    } catch (e) {
      debugPrint("Error deleting task: $e");
    }
  }

  Future<void> approveTask(String taskId) async {
    try {
      await _db.collection('tasks').doc(taskId).update({
        'status': TaskStatus.pending.name,
      });
    } catch (e) {
      debugPrint("Error approving task: $e");
      rethrow;
    }
  }

  Future<void> rejectTask(String taskId) async {
    try {
      await _db.collection('tasks').doc(taskId).update({
        'status': TaskStatus.todo.name,
      });
    } catch (e) {
      debugPrint("Error rejecting task: $e");
      rethrow;
    }
  }

  Future<String?> uploadAttachment({
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    final processed = await processAttachment(file: file, bytes: bytes, filename: filename);
    if (processed == null) return null;

    _lastAttachmentLocalPath = processed['localPath'];

    // Store local file path for the task attachment.
    return _lastAttachmentLocalPath;
  }

  String _resolveMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  String get newId => _db.collection('tasks').doc().id;
}
