import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router.dart';

class BibleAudioApp extends StatelessWidget {
  const BibleAudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // On web (CanvasKit), Merriweather has no CJK glyphs. Add NotoSansSC
    // (loaded from CDN in main.dart) as fallback for Chinese characters.
    TextTheme buildTextTheme([TextTheme? base]) {
      final t = GoogleFonts.merriweatherTextTheme(base);
      if (!kIsWeb) return t;
      TextStyle patch(TextStyle? s) => (s ?? const TextStyle())
          .copyWith(fontFamilyFallback: const ['NotoSansSC']);
      return t.copyWith(
        bodySmall: patch(t.bodySmall),
        bodyMedium: patch(t.bodyMedium),
        bodyLarge: patch(t.bodyLarge),
        labelSmall: patch(t.labelSmall),
        labelMedium: patch(t.labelMedium),
        labelLarge: patch(t.labelLarge),
        titleSmall: patch(t.titleSmall),
        titleMedium: patch(t.titleMedium),
        titleLarge: patch(t.titleLarge),
      );
    }

    return MaterialApp.router(
      title: 'Bible Audio Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D4037),
        brightness: Brightness.light,
        textTheme: buildTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D4037),
        brightness: Brightness.dark,
        textTheme: buildTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
      ),
      routerConfig: buildAppRouter(),
    );
  }
}
