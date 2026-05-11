import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router.dart';

class BibleAudioApp extends StatelessWidget {
  const BibleAudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bible Audio Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D4037),
        brightness: Brightness.light,
        textTheme: GoogleFonts.merriweatherTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D4037),
        brightness: Brightness.dark,
        textTheme: GoogleFonts.merriweatherTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      routerConfig: buildAppRouter(),
    );
  }
}
