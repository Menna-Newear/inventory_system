// ✅ presentation/blocs/theme/theme_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class ThemeInitial extends ThemeState {
  const ThemeInitial() : super(ThemeMode.system);
}

class ThemeLoading extends ThemeState {
  const ThemeLoading(ThemeMode themeMode) : super(themeMode);
}

class ThemeLoaded extends ThemeState {
  final bool isDarkMode;

  const ThemeLoaded({
    required ThemeMode themeMode,
    required this.isDarkMode,
  }) : super(themeMode);

  @override
  List<Object> get props => [themeMode, isDarkMode];
}

class ThemeError extends ThemeState {
  final String message;

  const ThemeError(
      ThemeMode themeMode, {
        required this.message,
      }) : super(themeMode);

  @override
  List<Object> get props => [themeMode, message];
}
