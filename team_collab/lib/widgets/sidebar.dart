import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final bool isDrawer;

  const Sidebar({super.key, required this.currentRoute, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notifCount = context.watch<NotificationProvider>().unreadCount;
    final user = auth.currentUser;

    final content = Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.group, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text('TeamCollab', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ),
        const Divider(color: Color(0xFF334155), height: 1),
        const SizedBox(height: 12),
        _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard', currentRoute: currentRoute),
        _NavItem(icon: Icons.chat_bubble_outline, label: 'Chat', route: '/chat', currentRoute: currentRoute),
        _NavItem(icon: Icons.task_alt_outlined, label: 'Tasks', route: '/tasks', currentRoute: currentRoute),
        _NavItem(icon: Icons.calendar_month_outlined, label: 'Calendar', route: '/calendar', currentRoute: currentRoute),
        Stack(
          children: [
            _NavItem(icon: Icons.notifications_outlined, label: 'Notifications', route: '/notifications', currentRoute: currentRoute),
            if (notifCount > 0)
              Positioned(
                right: 20, top: 12,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Text('$notifCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        _NavItem(icon: Icons.person_outline, label: 'Profile', route: '/profile', currentRoute: currentRoute),
        
        const Spacer(),
        
        // Theme Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 20,
                  color: themeProvider.isDarkMode ? Colors.indigoAccent : Colors.orange,
                ),
                const Text('Dark Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeColor: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        ),

        const Divider(color: Color(0xFF334155), height: 1),
        if (user != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: CircleAvatar(
                  radius: 18, 
                  backgroundColor: const Color(0xFF6366F1), 
                  child: Text(user.avatarInitials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(user.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), overflow: TextOverflow.ellipsis),
              ])),
              IconButton(icon: const Icon(Icons.logout, color: Color(0xFF64748B), size: 20), onPressed: () { auth.logout(); context.go('/login'); }, tooltip: 'Logout'),
            ]),
          ),
      ],
    );

    if (isDrawer) {
      return Drawer(
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(child: content),
      );
    }

    return Container(
      width: 240,
      color: const Color(0xFF1E293B),
      child: content,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _NavItem({required this.icon, required this.label, required this.route, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;
    return InkWell(
      onTap: () {
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
        context.go(route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B), size: 22),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: isActive ? const Color(0xFF6366F1) : const Color(0xFF94A3B8), fontSize: 15, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}
