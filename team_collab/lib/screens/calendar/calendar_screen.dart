import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/event.dart';
import '../../models/task.dart';
import '../../models/notification.dart';
import '../../widgets/responsive_scaffold.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final calProvider = context.watch<CalendarProvider>();
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;
    final bool isTablet = screenWidth >= 800 && screenWidth < 1200;
    final bool isDesktop = screenWidth >= 1200;
    
    final selectedItems = calProvider.getFilteredItemsForDay(
      _selectedDay ?? _focusedDay, 
      auth.currentUser?.id ?? '', 
      auth.isSuperAdmin
    );

    final calendarWidget = Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 600 : double.infinity,
        maxHeight: isMobile ? 400 : 500,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _isMonthView ? CalendarFormat.month : CalendarFormat.week,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => calProvider.getFilteredItemsForDay(day, auth.currentUser?.id ?? '', auth.isSuperAdmin),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: isMobile ? 12 : 14),
          weekendTextStyle: const TextStyle(color: Colors.redAccent),
          selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
          cellMargin: EdgeInsets.all(isMobile ? 2 : 4),
          cellPadding: EdgeInsets.all(isMobile ? 2 : 4),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: isMobile ? 16 : 17, fontWeight: FontWeight.bold),
          headerPadding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: 16),
        ),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onFormatChanged: (format) => setState(() => _isMonthView = format == CalendarFormat.month),
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
      ),
    );

    final eventListWidget = Container(
      constraints: BoxConstraints(
        maxHeight: isMobile ? double.infinity : MediaQuery.of(context).size.height - 200,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                _selectedDay != null ? DateFormat('MMMM d, yyyy').format(_selectedDay!) : 'Select a day',
                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddEventDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(isMobile ? '' : 'Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor, 
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Expanded(
            child: selectedItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(children: [
                      Icon(Icons.event_available_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('No events or tasks for this day', style: TextStyle(color: Colors.grey)),
                    ]),
                  ),
                )
              : ListView.builder(
                  itemCount: selectedItems.length,
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    return item is CalendarEvent 
                      ? _EventCard(
                          event: item, 
                          onTap: () => _showEditDeleteDialog(context, item),
                          isCompact: isMobile,
                        ).animate().fadeIn().slideX(begin: 0.1)
                      : _TaskCard(
                          task: item as Task,
                          onTap: () => _showTaskDialog(context, item),
                          isCompact: isMobile,
                        ).animate().fadeIn().slideX(begin: 0.1);
                  },
                ),
          ),
        ],
      ),
    );

    return ResponsiveScaffold(
      title: 'Calendar',
      currentRoute: '/calendar',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: isMobile 
          ? Column(
              children: [
                calendarWidget,
                const SizedBox(height: 24),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: eventListWidget,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isTablet ? 2 : 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: calendarWidget,
                  ),
                ),
                Expanded(
                  flex: isTablet ? 2 : 2,
                  child: eventListWidget,
                ),
              ],
            ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => _AddEventDialog(selectedDay: _selectedDay ?? _focusedDay));
  }

  void _showEditDeleteDialog(BuildContext context, CalendarEvent event) {
    final auth = context.read<AuthProvider>();
    // Only creator or admin can edit/delete
    if (event.creatorId != auth.currentUser?.id && !auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only the creator or an admin can modify this event.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => _AddEventDialog(selectedDay: event.date, event: event));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CalendarEvent event) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event?', style: TextStyle(fontSize: isWideScreen ? 18 : 16)),
        content: SizedBox(
          width: isWideScreen ? 300 : double.maxFinite,
          child: Text(
            'Are you sure you want to delete "${event.title}"?',
            style: TextStyle(fontSize: isWideScreen ? 16 : 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
          ),
          TextButton(
            onPressed: () {
              context.read<CalendarProvider>().deleteEvent(event.id);
              Navigator.pop(context);
            }, 
            child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: isWideScreen ? 16 : 14)),
          ),
        ],
        actionsPadding: EdgeInsets.all(isWideScreen ? 24 : 16),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, Task task) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.task, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(task.title, style: TextStyle(fontSize: isWideScreen ? 18 : 16))),
        ]),
        content: SizedBox(
          width: isWideScreen ? 400 : double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) ...[
                Text(
                  task.description,
                  style: TextStyle(height: 1.4, fontSize: isWideScreen ? 16 : 14),
                ),
                const SizedBox(height: 16),
              ],
              Text('Creator: ${task.creatorName}', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
              if (task.assigneeName != null)
                Text('Assigned to: ${task.assigneeName}', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
              Text('Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
              Text('Status: ${task.status.name}', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
          ),
        ],
        actionsPadding: EdgeInsets.all(isWideScreen ? 24 : 16),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final bool isCompact;
  const _EventCard({required this.event, required this.onTap, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: theme.primaryColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isCompact ? 14 : 16)),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.description, 
              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: isCompact ? 12 : 13),
              maxLines: isCompact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _UserChip(name: event.createdBy, label: 'Creator'),
              ...List.generate(event.taggedUserNames.length, (index) => 
                _UserChip(name: event.taggedUserNames[index], label: 'Tagged', color: theme.colorScheme.secondary)
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Spacer(),
            Icon(Icons.access_time, size: 14, color: theme.primaryColor),
            const SizedBox(width: 6),
            Text(DateFormat('h:mm a').format(event.date), style: TextStyle(fontSize: isCompact ? 11 : 12, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final bool isCompact;
  const _TaskCard({required this.task, required this.onTap, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: Colors.orange, width: 4)), // Different color for tasks
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.task, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isCompact ? 14 : 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description, 
              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: isCompact ? 12 : 13),
              maxLines: isCompact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _UserChip(name: task.creatorName, label: 'Creator'),
              if (task.assigneeName != null)
                _UserChip(name: task.assigneeName!, label: 'Assigned', color: Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Spacer(),
            Icon(Icons.calendar_today, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Text(DateFormat('MMM dd').format(task.dueDate), style: TextStyle(fontSize: isCompact ? 11 : 12, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String name;
  final String label;
  final Color? color;
  const _UserChip({required this.name, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (color ?? Colors.grey).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: TextStyle(fontSize: 10, color: (color ?? Colors.grey), fontWeight: FontWeight.bold)),
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _AddEventDialog extends StatefulWidget {
  final DateTime selectedDay;
  final CalendarEvent? event;
  const _AddEventDialog({required this.selectedDay, this.event});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final _searchController = TextEditingController();
  late List<String> _selectedUserIds;
  late List<String> _selectedUserNames;
  String _searchQuery = '';
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descController = TextEditingController(text: widget.event?.description ?? '');
    _selectedUserIds = List.from(widget.event?.taggedUserIds ?? []);
    _selectedUserNames = List.from(widget.event?.taggedUserNames ?? []);
    _selectedTime = TimeOfDay.fromDateTime(widget.event?.date ?? DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    final calProvider = context.read<CalendarProvider>();

    final finalDate = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (widget.event == null) {
      final event = CalendarEvent(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: finalDate,
        creatorId: user.id,
        createdBy: user.name,
        taggedUserIds: _selectedUserIds,
        taggedUserNames: _selectedUserNames,
      );
      calProvider.addEvent(event);
    } else {
      calProvider.updateEvent(widget.event!.id, {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'date': finalDate.toIso8601String(),
        'taggedUserIds': _selectedUserIds,
        'taggedUserNames': _selectedUserNames,
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<AuthProvider>().teamMembers;
    final currentUser = context.read<AuthProvider>().currentUser;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    final filteredMembers = members.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final isNotMe = m.id != currentUser?.id;
      return matchesSearch && isNotMe;
    }).toList();

    return AlertDialog(
      title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      content: SizedBox(
        width: isWideScreen ? 500 : double.maxFinite,
        height: isWideScreen ? 600 : 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController, 
                decoration: const InputDecoration(labelText: 'Event Title'),
                style: TextStyle(fontSize: isWideScreen ? 16 : 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController, 
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                style: TextStyle(fontSize: isWideScreen ? 16 : 14),
              ),
              const SizedBox(height: 20),
              
              // Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Event Time', style: TextStyle(fontSize: isWideScreen ? 16 : 14, fontWeight: FontWeight.bold)),
                subtitle: Text(_selectedTime.format(context), style: TextStyle(fontSize: isWideScreen ? 14 : 12)),
                trailing: Icon(Icons.access_time, color: theme.primaryColor),
                onTap: _pickTime,
              ),
              
              const SizedBox(height: 20),
              Text('Tag Teammates', style: TextStyle(fontSize: isWideScreen ? 16 : 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search teammates...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isWideScreen ? 16 : 12),
                ),
                style: TextStyle(fontSize: isWideScreen ? 16 : 14),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: isWideScreen ? 200 : 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return CheckboxListTile(
                      title: Text(member.name, style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
                      value: _selectedUserIds.contains(member.id),
                      dense: !isWideScreen,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: isWideScreen ? 8 : 4),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedUserIds.add(member.id);
                            _selectedUserNames.add(member.name);
                          } else {
                            _selectedUserIds.remove(member.id);
                            _selectedUserNames.remove(member.name);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text('Cancel', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
        ),
        ElevatedButton(
          onPressed: _submit, 
          child: Text(widget.event == null ? 'Add Event' : 'Update', style: TextStyle(fontSize: isWideScreen ? 16 : 14)),
        ),
      ],
      actionsPadding: EdgeInsets.all(isWideScreen ? 24 : 16),
    );
  }
}
