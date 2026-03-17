import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';
import '../../widgets/responsive_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return ResponsiveScaffold(
      title: 'Notifications',
      currentRoute: '/notifications',
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (!isMobile) const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              if (notifProvider.unreadCount > 0) ...[
                if (!isMobile) const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12)),
                  child: Text('${notifProvider.unreadCount} unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              if (notifProvider.unreadCount > 0)
                TextButton.icon(
                  onPressed: notifProvider.markAllAsRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark all as read'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                ),
            ]),
            const SizedBox(height: 24),
            if (notifications.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF334155)),
                      SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) => _NotificationTile(notification: notifications[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.task: return Icons.task_alt;
      case NotificationType.message: return Icons.chat_bubble_outline;
      case NotificationType.event: return Icons.event;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.task: return const Color(0xFF6366F1);
      case NotificationType.message: return const Color(0xFF10B981);
      case NotificationType.event: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NotificationProvider>().markAsRead(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? Colors.transparent : const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(notification.timestamp),
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
