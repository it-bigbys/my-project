enum TaskStatus { todo, inProgress, done }
enum TaskPriority { low, medium, high }

class Task {
  final String id;
  String title;
  String description;
  String assigneeId;
  String assigneeName;
  TaskStatus status;
  TaskPriority priority;
  DateTime dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.status,
    required this.priority,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'status': status.name,
      'priority': priority.name,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assigneeId: map['assigneeId'] ?? '',
      assigneeName: map['assigneeName'] ?? '',
      status: TaskStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => TaskStatus.todo),
      priority: TaskPriority.values.firstWhere((e) => e.name == map['priority'], orElse: () => TaskPriority.medium),
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}
