import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_collab/models/task.dart';

void main() {
  group('Task Approval Workflow Tests', () {
    test('TaskStatus includes awaitingApproval', () {
      // Verify the new status exists
      expect(TaskStatus.awaitingApproval, isNotNull);
      expect(TaskStatus.values.contains(TaskStatus.awaitingApproval), true);

      print('✅ TaskStatus includes awaitingApproval');
    });

    test('Task model supports awaitingApproval status', () {
      // Create a task with awaitingApproval status
      final task = Task(
        id: 'test_id',
        title: 'Test Task',
        description: 'Test Description',
        branch: 'Main',
        dateRequested: DateTime.now(),
        creatorId: 'creator_id',
        creatorName: 'Creator Name',
        status: TaskStatus.awaitingApproval,
        priority: TaskPriority.medium,
        dueDate: DateTime.now(),
      );

      expect(task.status, TaskStatus.awaitingApproval);
      expect(task.title, 'Test Task');

      print('✅ Task model supports awaitingApproval status');
    });

    test('TaskStatus enum has all expected values', () {
      // Verify all status values exist
      final expectedStatuses = [
        TaskStatus.todo,
        TaskStatus.inProgress,
        TaskStatus.done,
        TaskStatus.pending,
        TaskStatus.awaitingApproval,
      ];

      for (final status in expectedStatuses) {
        expect(TaskStatus.values.contains(status), true);
      }

      print('✅ TaskStatus enum has all expected values');
    });

    test('TaskPriority enum exists', () {
      // Verify TaskPriority enum exists and has expected values
      expect(TaskPriority.low, isNotNull);
      expect(TaskPriority.medium, isNotNull);
      expect(TaskPriority.high, isNotNull);

      print('✅ TaskPriority enum exists');
    });
  });
}
