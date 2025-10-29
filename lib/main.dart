// ✅ main.dart (WITH LOCALIZATION & THEME SWITCHING!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_system/presentation/blocs/auth/auth_bloc.dart';
import 'package:inventory_system/presentation/blocs/auth/auth_event.dart';
import 'package:inventory_system/presentation/blocs/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:window_manager/window_manager.dart';

import 'core/constants/supabase_constants.dart';
import 'core/themes/app_theme.dart';
import 'presentation/pages/dashboard/dashboard_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'injection_container.dart' as di;

// BLoC imports
import 'presentation/blocs/inventory/inventory_bloc.dart';
import 'presentation/blocs/category/category_bloc.dart';
import 'presentation/blocs/order/order_bloc.dart';
import 'presentation/blocs/order/order_event.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

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

  runApp(
    // ✅ Wrap app with EasyLocalization
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      startLocale: Locale('en'),
      child: InventoryManagementApp(),
    ),
  );
}

// ✅ Changed to StatefulWidget to support dynamic theme switching
class InventoryManagementApp extends StatefulWidget {
  const InventoryManagementApp({super.key});

  // ✅ Static method to access state from anywhere
  static _InventoryManagementAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_InventoryManagementAppState>();

  @override
  State<InventoryManagementApp> createState() => _InventoryManagementAppState();
}

class _InventoryManagementAppState extends State<InventoryManagementApp> {
  // ✅ Theme state
  ThemeMode _themeMode = ThemeMode.system;

  // ✅ Method to change theme from anywhere in the app
  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // ✅ Provide ALL BLoCs globally at the root
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.getIt<AuthBloc>()..add(AppStarted()),
        ),
        BlocProvider<InventoryBloc>(
          create: (context) => di.getIt<InventoryBloc>(),
          lazy: false,
        ),
        BlocProvider<CategoryBloc>(
          create: (context) => di.getIt<CategoryBloc>(),
          lazy: false,
        ),
        BlocProvider<OrderBloc>(
          create: (context) => di.getIt<OrderBloc>(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        // ✅ Add localization delegates from EasyLocalization
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,

        title: 'app_title'.tr(), // ✅ Translated title
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode, // ✅ Use dynamic theme mode
        debugShowCheckedModeBanner: false,
        home: AuthGate(),
      ),
    );
  }
}

// ✅ Auth Gate - Routes based on authentication state
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading splash screen
        if (state is AuthLoading || state is AuthInitial) {
          return _buildLoadingScreen(context);
        }

        // User is authenticated - load data and show dashboard
        if (state is Authenticated) {
          // ✅ Load data when authenticated
          context.read<InventoryBloc>().add(LoadInventoryItems());
          context.read<CategoryBloc>().add(LoadCategories());
          context.read<OrderBloc>().add(LoadOrders());

          return DashboardPage();
        }

        // User is not authenticated - show login page
        return LoginPage();
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: 64,
                  color: Color(0xFF2196F3),
                ),
              ),
              SizedBox(height: 32),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),

              // ✅ Translated loading text
              Text(
                'common.loading'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
