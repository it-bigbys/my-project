import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/loading_screen.dart';

class TeamCollabApp extends StatelessWidget {
  const TeamCollabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.read<AuthProvider>();
    
    return MaterialApp.router(
      title: 'TeamCollab',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      routerConfig: _router(context, authProvider),
    );
  }

  GoRouter _router(BuildContext context, AuthProvider auth) => GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      
      if (!isLoggedIn && !isLoginRoute) return '/login';
      
      // If logging in, send to loading screen first
      if (isLoggedIn && isLoginRoute) return '/loading';
      
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/loading', builder: (_, __) => const LoadingScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
      GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
    ],
  );
}
