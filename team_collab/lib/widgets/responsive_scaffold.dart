import 'package:flutter/material.dart';
import 'sidebar.dart';

enum DeviceType { mobile, tablet, desktop }

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

  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return DeviceType.mobile;
    if (width < 1100) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(context);
    final theme = Theme.of(context);
    final bool isMobile = deviceType == DeviceType.mobile;
    final bool isTablet = deviceType == DeviceType.tablet;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isMobile || isTablet
          ? AppBar(
              title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              centerTitle: isMobile,
            )
          : null,
      drawer: isMobile || isTablet ? Sidebar(currentRoute: currentRoute, isDrawer: true) : null,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          // Sidebar is only permanent on Desktop
          if (deviceType == DeviceType.desktop) 
            Sidebar(currentRoute: currentRoute),
          
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
