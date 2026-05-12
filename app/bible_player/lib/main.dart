import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'app.dart';
import 'services/db_service.dart';
import 'services/prefs_service.dart';

/// Load Noto Sans SC from jsDelivr CDN and register with Flutter/CanvasKit.
/// Awaited before runApp so Chinese text renders correctly on first frame.
Future<void> _loadChineseFont() async {
  try {
    final response = await http
        .get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fontsource/noto-sans-sc@5/files/'
          'noto-sans-sc-chinese-simplified-400-normal.woff2',
        ))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final loader = FontLoader('NotoSansSC')
        ..addFont(Future.value(ByteData.sublistView(response.bodyBytes)));
      await loader.load();
    }
  } catch (_) {
    // Non-fatal — Chinese text will show boxes without this font on CanvasKit
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    WidgetsBinding.instance.scheduleWarmUpFrame();
    // Load Chinese font async — don't block app startup
    _loadChineseFont();
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
