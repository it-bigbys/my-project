import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            Image.asset(
              'images/logo.png',
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.group, 
                size: 80, 
                color: theme.primaryColor
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1500.ms, color: theme.colorScheme.secondary.withValues(alpha: 0.3))
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),
            
            const SizedBox(height: 40),
            
            // Loading Text
            Text(
              'Synchronizing Workspace...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: 1.2,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 800.ms)
            .then()
            .fadeOut(delay: 500.ms, duration: 800.ms),
            
            const SizedBox(height: 20),
            
            // Modern Linear Progress
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                color: theme.primaryColor,
                minHeight: 2,
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
