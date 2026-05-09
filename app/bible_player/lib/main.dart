import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/db_service.dart';
import 'services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.init();
  await DbService.init();

  // Configure audio session for background playback (best-effort)
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (_) {
    // Ignore on platforms where audio_session is not supported
  }

  runApp(
    const ProviderScope(
      child: BibleAudioApp(),
    ),
  );
}
