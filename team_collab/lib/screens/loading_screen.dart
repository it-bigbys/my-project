import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate initial data fetch / sync delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo with Shimmer
            Image.asset(
              'images/logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.group, 
                size: 80, 
                color: theme.primaryColor
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1500.ms, color: theme.colorScheme.secondary.withValues(alpha: 0.3))
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),
            
            const SizedBox(height: 48),
            
            // Pulsing Status Text
            Text(
              'Initializing Workspace...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: 2.0,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(duration: 800.ms),
            
            const SizedBox(height: 24),
            
            // Sleek Linear Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 180,
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                  color: theme.primaryColor,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
