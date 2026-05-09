# Bible Audio Player

A Flutter web application for listening to Bible audio with synchronized verse highlighting.

## Features

- Browse all 66 books of the Bible (Old and New Testament)
- Select chapters with a visual grid interface
- Listen to audio playback with play/pause, seek, and speed controls
- Synchronized verse highlighting that follows along with the audio
- Tap any verse to jump to that position in the audio
- Responsive Material Design 3 UI with dark mode support

## Architecture

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp configuration
├── router.dart               # GoRouter navigation setup
├── constants/
│   ├── api_constants.dart    # API URL helpers
│   ├── app_constants.dart    # App-wide constants
│   └── bible_data.dart       # Static data for all 66 books
├── models/
│   ├── book.dart             # Book model (id, name, chapters)
│   ├── chapter.dart          # Chapter model
│   └── timed_verse.dart      # Verse with start/end timestamps
├── services/
│   ├── audio_service.dart    # just_audio wrapper
│   ├── bible_data_service.dart # Fetches audio URLs & SRT data
│   └── srt_parser.dart       # Parses SRT subtitle files
├── providers/
│   ├── app_providers.dart    # Riverpod providers for services
│   └── audio_provider.dart   # Audio playback state management
├── screens/
│   ├── home_screen.dart      # Book selection with OT/NT tabs
│   ├── book_screen.dart      # Chapter selection grid
│   └── player_screen.dart    # Audio player with verse display
└── widgets/
    ├── audio_controls.dart   # Playback controls widget
    ├── book_card.dart        # Book grid card
    ├── chapter_selector.dart # Chapter number grid
    └── verse_list.dart       # Scrollable verse list with highlighting
```

## Tech Stack

- **Flutter 3.x** (Web target)
- **Riverpod** for state management
- **GoRouter** for declarative routing
- **just_audio** for audio playback
- **Google Fonts** (Merriweather)
- **Equatable** for value equality

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run in development
flutter run -d chrome

# Build for production
flutter build web
```

## Testing

```bash
flutter test
```
