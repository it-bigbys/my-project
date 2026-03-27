import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../models/task.dart';
import '../models/event.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<AppNotification> _notifications = [];
  SharedPreferences? _prefs;

  List<AppNotification> get notifications => List.unmodifiable(_notifications.reversed);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _initPrefs();
    _listenToNotifications();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _listenToNotifications() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _db.collection('users').doc(user.uid).collection('notifications')
            .orderBy('timestamp', descending: false)
            .snapshots()
            .listen((snapshot) {
          _notifications = snapshot.docs.map((doc) => AppNotification.fromMap(doc.id, doc.data())).toList();
          notifyListeners();
        });
      } else {
        _notifications = [];
        notifyListeners();
      }
    });
  }

  // Check for upcoming events and tasks for the day
  void checkUpcomingReminders(List<Task> tasks, Map<DateTime, List<CalendarEvent>> events, String userId) async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Check Tasks due today
    for (var task in tasks) {
      if (task.assigneeId == userId && task.status != TaskStatus.done) {
        final taskDate = DateFormat('yyyy-MM-dd').format(task.dueDate);
        if (taskDate == todayStr) {
          final prefKey = 'reminder_task_${task.id}_$todayStr';
          if (!(_prefs?.getBool(prefKey) ?? false)) {
            await _sendLocalReminder(
              'Task Due Today',
              'Your task "${task.title}" is due today!',
              NotificationType.task,
            );
            await _prefs?.setBool(prefKey, true);
          }
        }
      }
    }

    // Check Events today (where user is creator or tagged)
    final today = DateTime(now.year, now.month, now.day);
    final todaysEvents = events[today] ?? [];
    for (var event in todaysEvents) {
      if (event.creatorId == userId || event.taggedUserIds.contains(userId)) {
        final prefKey = 'reminder_event_${event.id}_$todayStr';
        if (!(_prefs?.getBool(prefKey) ?? false)) {
          final timeString = DateFormat('h:mm a').format(event.date);
          await _sendLocalReminder(
            'Upcoming Event',
            'You have an event: "${event.title}" at $timeString',
            NotificationType.event,
          );
          await _prefs?.setBool(prefKey, true);
        }
      }
    }
  }

  Future<void> _sendLocalReminder(String title, String body, NotificationType type) async {
    // Add to Firestore so it shows up in the notifications tab
    await addNotification(title, body, type);
  }

  Future<void> addNotification(String title, String body, NotificationType type) async {
    final user = _auth.currentUser;
    if (user != null) {
      final notif = AppNotification(
        id: '',
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).collection('notifications').add(notif.toMap());
    }
  }

  Future<void> markAsRead(String id) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('notifications').doc(id).update({'isRead': true});
    }
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user != null) {
      final batch = _db.batch();
      final snapshots = await _db.collection('users').doc(user.uid).collection('notifications').where('isRead', isEqualTo: false).get();
      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }
}
