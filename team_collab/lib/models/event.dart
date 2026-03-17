import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String createdBy;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory CalendarEvent.fromMap(String id, Map<String, dynamic> map) {
    return CalendarEvent(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      createdBy: map['createdBy'] ?? 'System',
    );
  }
}
