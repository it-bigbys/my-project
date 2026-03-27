import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String creatorId;
  final String createdBy;
  final List<String> taggedUserIds;
  final List<String> taggedUserNames;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.creatorId,
    required this.createdBy,
    this.taggedUserIds = const [],
    this.taggedUserNames = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'creatorId': creatorId,
      'createdBy': createdBy,
      'taggedUserIds': taggedUserIds,
      'taggedUserNames': taggedUserNames,
    };
  }

  factory CalendarEvent.fromMap(String id, Map<String, dynamic> map) {
    return CalendarEvent(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      creatorId: map['creatorId'] ?? '',
      createdBy: map['createdBy'] ?? 'System',
      taggedUserIds: List<String>.from(map['taggedUserIds'] ?? []),
      taggedUserNames: List<String>.from(map['taggedUserNames'] ?? []),
    );
  }
}
