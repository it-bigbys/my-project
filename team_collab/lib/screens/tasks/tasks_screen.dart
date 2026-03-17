import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/task.dart';
import '../../models/notification.dart';
import '../../widgets/responsive_scaffold.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return ResponsiveScaffold(
      title: 'Tasks',
      currentRoute: '/tasks',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isMobile 
        ? Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF6366F1),
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: const Color(0xFF64748B),
                tabs: const [
                  Tab(text: 'To Do'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Done'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TaskList(tasks: taskProvider.todoTasks),
                    _TaskList(tasks: taskProvider.inProgressTasks),
                    _TaskList(tasks: taskProvider.doneTasks),
                  ],
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KanbanColumn(title: 'To Do', color: const Color(0xFF64748B), tasks: taskProvider.todoTasks),
                const SizedBox(width: 16),
                _KanbanColumn(title: 'In Progress', color: const Color(0xFFF59E0B), tasks: taskProvider.inProgressTasks),
                const SizedBox(width: 16),
                _KanbanColumn(title: 'Done', color: const Color(0xFF10B981), tasks: taskProvider.doneTasks),
              ],
            ),
          ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddTaskDialog());
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;

  const _KanbanColumn({required this.title, required this.color, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${tasks.length}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: tasks.length,
                itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high: return const Color(0xFFEF4444);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.low: return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(task.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(task.priority.name.toUpperCase(), style: TextStyle(color: _priorityColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(task.description, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(
              radius: 12, 
              backgroundColor: const Color(0xFF6366F1), 
              child: Text(
                _getInitials(task.assigneeName), 
                style: const TextStyle(color: Colors.white, fontSize: 9)
              )
            ),
            const SizedBox(width: 8),
            Text(task.assigneeName.split(' ').first, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(DateFormat('MMM d').format(task.dueDate), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ]),
          const Divider(height: 24),
          _StatusDropdown(task: task),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '??';
    final parts = name.trim().split(' ');
    String initials = '';
    for (var part in parts) {
      if (part.isNotEmpty) initials += part[0];
    }
    return initials.toUpperCase().substring(0, initials.length > 2 ? 2 : initials.length);
  }
}

class _StatusDropdown extends StatelessWidget {
  final Task task;
  const _StatusDropdown({required this.task});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
        child: DropdownButton<TaskStatus>(
          value: task.status,
          isDense: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6366F1)),
          items: TaskStatus.values.map((s) {
            final label = s == TaskStatus.todo ? 'To Do' : s == TaskStatus.inProgress ? 'In Progress' : 'Done';
            return DropdownMenuItem(value: s, child: Text(label));
          }).toList(),
          onChanged: (s) {
            if (s != null) context.read<TaskProvider>().updateTaskStatus(task.id, s);
          },
        ),
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  String? _assigneeId;
  String? _assigneeName;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty || _assigneeId == null) return;
    
    final taskProvider = context.read<TaskProvider>();
    final notifProvider = context.read<NotificationProvider>();
    
    final newTask = Task(
      id: taskProvider.newId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      assigneeId: _assigneeId!,
      assigneeName: _assigneeName!,
      status: TaskStatus.todo,
      priority: _priority,
      dueDate: _dueDate,
    );
    
    taskProvider.addTask(newTask);
    
    // Trigger notification popup simulation
    notifProvider.addNotification(
      'New Task Assigned',
      'Task "${newTask.title}" has been assigned to ${_assigneeName}.',
      NotificationType.task,
    );

    _showAssignmentPopup(context, _assigneeName!, newTask.title);
    
    Navigator.pop(context);
  }

  void _showAssignmentPopup(BuildContext context, String name, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.assignment_ind, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text('New task assigned to $name: $title')),
        ]),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'VIEW', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.read<AuthProvider>().teamMembers;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _field('Title', _titleController, 'e.g. Design mobile login screen'),
              const SizedBox(height: 16),
              _field('Description', _descController, 'What needs to be done?', maxLines: 3),
              const SizedBox(height: 16),
              const Text('Assignee', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _assigneeId,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                decoration: _inputDec('Select member'),
                items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                onChanged: (v) {
                  setState(() {
                    _assigneeId = v;
                    _assigneeName = members.firstWhere((m) => m.id == v).name;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TaskPriority>(
                          value: _priority,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                          decoration: _inputDec(''),
                          items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Date', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (picked != null) setState(() => _dueDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 10),
                              Text(DateFormat('MMM d').format(_dueDate), style: const TextStyle(fontSize: 14)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B)))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Create Task'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, maxLines: maxLines, style: const TextStyle(fontSize: 14), decoration: _inputDec(hint)),
    ]);
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF475569)),
    filled: true,
    fillColor: Theme.of(context).scaffoldBackgroundColor,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
