import 'package:flutter/material.dart';
import 'sidebar.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String currentRoute;
  final String title;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    required this.title,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: isMobile
          ? AppBar(
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF1E293B),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: isMobile ? Sidebar(currentRoute: currentRoute, isDrawer: true) : null,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (!isMobile) Sidebar(currentRoute: currentRoute),
          Expanded(child: body),
        ],
      ),
    );
  }
}
