import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications.reversed);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _listenToNotifications();
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
