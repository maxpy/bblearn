import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/db_service.dart';
import 'services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, the engine may start in 'inactive' lifecycle state if the page
  // loads without window focus, causing the render loop to never start.
  // scheduleWarmUpFrame forces an initial frame regardless of lifecycle state.
  if (kIsWeb) {
    WidgetsBinding.instance.scheduleWarmUpFrame();
  }

  await PrefsService.init();
  await DbService.init();

  // Configure audio session for background playback with Bluetooth support
  try {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.allowBluetoothA2dp,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  } catch (_) {
    // Ignore on platforms where audio_session is not supported
  }

  runApp(
    const ProviderScope(
      child: BibleAudioApp(),
    ),
  );
}
