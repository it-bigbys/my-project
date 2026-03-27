import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/task_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/theme_provider.dart';
import 'services/local_storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clean the URL by removing the '#' (hash) from the web address
  usePathUrlStrategy();
  
  // Initialize Firebase with the generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Shared instance
  final localStorageService = LocalStorageService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: localStorageService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            localStorageService: context.read<LocalStorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(
            localStorageService: context.read<LocalStorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(
            localStorageService: context.read<LocalStorageService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: const TeamCollabApp(),
    ),
  );
}
