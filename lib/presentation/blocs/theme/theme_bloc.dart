// ✅ presentation/blocs/theme/theme_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'app_theme_mode';

  ThemeBloc() : super(const ThemeInitial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
    on<ToggleTheme>(_onToggleTheme);
    on<SetSystemTheme>(_onSetSystemTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      emit(ThemeLoading(state.themeMode));

      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey) ?? 'system';

      final themeMode = _parseThemeMode(themeModeString);
      final isDarkMode = themeMode == ThemeMode.dark;

      emit(ThemeLoaded(
        themeMode: themeMode,
        isDarkMode: isDarkMode,
      ));

      debugPrint('✅ Theme loaded: $themeModeString');
    } catch (e) {
      debugPrint('❌ Error loading theme: $e');
      emit(ThemeError(
        state.themeMode,
        message: 'Failed to load theme: $e',
      ));
    }
  }

  Future<void> _onChangeTheme(
      ChangeTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      emit(ThemeLoading(event.themeMode));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeToString(event.themeMode));

      final isDarkMode = event.themeMode == ThemeMode.dark;

      emit(ThemeLoaded(
        themeMode: event.themeMode,
        isDarkMode: isDarkMode,
      ));

      debugPrint('🎨 Theme changed to: ${event.themeMode.toString()}');
    } catch (e) {
      debugPrint('❌ Error changing theme: $e');
      emit(ThemeError(
        event.themeMode,
        message: 'Failed to change theme: $e',
      ));
    }
  }

  Future<void> _onToggleTheme(
      ToggleTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      final currentTheme = state.themeMode;
      final newTheme = currentTheme == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;

      add(ChangeTheme(newTheme));
      debugPrint('🔄 Theme toggled to: ${newTheme.toString()}');
    } catch (e) {
      debugPrint('❌ Error toggling theme: $e');
      emit(ThemeError(
        state.themeMode,
        message: 'Failed to toggle theme: $e',
      ));
    }
  }

  Future<void> _onSetSystemTheme(
      SetSystemTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      emit(ThemeLoading(state.themeMode));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, 'system');

      emit(ThemeLoaded(
        themeMode: ThemeMode.system,
        isDarkMode: false,
      ));

      debugPrint('🎨 Theme set to system preference');
    } catch (e) {
      debugPrint('❌ Error setting system theme: $e');
      emit(ThemeError(
        state.themeMode,
        message: 'Failed to set system theme: $e',
      ));
    }
  }

  ThemeMode _parseThemeMode(String themeModeString) {
    switch (themeModeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode themeMode) {
    return themeMode.toString().split('.').last;
  }
}
