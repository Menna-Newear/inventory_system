// ✅ main.dart (WITH THEME BLOC!)
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
import 'presentation/blocs/theme/theme_bloc.dart';
import 'presentation/blocs/theme/theme_event.dart';
import 'presentation/blocs/theme/theme_state.dart';
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
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const InventoryManagementApp(),
    ),
  );
}

class InventoryManagementApp extends StatelessWidget {
  const InventoryManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => di.getIt<ThemeBloc>()..add(const LoadTheme()),
        ),
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
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,

            title: 'app.title'.tr(),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _dataLoaded = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated && !_dataLoaded) {
          _loadInitialData(context);
          setState(() => _dataLoaded = true);
          debugPrint('✅ User authenticated, loading initial data');
        }

        if (state is! Authenticated) {
          setState(() => _dataLoaded = false);
          debugPrint('🔄 User logged out, resetting data');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading || state is AuthInitial) {
            debugPrint('⏳ Showing loading screen');
            return _buildLoadingScreen(context);
          }

          if (state is Authenticated) {
            debugPrint('🏠 Showing dashboard');
            return  DashboardPage();
          }

          debugPrint('🔐 Showing login page');
          return  LoginPage();
        },
      ),
    );
  }

  void _loadInitialData(BuildContext context) {
    try {
      context.read<InventoryBloc>().add(LoadInventoryItems());
      context.read<CategoryBloc>().add(LoadCategories());
      context.read<OrderBloc>().add(LoadOrders());

      debugPrint('✅ Initial data loading triggered');
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
    }
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF1a1a1a),
              const Color(0xFF2d2d2d),
              const Color(0xFF1a1a1a),
            ]
                : [
              const Color(0xFF2196F3),
              const Color(0xFF1976D2),
              const Color(0xFF0D47A1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedLogo(isDark),
              SizedBox(height: 40),
              _buildLoadingIndicator(theme),
              SizedBox(height: 28),
              Text(
                'splash.loading_app'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'splash.please_wait'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'splash.initializing_services'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.inventory_2,
          size: 72,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 3,
              ),
            ),
          ),
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.primaryColor.withOpacity(0.8),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
