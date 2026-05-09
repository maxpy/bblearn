#!/usr/bin/env python3
"""Download Bible text (verse data) for KJV and CUV versions.

Downloads verse text and organizes into JSON files:
assets/data/text/{version}/{testament}/{book_dir}/chapter_{NNN}.json

Each JSON file contains an array of verse objects:
[
  {"verse": 1, "text": "In the beginning God created..."},
  {"verse": 2, "text": "And the earth was without form..."},
  ...
]

Usage:
    python3 scripts/download_text.py --version KJV --book 1 --chapter 1
    python3 scripts/download_text.py --version KJV --all
"""

import argparse
import json
import os
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

from bible_metadata import BOOKS, get_book_by_number, get_book_dir


# Base URLs for text sources
# These are placeholder URLs - replace with actual API endpoints
TEXT_SOURCES = {
    'KJV': 'https://api.bible.example.com/kjv/{book_abbrev}/{chapter}',
    'CUV': 'https://api.bible.example.com/cuv/{book_abbrev}/{chapter}',
}

DATA_DIR = Path(__file__).parent.parent / 'app' / 'bible_player' / 'assets' / 'data' / 'text'


def fetch_chapter_text(version: str, book_number: int, chapter: int) -> list:
    """Fetch verse text for a chapter from the API.

    Returns a list of dicts: [{"verse": 1, "text": "..."}, ...]
    """
    book = get_book_by_number(book_number)
    url_template = TEXT_SOURCES.get(version)
    if not url_template:
        raise ValueError(f'Unknown version: {version}')

    url = url_template.format(
        book_abbrev=book.abbrev_en,
        chapter=chapter,
    )

    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            data = json.loads(response.read().decode('utf-8'))
            # Normalize response format
            if isinstance(data, list):
                return [{'verse': v.get('verse', i + 1), 'text': v.get('text', '')}
                        for i, v in enumerate(data)]
            elif isinstance(data, dict) and 'verses' in data:
                return [{'verse': v.get('verse', i + 1), 'text': v.get('text', '')}
                        for i, v in enumerate(data['verses'])]
            else:
                print(f'  Warning: Unexpected response format for {url}')
                return []
    except urllib.error.URLError as e:
        print(f'  Error fetching {url}: {e}')
        return []


def save_chapter_text(version: str, book_number: int, chapter: int,
                      verses: list) -> Path:
    """Save verse text to a JSON file."""
    book = get_book_by_number(book_number)
    book_dir = get_book_dir(book)
    testament = book.testament

    dest_dir = DATA_DIR / version / testament / book_dir
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f'chapter_{chapter:03d}.json'

    with open(dest, 'w', encoding='utf-8') as f:
        json.dump(verses, f, ensure_ascii=False, indent=2)

    print(f'  Saved {len(verses)} verses to {dest}')
    return dest


def download_chapter(version: str, book_number: int, chapter: int) -> bool:
    """Download text for a single chapter."""
    book = get_book_by_number(book_number)
    book_dir = get_book_dir(book)
    testament = book.testament

    dest_dir = DATA_DIR / version / testament / book_dir
    dest = dest_dir / f'chapter_{chapter:03d}.json'

    if dest.exists():
        print(f'  Already exists: {dest}')
        return True

    verses = fetch_chapter_text(version, book_number, chapter)
    if verses:
        save_chapter_text(version, book_number, chapter, verses)
        return True
    return False


def download_book(version: str, book_number: int) -> None:
    """Download text for all chapters of a book."""
    book = get_book_by_number(book_number)
    print(f'\nDownloading {version} text - {book.name_en} ({book.chapters} chapters)')
    for ch in range(1, book.chapters + 1):
        download_chapter(version, book_number, ch)
        time.sleep(0.5)  # Rate limiting


def download_all(version: str) -> None:
    """Download text for all books and chapters."""
    print(f'Downloading all {version} text...')
    for book in BOOKS:
        download_book(version, book.number)


def main() -> None:
    parser = argparse.ArgumentParser(description='Download Bible text data')
    parser.add_argument('--version', choices=['KJV', 'CUV'], required=True,
                        help='Bible version to download')
    parser.add_argument('--book', type=int, help='Book number (1-66)')
    parser.add_argument('--chapter', type=int, help='Chapter number')
    parser.add_argument('--all', action='store_true',
                        help='Download all books and chapters')
    args = parser.parse_args()

    if args.all:
        download_all(args.version)
    elif args.book and args.chapter:
        download_chapter(args.version, args.book, args.chapter)
    elif args.book:
        download_book(args.version, args.book)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()
