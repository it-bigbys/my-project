import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  List<Task> get todoTasks => _tasks.where((t) => t.status == TaskStatus.todo).toList();
  List<Task> get inProgressTasks => _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<Task> get doneTasks => _tasks.where((t) => t.status == TaskStatus.done).toList();

  TaskProvider() {
    _listenToTasks();
  }

  void _listenToTasks() {
    _db.collection('tasks').orderBy('dueDate').snapshots().listen((snapshot) {
      _tasks = snapshot.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addTask(Task task) async {
    try {
      await _db.collection('tasks').add(task.toMap());
    } catch (e) {
      debugPrint("Error adding task: $e");
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      await _db.collection('tasks').doc(taskId).update({'status': status.name});
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

  String get newId => _db.collection('tasks').doc().id;
}
