import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../models/task.dart';
import '../../widgets/responsive_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final notifs = context.watch<NotificationProvider>();
    final chat = context.watch<ChatProvider>();
    final calendar = context.watch<CalendarProvider>();
    final user = auth.currentUser;

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return ResponsiveScaffold(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning, ${user?.name.split(' ').first ?? 'there'} 👋', 
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.bold))
              .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
            const SizedBox(height: 4),
            Text("Here's what's happening with your team today.", 
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14))
              .animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 24),
            
            // Overview of Tasks (Stats)
            _buildStatsGrid(context, tasks, notifs, isMobile),
            
            const SizedBox(height: 32),
            
            // Main Dashboard Content
            if (isMobile) ...[
               _UpcomingEvents(events: calendar.getEventsForDay(DateTime.now()).take(3).toList())
                .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
               const SizedBox(height: 24),
               _RecentMessages(messages: chat.messages.reversed.take(3).toList())
                .animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
               const SizedBox(height: 24),
               _RecentTasks(tasks: tasks.tasks.take(5).toList())
                .animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
            ] else 
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _RecentTasks(tasks: tasks.tasks.take(5).toList())
                          .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _RecentMessages(messages: chat.messages.reversed.take(5).toList())
                          .animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _UpcomingEvents(events: calendar.getEventsForDay(DateTime.now()).take(5).toList())
                          .animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _NotificationSummary(notifications: notifs.notifications.take(5).toList())
                          .animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, TaskProvider tasks, NotificationProvider notifs, bool isMobile) {
    final List<Widget> stats = [
      _StatCard(label: 'Total Tasks', value: '${tasks.tasks.length}', icon: Icons.task_alt, color: const Color(0xFF6366F1), delay: 100),
      _StatCard(label: 'In Progress', value: '${tasks.inProgressTasks.length}', icon: Icons.pending_actions, color: const Color(0xFFF59E0B), delay: 200),
      _StatCard(label: 'Completed', value: '${tasks.doneTasks.length}', icon: Icons.check_circle_outline, color: const Color(0xFF10B981), delay: 300),
      _StatCard(label: 'Unread', value: '${notifs.unreadCount}', icon: Icons.notifications_active_outlined, color: const Color(0xFFEF4444), delay: 400),
    ];

    if (isMobile) {
      return Column(children: [
        Row(children: [stats[0], const SizedBox(width: 12), stats[1]]),
        const SizedBox(height: 12),
        Row(children: [stats[2], const SizedBox(width: 12), stats[3]]),
      ]);
    }
    return Row(children: stats.map((s) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: s))).toList());
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 11, letterSpacing: 0.5)),
        ]),
      ]),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _RecentTasks extends StatelessWidget {
  final List<dynamic> tasks;
  const _RecentTasks({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Tasks',
      icon: Icons.assignment_rounded,
      child: Column(
        children: tasks.isEmpty 
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No recent tasks')))]
          : tasks.asMap().entries.map((entry) => _TaskRow(task: entry.value)
              .animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: 0.05)).toList(),
      ),
    );
  }
}

class _RecentMessages extends StatelessWidget {
  final List<dynamic> messages;
  const _RecentMessages({required this.messages});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Messages',
      icon: Icons.chat_bubble_rounded,
      child: Column(
        children: messages.isEmpty
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No messages')))]
          : messages.asMap().entries.map((entry) {
              final m = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 16, backgroundColor: const Color(0xFF6366F1), child: Text(m.senderName[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                title: Text(m.senderName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(m.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: Text(DateFormat('h:mm a').format(m.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ).animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: 0.05);
            }).toList(),
      ),
    );
  }
}

class _UpcomingEvents extends StatelessWidget {
  final List<dynamic> events;
  const _UpcomingEvents({required this.events});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Upcoming Events',
      icon: Icons.calendar_today_rounded,
      child: Column(
        children: events.isEmpty
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No events today')))]
          : events.asMap().entries.map((entry) {
              final e = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(width: 4, height: 28, decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text(DateFormat('h:mm a').format(e.date), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                ]),
              ).animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: 0.05);
            }).toList(),
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  final List<dynamic> notifications;
  const _NotificationSummary({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      child: Column(
        children: notifications.isEmpty
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('All caught up!')))]
          : notifications.asMap().entries.map((entry) {
              final n = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Icon(Icons.circle, size: 8, color: n.isRead ? Colors.transparent : const Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(n.title, style: TextStyle(fontSize: 12, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ).animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: 0.05);
            }).toList(),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final dynamic task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(width: 4, height: 36, decoration: BoxDecoration(color: _getPriorityColor(task.priority), borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(task.assigneeName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ])),
        _StatusBadge(status: task.status),
      ]),
    );
  }

  Color _getPriorityColor(dynamic p) {
    if (p == TaskPriority.high) return const Color(0xFFEF4444);
    if (p == TaskPriority.medium) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}

class _StatusBadge extends StatelessWidget {
  final dynamic status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String label = 'To Do';
    if (status == TaskStatus.done) { color = const Color(0xFF10B981); label = 'Done'; }
    else if (status == TaskStatus.inProgress) { color = const Color(0xFFF59E0B); label = 'In Progress'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}
