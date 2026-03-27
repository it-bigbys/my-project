import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../models/task.dart';
import '../../models/notification.dart';
import '../../widgets/responsive_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final notifs = context.watch<NotificationProvider>();
    final calendar = context.watch<CalendarProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    // Filter data based on role
    final isSuperAdmin = auth.currentUser?.role == 'Super Admin';
    final isAdmin = auth.currentUser?.role == 'Admin';
    final isGOM = auth.isGOM;
    final isSecretary = auth.currentUser?.role == 'Secretary';
    final isIT = auth.currentUser?.role == 'IT';
    final userId = user?.id;

    List<Task> allTasks;
    if (isSuperAdmin || isAdmin || isGOM) {
      allTasks = taskProvider.visibleTasks;
    } else if (isSecretary) {
      allTasks = taskProvider.visibleTasks.where((t) => t.status != TaskStatus.awaitingApproval).toList();
    } else if (isIT) {
      allTasks = taskProvider.visibleTasks.where((t) => t.assigneeId == userId).toList();
    } else {
      // Branch and other regular users: see only created tasks
      allTasks = taskProvider.visibleTasks.where((t) => t.creatorId == userId).toList();
    }

    final myTasks = allTasks;

    final todoCount = myTasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgressCount = myTasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completedCount = myTasks.where((t) => t.status == TaskStatus.done).length;
    final pendingCount = myTasks.where((t) => t.status == TaskStatus.pending).length;

    final awaitingApprovalCount = (isSuperAdmin || isAdmin || isGOM) ? taskProvider.awaitingApprovalTasks.length : 0;

    final myEvents = auth.isAdmin 
        ? calendar.getEventsForDay(DateTime.now())
        : calendar.getEventsForDay(DateTime.now()).where((e) => e.creatorId == user?.id || e.taggedUserIds.contains(user?.id)).toList();

    // Trigger daily reminders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        context.read<NotificationProvider>().checkUpcomingReminders(taskProvider.tasks, calendar.allEvents, user.id);
      }
    });

    final ImageProvider<Object>? dashboardUserImage;
    final String? userPhotoUrl = user?.photoUrl;
    if (user?.photoLocalPath != null && !kIsWeb && File(user!.photoLocalPath!).existsSync()) {
      dashboardUserImage = FileImage(File(user.photoLocalPath!));
    } else if (userPhotoUrl != null && userPhotoUrl.isNotEmpty) {
      dashboardUserImage = NetworkImage(userPhotoUrl);
    } else {
      dashboardUserImage = null;
    }

    return ResponsiveScaffold(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (dashboardUserImage != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: dashboardUserImage,
                  ).animate().fadeIn(duration: 600.ms).scale(),
                if (user?.photoLocalPath != null || user?.photoUrl != null) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning, ${user?.name.split(' ').first ?? 'there'} 👋', 
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.bold))
                        .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                      const SizedBox(height: 4),
                      Text(_getGreetingSubtitle(auth), 
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14))
                        .animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildStatsGrid(context, myTasks.length, inProgressCount, completedCount, notifs.unreadCount, awaitingApprovalCount, isMobile, auth),
            
            const SizedBox(height: 32),
            
            if (isMobile) ...[
               _TaskPieChart(todo: todoCount, inProgress: inProgressCount, done: completedCount, pending: pendingCount)
                .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
               const SizedBox(height: 24),
               _RequestChart(tasks: myTasks).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
               const SizedBox(height: 24),
               _UpcomingEvents(
                 events: myEvents.take(3).toList(),
                 onTap: () => context.go('/calendar'),
               ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
            ] else 
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _TaskPieChart(todo: todoCount, inProgress: inProgressCount, done: completedCount, pending: pendingCount)),
                            const SizedBox(width: 24),
                            Expanded(child: _RequestChart(tasks: myTasks)),
                          ],
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _RecentTasks(
                          tasks: myTasks.take(5).toList(),
                          onTap: () => context.go('/tasks'),
                          auth: auth,
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _UpcomingEvents(
                          events: myEvents.take(5).toList(),
                          onTap: () => context.go('/calendar'),
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _NotificationSummary(
                          notifications: notifs.notifications.take(5).toList(),
                        ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
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

  Widget _buildStatsGrid(BuildContext context, int total, int inProgress, int completed, int unread, int awaitingApproval, bool isMobile, AuthProvider auth) {
    final isSuperAdmin = auth.currentUser?.role == 'Super Admin';
    final isAdmin = auth.currentUser?.role == 'Admin';
    final isIT = auth.currentUser?.role == 'IT';
    final isSecretary = auth.currentUser?.role == 'Secretary';
    final isBranch = auth.currentUser?.role == 'Branch';

    // Determine the label for the total tasks count
    String totalTasksLabel;
    if (isSuperAdmin || isAdmin || isIT || isSecretary) {
      totalTasksLabel = 'Total Request';
    } else if (isBranch) {
      totalTasksLabel = 'My Request';
    } else {
      totalTasksLabel = 'My Tasks';
    }

    final List<Widget> stats = [
      _StatCard(label: totalTasksLabel, value: '$total', icon: Icons.task_alt, color: Theme.of(context).primaryColor, delay: 100, onTap: () => context.go('/tasks')),
      _StatCard(label: 'In Progress', value: '$inProgress', icon: Icons.pending_actions, color: const Color(0xFFFFD700), delay: 200, onTap: () => context.go('/tasks')),
      _StatCard(label: 'Completed', value: '$completed', icon: Icons.check_circle_outline, color: const Color(0xFF10B981), delay: 300, onTap: () => context.go('/tasks')),
      if (awaitingApproval > 0) _StatCard(label: 'Awaiting Approval', value: '$awaitingApproval', icon: Icons.hourglass_top, color: const Color(0xFFFF6B35), delay: 350, onTap: () => context.go('/tasks')),
      _StatCard(label: 'Unread', value: '$unread', icon: Icons.notifications_active_outlined, color: const Color(0xFF1E3A8A), delay: 400, onTap: () {}),
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

  String _getGreetingSubtitle(AuthProvider auth) {
    final isSuperAdmin = auth.currentUser?.role == 'Super Admin';
    final isAdmin = auth.currentUser?.role == 'Admin';
    final isIT = auth.currentUser?.role == 'IT';
    final isSecretary = auth.currentUser?.role == 'Secretary';
    final isBranch = auth.currentUser?.role == 'Branch';

    if (isSuperAdmin || isAdmin || isIT || isSecretary) {
      return "Here's the total requests overview today.";
    } else if (isBranch) {
      return "Here's your requests overview today.";
    } else {
      return "Here's your personal overview today.";
    }
  }
}

class _TaskPieChart extends StatelessWidget {
  final int todo, inProgress, done, pending;
  const _TaskPieChart({required this.todo, required this.inProgress, required this.done, required this.pending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = todo + inProgress + done + pending;

    return _DashboardCard(
      title: 'Task Distribution',
      icon: Icons.pie_chart_rounded,
      onTap: () => context.go('/tasks'),
      child: total == 0 
        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No task data')))
        : Column(
            children: [
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(value: todo.toDouble(), color: const Color(0xFF64748B), title: '', radius: 40),
                      PieChartSectionData(value: inProgress.toDouble(), color: const Color(0xFFFFD700), title: '', radius: 40),
                      PieChartSectionData(value: done.toDouble(), color: const Color(0xFF10B981), title: '', radius: 40),
                      PieChartSectionData(value: pending.toDouble(), color: Colors.purple, title: '', radius: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _LegendItem(color: const Color(0xFF64748B), label: 'To Do', value: todo),
                  _LegendItem(color: const Color(0xFFFFD700), label: 'In Progress', value: inProgress),
                  _LegendItem(color: const Color(0xFF10B981), label: 'Done', value: done),
                  _LegendItem(color: Colors.purple, label: 'Pending', value: pending),
                ],
              ),
            ],
          ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Text('$value', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _RequestChart extends StatelessWidget {
  final List<Task> tasks;
  const _RequestChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    Map<int, int> monthlyCounts = {for (var i = 1; i <= 12; i++) i: 0};
    
    for (var task in tasks) {
      if (task.dueDate.year == now.year) {
        monthlyCounts[task.dueDate.month] = (monthlyCounts[task.dueDate.month] ?? 0) + 1;
      }
    }

    final List<FlSpot> spots = monthlyCounts.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return _DashboardCard(
      title: 'Requests Over Time',
      icon: Icons.show_chart_rounded,
      onTap: () {},
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.only(top: 20, right: 20),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      if (value < 1 || value > 12) return const Text('');
                      return Text(months[value.toInt() - 1], style: const TextStyle(color: Colors.grey, fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
            Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11, letterSpacing: 0.5)),
          ]),
        ]),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _RecentTasks extends StatelessWidget {
  final List<dynamic> tasks;
  final VoidCallback onTap;
  final AuthProvider auth;
  const _RecentTasks({required this.tasks, required this.onTap, required this.auth});

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = auth.currentUser?.role == 'Super Admin';
    final isAdmin = auth.currentUser?.role == 'Admin';
    final isIT = auth.currentUser?.role == 'IT';
    final isSecretary = auth.currentUser?.role == 'Secretary';
    final isBranch = auth.currentUser?.role == 'Branch';

    // Determine the title based on role
    String title;
    if (isSuperAdmin || isAdmin || isIT || isSecretary) {
      title = 'Recent Request';
    } else if (isBranch) {
      title = 'Recent Request';
    } else {
      title = 'Recent Tasks';
    }

    return _DashboardCard(
      title: title,
      icon: Icons.assignment_rounded,
      onTap: onTap,
      child: Column(
        children: tasks.isEmpty
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No tasks to show')))]
          : tasks.asMap().entries.map((entry) => _TaskRow(task: entry.value)
              .animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: 0.05)).toList(),
      ),
    );
  }
}

class _UpcomingEvents extends StatelessWidget {
  final List<dynamic> events;
  final VoidCallback onTap;
  const _UpcomingEvents({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Upcoming Events',
      icon: Icons.calendar_today_rounded,
      onTap: onTap,
      child: Column(
        children: events.isEmpty
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No upcoming events')))]
          : events.asMap().entries.map((entry) {
              final e = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(width: 4, height: 28, decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(4))),
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
  final List<AppNotification> notifications;
  const _NotificationSummary({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.read<NotificationProvider>();
    
    return _DashboardCard(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      onTap: () {}, // No longer navigates to separate screen
      child: Column(
        children: notifications.isEmpty
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('All caught up!')))]
          : notifications.asMap().entries.map((entry) {
              final n = entry.value;
              return GestureDetector(
                onTap: () => _showNotificationDetails(context, n, notifProvider),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: n.isRead ? Colors.transparent : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(children: [
                    Icon(Icons.circle, size: 8, color: n.isRead ? Colors.transparent : Theme.of(context).primaryColor),
                    const SizedBox(width: 10),
                    Expanded(child: Text(n.title, style: TextStyle(fontSize: 12, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(DateFormat('h:mm a').format(n.timestamp), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
                  ]),
                ),
              ).animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: 0.05);
            }).toList(),
      ),
    );
  }

  void _showNotificationDetails(BuildContext context, AppNotification notification, NotificationProvider provider) {
    // Mark as read when viewed
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    IconData icon;
    Color iconColor;
    switch (notification.type) {
      case NotificationType.task:
        icon = Icons.task_alt;
        iconColor = const Color(0xFF6366F1);
        break;
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        iconColor = const Color(0xFF10B981);
        break;
      case NotificationType.event:
        icon = Icons.event;
        iconColor = const Color(0xFFF59E0B);
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 16),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(notification.timestamp),
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.icon, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
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
                decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ]),
            const SizedBox(height: 20),
            child,
          ],
        ),
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
          Text(task.assigneeName ?? 'Unassigned', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ])),
        _StatusBadge(status: task.status),
      ]),
    );
  }

  Color _getPriorityColor(dynamic p) {
    if (p == TaskPriority.high) return const Color(0xFFEF4444);
    if (p == TaskPriority.medium) return const Color(0xFFFFD700);
    return const Color(0xFF10B981);
  }
}

class _StatusBadge extends StatelessWidget {
  final dynamic status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color = Colors.grey;
    String label = 'To Do';
    if (status == TaskStatus.done) { color = const Color(0xFF10B981); label = 'Done'; }
    else if (status == TaskStatus.inProgress) { color = const Color(0xFFFFD700); label = 'In Progress'; }
    else if (status == TaskStatus.pending) { color = Colors.purple; label = 'Pending'; }
    else if (status == TaskStatus.awaitingApproval) { color = const Color(0xFFFF6B35); label = 'Awaiting Approval'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}
