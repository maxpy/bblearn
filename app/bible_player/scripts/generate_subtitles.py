#!/usr/bin/env python3
"""Generate SRT subtitle files for Bible chapters.

Usage:
    python3 scripts/generate_subtitles.py --book GEN --chapter 1 --output app/bible_player/assets/subtitles/
    python3 scripts/generate_subtitles.py --book GEN --chapter 1  # defaults to assets/subtitles/
"""

import argparse
import os
import sys

# Sample verse data for Genesis 1 (expand as needed)
SAMPLE_VERSES = {
    'GEN': {
        1: [
            'In the beginning God created the heavens and the earth.',
            'Now the earth was formless and empty, darkness was over the surface of the deep,',
            'and the Spirit of God was hovering over the waters.',
            'And God said, "Let there be light," and there was light.',
            'God saw that the light was good, and he separated the light from the darkness.',
            'God called the light "day," and the darkness he called "night."',
            'And there was evening, and there was morning — the first day.',
        ],
    },
}


def generate_srt(book: str, chapter: int, seconds_per_verse: float = 5.0) -> str:
    """Generate SRT content for a given book and chapter."""
    book = book.upper()
    verses = SAMPLE_VERSES.get(book, {}).get(chapter, [])

    if not verses:
        print(f'Warning: No verse data found for {book} chapter {chapter}', file=sys.stderr)
        print('Generating placeholder SRT with sample content.', file=sys.stderr)
        verses = [f'{book} Chapter {chapter}, Verse {i+1}' for i in range(5)]

    lines = []
    current_time = 0.0

    for i, verse_text in enumerate(verses):
        index = i + 1
        start = current_time
        end = start + seconds_per_verse

        start_str = format_srt_time(start)
        end_str = format_srt_time(end)

        lines.append(f'{index}')
        lines.append(f'{start_str} --> {end_str}')
        lines.append(verse_text)
        lines.append('')

        current_time = end + 0.5  # 0.5s gap between cues

    return '\n'.join(lines)


def format_srt_time(seconds: float) -> str:
    """Format seconds into SRT timestamp HH:MM:SS,mmm."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds % 1) * 1000)
    return f'{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}'


def main():
    parser = argparse.ArgumentParser(description='Generate SRT subtitles for Bible chapters')
    parser.add_argument('--book', required=True, help='Book ID (e.g., GEN, EXO)')
    parser.add_argument('--chapter', required=True, type=int, help='Chapter number')
    parser.add_argument('--output', default='app/bible_player/assets/subtitles/',
                        help='Output directory')
    parser.add_argument('--seconds-per-verse', type=float, default=5.0,
                        help='Seconds per verse (default: 5.0)')

    args = parser.parse_args()

    os.makedirs(args.output, exist_ok=True)

    srt_content = generate_srt(args.book, args.chapter, args.seconds_per_verse)
    filename = f'{args.book.lower()}_{args.chapter}.srt'
    filepath = os.path.join(args.output, filename)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(srt_content)

    print(f'Generated: {filepath}')


if __name__ == '__main__':
    main()
