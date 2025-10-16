import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ✅ Add this import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/supabase_constants.dart';
import 'core/themes/app_theme.dart';
import 'presentation/pages/dashboard/dashboard_page.dart';
import 'injection_container.dart' as di;

// ✅ Add these imports for BLoCs
import 'presentation/blocs/inventory/inventory_bloc.dart';
import 'presentation/blocs/category/category_bloc.dart';
import 'presentation/blocs/order/order_bloc.dart';
import 'presentation/blocs/order/order_event.dart';

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
    // ✅ CRITICAL FIX: Move MultiBlocProvider to the root level
    return MultiBlocProvider(
      providers: [
        // ✅ App-wide BLoC providers at the root level
        BlocProvider(
          create: (context) => di.getIt<InventoryBloc>()..add(LoadInventoryItems()),
        ),
        BlocProvider(
          create: (context) => di.getIt<CategoryBloc>()..add(LoadCategories()),
        ),
        BlocProvider(
          create: (context) => di.getIt<OrderBloc>()..add(LoadOrders()),
        ),
      ],
      child: MaterialApp(
        title: 'Inventory Management System',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: DashboardPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
