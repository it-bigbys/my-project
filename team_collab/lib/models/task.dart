import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { todo, inProgress, done, pending, awaitingApproval }
enum TaskPriority { low, medium, high }

class Task {
  final String id;
  String title;
  String description;
  String branch;
  DateTime dateRequested;
  String? assigneeId;
  String? assigneeName;
  String creatorId;
  String creatorName;
  TaskStatus status;
  TaskPriority priority;
  DateTime dueDate;
  List<String> services;
  String? attachmentData; // Base64 string for Firestore
  String? attachmentName;
  String? attachmentUrl; // optional direct link or local URI
  String? attachmentLocalPath;
  DateTime? completedDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.branch,
    required this.dateRequested,
    this.assigneeId,
    this.assigneeName,
    required this.creatorId,
    required this.creatorName,
    required this.status,
    required this.priority,
    required this.dueDate,
    this.services = const [],
    this.attachmentData,
    this.attachmentName,
    this.attachmentUrl,
    this.attachmentLocalPath,
    this.completedDate,
  });

  Map<String, dynamic> toMap() {
    final data = {
      'title': title,
      'description': description,
      'branch': branch,
      'dateRequested': dateRequested.toIso8601String(),
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'status': status.name,
      'priority': priority.name,
      'dueDate': dueDate.toIso8601String(),
      'services': services,
      // Store only metadata and local file path; avoid storing raw binary data in Firestore
      'attachmentName': attachmentName,
      'attachmentLocalPath': attachmentLocalPath,
    };
    if (completedDate != null) {
      data['completedDate'] = completedDate!.toIso8601String();
    }
    return data;
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assigneeId: map['assigneeId'],
      assigneeName: map['assigneeName'],
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? 'Unknown',
      status: TaskStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => TaskStatus.todo),
      priority: TaskPriority.values.firstWhere((e) => e.name == map['priority'], orElse: () => TaskPriority.medium),
      branch: map['branch'] ?? '',
      dateRequested: map.containsKey('dateRequested') && map['dateRequested'] != null
        ? DateTime.parse(map['dateRequested'])
        : DateTime.now(),
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      services: map['services'] != null
        ? List<String>.from(map['services'])
        : [],
      attachmentData: map['attachmentData'],
      attachmentName: map['attachmentName'],
      attachmentUrl: map['attachmentUrl'],
      attachmentLocalPath: map['attachmentLocalPath'],
      completedDate: map.containsKey('completedDate') && map['completedDate'] != null
        ? DateTime.parse(map['completedDate'])
        : null,
    );
  }
}
