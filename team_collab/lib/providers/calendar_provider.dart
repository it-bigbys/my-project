import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class CalendarProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;

  CalendarProvider() {
    _listenToEvents();
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

  String get newId => _db.collection('events').doc().id;
}
