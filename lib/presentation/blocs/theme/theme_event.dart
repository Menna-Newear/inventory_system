// ✅ presentation/blocs/theme/theme_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

/// Load theme preference from local storage
class LoadTheme extends ThemeEvent {
  const LoadTheme();
}

/// Change theme mode
class ChangeTheme extends ThemeEvent {
  final ThemeMode themeMode;

  const ChangeTheme(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

/// Toggle between light and dark theme
class ToggleTheme extends ThemeEvent {
  const ToggleTheme();
}

/// Set theme to system preference
class SetSystemTheme extends ThemeEvent {
  const SetSystemTheme();
}
