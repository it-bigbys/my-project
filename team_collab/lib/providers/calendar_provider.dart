import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/task.dart';

class CalendarProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<DateTime, List<CalendarEvent>> _events = {};
  Map<DateTime, List<Task>> _tasks = {};
  bool _isLoading = true;

  CalendarProvider() {
    _listenToEvents();
    _listenToTasks();
  }

  void _listenToEvents() {
    _db.collection('events').snapshots().listen((snapshot) {
      final Map<DateTime, List<CalendarEvent>> newEvents = {};
      for (var doc in snapshot.docs) {
        final event = CalendarEvent.fromMap(doc.id, doc.data());
        final key = DateTime(event.date.year, event.date.month, event.date.day);
        newEvents.putIfAbsent(key, () => []).add(event);
      }
      _events = newEvents;
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToTasks() {
    _db.collection('tasks').snapshots().listen((snapshot) {
      final Map<DateTime, List<Task>> newTasks = {};
      for (var doc in snapshot.docs) {
        final task = Task.fromMap(doc.id, doc.data());
        // Only include tasks that have assignees (since only assigned tasks can have dates set by assignees)
        if (task.assigneeId != null) {
          final key = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          newTasks.putIfAbsent(key, () => []).add(task);
        }
      }
      _tasks = newTasks;
      notifyListeners();
    });
  }

  List<dynamic> getFilteredItemsForDay(DateTime day, String userId, bool isSuperAdmin) {
    final key = DateTime(day.year, day.month, day.day);
    final events = _events[key] ?? [];
    final tasks = _tasks[key] ?? [];
    
    final filteredEvents = isSuperAdmin 
      ? events 
      : events.where((e) => e.creatorId == userId || e.taggedUserIds.contains(userId)).toList();
    
    final filteredTasks = isSuperAdmin
      ? tasks
      : tasks.where((t) => t.creatorId == userId || t.assigneeId == userId).toList();
    
    return [...filteredEvents, ...filteredTasks];
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  Map<DateTime, List<CalendarEvent>> get allEvents => _events;
  bool get isLoading => _isLoading;

  Future<void> addEvent(CalendarEvent event) async {
    try {
      await _db.collection('events').add(event.toMap());
    } catch (e) {
      debugPrint("Error adding event: $e");
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      await _db.collection('events').doc(eventId).update(data);
    } catch (e) {
      debugPrint("Error updating event: $e");
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _db.collection('events').doc(eventId).delete();
    } catch (e) {
      debugPrint("Error deleting event: $e");
    }
  }

  String get newId => _db.collection('events').doc().id;
}
