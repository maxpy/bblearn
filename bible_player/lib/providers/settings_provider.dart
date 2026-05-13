import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the app theme mode (light, dark, or system).
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setTheme(ThemeMode mode) => state = mode;
}

/// Controls the base font size for Bible text display.
final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(
  FontSizeNotifier.new,
);

class FontSizeNotifier extends Notifier<double> {
  @override
  double build() => 16.0;

  void setSize(double size) => state = size;
}

/// Whether to automatically advance to the next chapter after playback ends.
final autoPlayNextChapterProvider =
    NotifierProvider<AutoPlayNextChapterNotifier, bool>(
  AutoPlayNextChapterNotifier.new,
);

class AutoPlayNextChapterNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void setValue(bool value) => state = value;
}
