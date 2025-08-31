// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/supabase_constants.dart';
import 'core/themes/app_theme.dart';
import 'presentation/pages/dashboard/dashboard_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // Setup dependency injection
  await di.init();

  // Configure desktop window
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Inventory Management System',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(InventoryManagementApp());
}

class InventoryManagementApp extends StatelessWidget {
  const InventoryManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}