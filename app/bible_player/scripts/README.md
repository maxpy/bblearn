# Bible Audio Player

A bilingual (English KJV + Chinese CUV) Bible audio player with synchronised subtitles, built with Flutter and powered by Python data-preparation scripts.

## Project Structure

```
.
├── scripts/                   # Python data pipeline
│   ├── bible_metadata.py      # Book names, chapter counts, abbreviations
│   ├── download_audio.py      # Download KJV chapter MP3s
│   ├── download_text.py       # Download bilingual verse text (JSON)
│   └── generate_subtitles.py  # Create time-aligned subtitle JSON
│
├── app/                       # Flutter application
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   └── lib/
│       ├── main.dart          # Entry point
│       ├── app.dart           # Root widget with providers
│       ├── theme.dart         # Material 3 theme
│       ├── constants.dart     # App-wide constants
│       ├── models/
│       │   ├── bible_book.dart
│       │   ├── chapter_data.dart
│       │   ├── play_sequence.dart
│       │   ├── verse_text.dart
│       │   └── verse_timing.dart
│       ├── services/
│       │   ├── bible_data_service.dart   # Loads JSON data files
│       │   └── audio_playback_service.dart # just_audio wrapper
│       ├── providers/
│       │   ├── bible_provider.dart  # Book/chapter state
│       │   └── audio_provider.dart  # Playback state
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── book_list_screen.dart
│       │   ├── chapter_list_screen.dart
│       │   └── player_screen.dart
│       └── widgets/
│           ├── verse_card.dart       # Bilingual verse display
│           ├── subtitle_display.dart # Active-verse banner
│           └── audio_controls.dart   # Transport bar
│
└── package.json
```

## Getting Started

### 1. Prepare Data (Python ≥ 3.9)

```bash
cd scripts
pip install requests

# Generate the master book list
python bible_metadata.py

# Download chapter audio (MP3)
python download_audio.py

# Download bilingual verse text
python download_text.py

# Generate subtitle timing files
python generate_subtitles.py
```

All output is written to a `data/` directory.

### 2. Run the Flutter App

```bash
cd app
flutter pub get
flutter run
```

The app expects the `data/` directory to be accessible at runtime (in the working directory or the device's documents folder).

## Features

- **Bilingual text** – every verse shown in English (KJV) and Chinese (CUV)
- **Synchronised subtitles** – active verse highlighted as audio plays
- **Chapter navigation** – browse by testament → book → chapter
- **Continuous playback** – auto-advances through chapters
- **Playback controls** – play/pause, ±10 s skip, chapter skip, speed (0.5×–2×)
- **Search** – filter books by English name, Chinese name, or abbreviation
- **Material 3 theming** – light and dark modes follow system preference

## Dependencies

| Package | Purpose |
| --- | --- |
| `provider` | State management |
| `just_audio` | Audio playback |
| `path_provider` | Locate documents directory |
| `google_fonts` | Noto Sans for CJK support |
