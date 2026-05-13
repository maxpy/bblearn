import 'package:flutter/material.dart';

// App info
const String appName = 'BiblePlayer';
const String appVersion = '1.0.0';

// Bible version model
class BibleVersion {
  final String id;
  final String name;
  final String nameShort;
  final String language;

  const BibleVersion({
    required this.id,
    required this.name,
    required this.nameShort,
    required this.language,
  });
}

// Available Bible versions
const Map<String, BibleVersion> availableVersions = {
  'KJV': BibleVersion(
    id: 'KJV',
    name: 'King James Version',
    nameShort: 'KJV',
    language: 'en',
  ),
  'CUV': BibleVersion(
    id: 'CUV',
    name: '和合本',
    nameShort: '和合本',
    language: 'zh',
  ),
};

// Theme colors
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color accent = Color(0xFFFF9800);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color oldTestament = Color(0xFF5C6BC0);
  static const Color newTestament = Color(0xFF26A69A);
}
