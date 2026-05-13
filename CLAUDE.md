# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

```
bible_player/       # Flutter app (main working directory)
workers/bible-api/  # Cloudflare Worker serving Bible data from KV
scripts/            # Python utilities (build DB, export KV, realign SRT)
versions/           # Raw Bible text data (KJV, CUV, KOR)
```

All Flutter work happens inside `bible_player/`. Run all `flutter` commands from there.

## Common Commands

```bash
# Development
cd bible_player
flutter pub get
flutter run -d chrome                    # web dev server
flutter run -d 00008140-001C0D0E028B001C # iOS device

# Testing
flutter test                             # unit tests
flutter test test/services/audio_player_service_test.dart  # single file
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/playback_test.dart -d chrome   # integration

# Build & deploy web
flutter build web --release
HTTPS_PROXY=http://127.0.0.1:7890 HTTP_PROXY=http://127.0.0.1:7890 \
  npx wrangler pages deploy build/web --project-name bible-audio --commit-dirty=true

# Build & deploy iOS
flutter build ios --release
xcrun devicectl device install app --device 9328007D-D13A-590C-B9D8-B318B132507B \
  build/ios/iphoneos/Runner.app

# Deploy Cloudflare Worker
cd workers/bible-api && npx wrangler deploy
```

## Architecture

### Data Flow

```
SQLite (bible.db)          ← iOS/Android
Cloudflare KV Worker API   ← Web (DbService._loadFromKv)
```

`DbService` detects `kIsWeb` and routes accordingly. Both paths produce identical `VerseTiming` + `VerseText` objects. The KV API is at `https://api.bblearn.uk/bible/{version}/{book}/{chapter}`.

### Playback Engine

`AudioPlayerService` wraps `just_audio` and exposes a `stateStream` of `PlaybackState`. On iOS it delegates to a native `AVAudioEngine` platform channel for lock-screen playback and speed control via `AVAudioUnitTimePitch`. On web it uses `just_audio`'s HTML audio backend with manual seek-based clipping.

`PlayQueue` builds the ordered clip list from `ChapterData` + `PlaySequence`. A `PlaySequence` defines the interleaving pattern (e.g. EN→CN per verse, EN chapter then CN chapter).

### State Management (Riverpod)

Key providers in `lib/providers/playback_provider.dart`:
- `audioPlayerServiceProvider` — singleton `AudioPlayerService`
- `playbackStateProvider` — `StreamProvider` wrapping `stateStream`
- `currentSequenceProvider` — persisted play sequence selection
- `stepSpeedsProvider` — per-version speed multipliers (persisted)

`BilingualPlayerNotifier` (also in `playback_provider.dart`) orchestrates chapter loading, sequence switching, and auto-advance.

### Navigation

`go_router` in `lib/router.dart`. `initialLocation` is set from `PrefsService` to restore the last-played position on startup. Routes: `/` (home) → `/book/:id` → `/player/:book/:chapter`.

### External Services

- Audio files: `https://audio.bblearn.uk/audio/{version}/{book}/{chapter}.mp3`
- Bible text/timing: `https://api.bblearn.uk/bible/{version}/{book}/{chapter}` (Cloudflare KV Worker, web only)

### Platform Notes

- **Web**: proxy (port 7890) required for `wrangler` CLI calls to Cloudflare API
- **iOS**: always build release (`flutter build ios --release`); debug requires flutter tooling to launch
- **Riverpod codegen**: if adding `@riverpod` annotations, run `flutter pub run build_runner build`
