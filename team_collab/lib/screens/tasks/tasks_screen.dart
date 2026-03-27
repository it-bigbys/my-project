import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/attachment_widget.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks, AuthProvider auth) {
    List<Task> filtered = tasks;
    if (_searchQuery.isEmpty) return filtered;

    final query = _searchQuery.toLowerCase();
    return filtered.where((task) {
      return task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          (task.assigneeName?.toLowerCase().contains(query) ?? false) ||
          task.creatorName.toLowerCase().contains(query) ||
          task.branch.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final authProvider = context.watch<AuthProvider>();
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final theme = Theme.of(context);

    final pendingTasks = taskProvider.pendingTasks;
    final awaitingApprovalTasks = taskProvider.awaitingApprovalTasks;
    final todoTasks = taskProvider.todoTasks;
    final inProgressTasks = taskProvider.inProgressTasks;
    final doneTasks = taskProvider.recentDoneTasks;

    return ResponsiveScaffold(
      title: 'Tasks',
      currentRoute: '/tasks',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 32, 16, isMobile ? 16 : 32, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          Expanded(
            child: isMobile
                ? Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: theme.primaryColor,
                        labelColor: theme.primaryColor,
                        unselectedLabelColor: const Color(0xFF64748B),
                        tabs: const [
                          Tab(text: 'Requests'),
                          Tab(text: 'Awaiting Approval'),
                          Tab(text: 'To Do'),
                          Tab(text: 'In Progress'),
                          Tab(text: 'Done'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _TaskList(
                                tasks:
                                    _filterTasks(pendingTasks, authProvider)),
                            _TaskList(
                                tasks: _filterTasks(
                                    awaitingApprovalTasks, authProvider)),
                            _TaskList(
                                tasks: _filterTasks(todoTasks, authProvider)),
                            _TaskList(
                                tasks: _filterTasks(
                                    inProgressTasks, authProvider)),
                            _TaskList(
                                tasks: _filterTasks(doneTasks, authProvider)),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _KanbanColumn(
                            title: 'Requests',
                            color: Colors.purple,
                            tasks: _filterTasks(pendingTasks, authProvider)),
                        const SizedBox(width: 16),
                        _KanbanColumn(
                            title: 'Awaiting Approval',
                            color: const Color(0xFFFF6B35),
                            tasks: _filterTasks(
                                awaitingApprovalTasks, authProvider)),
                        const SizedBox(width: 16),
                        _KanbanColumn(
                            title: 'To Do',
                            color: const Color(0xFF64748B),
                            tasks: _filterTasks(todoTasks, authProvider)),
                        const SizedBox(width: 16),
                        _KanbanColumn(
                            title: 'In Progress',
                            color: const Color(0xFFFFD700),
                            tasks: _filterTasks(inProgressTasks, authProvider)),
                        const SizedBox(width: 16),
                        _KanbanColumn(
                            title: 'Done',
                            color: const Color(0xFF10B981),
                            tasks: _filterTasks(doneTasks, authProvider)),
                      ],
                    ),
                  ),
          ),
        ],
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
    if (tasks.isEmpty) {
      return const Center(
          child: Text('No tasks found', style: TextStyle(color: Colors.grey)));
    }
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

  const _KanbanColumn(
      {required this.title, required this.color, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${tasks.length}',
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
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
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    bool _isAssigneeIT() {
      if (task.assigneeId == null) return false;
      try {
        return auth.teamMembers
                .firstWhere((m) => m.id == task.assigneeId)
                .role ==
            'IT';
      } catch (_) {
        return false;
      }
    }

    // Admins/Super Admins edit everything.
    // Secretaries edit Pending tasks OR tasks assigned to IT.
    // Creators edit only while awaiting approval.
    final canEditFullDetails = auth.isAdminRole ||
        (auth.isSecretary && (task.status == TaskStatus.pending || _isAssigneeIT())) ||
        ((auth.isBranch || auth.isGOM) &&
            task.creatorId == auth.currentUser?.id &&
            task.status == TaskStatus.awaitingApproval);

    final taskCard = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (canEditFullDetails) {
                _showEditTaskDialog(context, task);
              } else {
                _showTaskDetailsDialog(context, task);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(task.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2),
              ],
            ),
          ),
          if (task.attachmentData != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(child: Text(task.attachmentName ?? 'Attachment', style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.store, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(task.branch.isNotEmpty ? task.branch : 'Branch N/A',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Spacer(),
            const Icon(Icons.person_outline, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(task.assigneeName ?? 'Unassigned',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(DateFormat('MMM dd').format(task.dueDate),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
          if (task.creatorId != task.assigneeId) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.create, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Created by ${task.creatorName}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ],
          if (task.status == TaskStatus.awaitingApproval && auth.isGOM) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveTask(context, task.id),
                    icon: const Icon(Icons.check, size: 16),
                    label:
                        const Text('Approve', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectTask(context, task.id),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (task.assigneeId == auth.currentUser?.id || auth.isAdminRole) ...[
            const Divider(height: 20),
            _StatusDropdown(task: task),
          ],
          if (task.creatorId == auth.currentUser?.id && !auth.isIT && !auth.isSecretary && !auth.isAdminRole) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _cancelTask(context, task.id),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel Task', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ],
      ),
    );

    return taskCard
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 16, end: 0, duration: 250.ms);
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(context: context, builder: (_) => _AddTaskDialog(task: task));
  }

  void _showTaskDetailsDialog(BuildContext context, Task task) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Branch', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.branch),
              const SizedBox(height: 16),
              Text('Services', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.services.join(', ')),
              const SizedBox(height: 16),
              Text('Details', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(task.description),
              const SizedBox(height: 16),
              Text('Assigned To', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(task.assigneeName ?? 'Unassigned'),
              const SizedBox(height: 16),
              Text('Due Date', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(DateFormat('MMM dd, yyyy').format(task.dueDate)),
              const SizedBox(height: 16),
              Text('Status', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(task.status.name.toUpperCase()),
              if (task.attachmentData != null) ...[
                const SizedBox(height: 16),
                Text('Attachment', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Icon(Icons.attach_file, color: Colors.blue),
                Text(task.attachmentName ?? 'File', style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _approveTask(BuildContext context, String taskId) async {
    try {
      await context.read<TaskProvider>().approveTask(taskId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task approved successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to approve task: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _rejectTask(BuildContext context, String taskId) async {
    try {
      await context.read<TaskProvider>().rejectTask(taskId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task rejected and sent back to creator'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to reject task: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelTask(BuildContext context, String taskId) async {
    try {
      await context.read<TaskProvider>().deleteTask(taskId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task cancelled and removed'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to cancel task: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StatusDropdown extends StatelessWidget {
  final Task task;
  const _StatusDropdown({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    
    final canChangeStatus = task.assigneeId == auth.currentUser?.id || auth.isAdminRole;

    return DropdownButtonHideUnderline(
      child: DropdownButton<TaskStatus>(
        value: task.status,
        isDense: true,
        disabledHint: Text(task.status.name.toUpperCase(),
            style: TextStyle(
                color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        style: TextStyle(
            color: theme.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold),
        items: TaskStatus.values
            .map((s) =>
                DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
            .toList(),
        onChanged: canChangeStatus
            ? (s) {
                if (s != null)
                  context.read<TaskProvider>().updateTaskStatus(task.id, s);
              }
            : null,
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  final Task? task;
  const _AddTaskDialog({this.task});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _branchController;
  String? _assigneeId;
  String? _assigneeName;
  String? _attachmentData;
  String? _attachmentName;
  bool _isUploading = false;
  late DateTime _dueDate;
  List<String> _selectedServices = [];

  static const List<String> _serviceOptions = [
    'POS',
    'POS Printer',
    'Waiter Station POS',
    'Kitchen Printer',
    'CCTV',
    'Quickbooks',
    'Internet',
    'Office Computer',
    'Office Printer',
    'Sound System',
    'POS Button',
    'POS Access',
    'Change Price',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _branchController = TextEditingController(text: widget.task?.branch ?? '');
    _descController =
        TextEditingController(text: widget.task?.description ?? '');
    _assigneeId = widget.task?.assigneeId;
    _assigneeName = widget.task?.assigneeName;
    _attachmentData = widget.task?.attachmentData;
    _attachmentName = widget.task?.attachmentName;
    _dueDate =
        widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedServices = widget.task?.services.toList() ?? [];
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _isUploading = true);

      File? file;
      Uint8List? bytes;
      if (result.files.single.path != null) {
        file = File(result.files.single.path!);
      } else if (result.files.single.bytes != null) {
        bytes = result.files.single.bytes;
      }

      final attachment = await context.read<TaskProvider>().processAttachment(
            file: file,
            bytes: bytes,
            filename: result.files.single.name,
          );

      if (attachment == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('File too large or processing failed (Max 800KB).')),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _attachmentData = attachment['data'];
        _attachmentName = attachment['name'];
        _isUploading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();

    if (widget.task == null) {
      final newTask = Task(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        branch: _branchController.text.trim(),
        dateRequested: DateTime.now(),
        assigneeId: (auth.isAdminRole || auth.isSecretary) ? _assigneeId : null,
        assigneeName: (auth.isAdminRole || auth.isSecretary) ? _assigneeName : null,
        creatorId: auth.currentUser!.id,
        creatorName: auth.currentUser!.name,
        status: (auth.isAdminRole || auth.isSecretary) ? TaskStatus.todo : TaskStatus.awaitingApproval,
        priority: TaskPriority.medium,
        dueDate: _dueDate,
        services: _selectedServices,
        attachmentData: _attachmentData,
        attachmentName: _attachmentName,
      );
      taskProvider.addTask(newTask);
    } else {
      taskProvider.updateTask(widget.task!.id, {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'branch': _branchController.text.trim(),
        'assigneeId': _assigneeId,
        'assigneeName': _assigneeName,
        'attachmentData': _attachmentData,
        'attachmentName': _attachmentName,
        'dueDate': _dueDate.toIso8601String(),
        'services': _selectedServices,
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final members = auth.teamMembers;

    return AlertDialog(
      title: Text(widget.task == null ? 'Task Request' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: _branchController,
                decoration: const InputDecoration(labelText: 'Branch')),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Services Required'),
              child: Column(
                children: _serviceOptions.map((service) {
                  return CheckboxListTile(
                    title: Text(service, style: const TextStyle(fontSize: 14)),
                    value: _selectedServices.contains(service),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),
            TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
              ),
            ),
            const SizedBox(height: 16),
            // Attachment Section
            if (_attachmentData != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_attachmentName ?? 'File',
                          style: const TextStyle(fontSize: 12))),
                  IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() {
                            _attachmentData = null;
                            _attachmentName = null;
                          })),
                ]),
              )
            else
              TextButton.icon(
                onPressed: _isUploading ? null : _pickFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_link),
                label: Text(_isUploading ? 'Uploading...' : 'Add Attachment'),
              ),

            if (auth.isAdminRole) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _assigneeId,
                hint: const Text('Assign to...'),
                items: members
                    .map((m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _assigneeId = v;
                    _assigneeName = members.firstWhere((m) => m.id == v).name;
                  });
                },
              ),
            ] else if (auth.isSecretary) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _assigneeId,
                hint: const Text('Assign to IT...'),
                items: members
                    .where((m) => m.role == 'IT')
                    .map((m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _assigneeId = v;
                    _assigneeName = members.firstWhere((m) => m.id == v).name;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: _isUploading ? null : _submit,
            child: const Text('Submit')),
      ],
    );
  }
}
