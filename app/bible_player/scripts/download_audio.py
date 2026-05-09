#!/usr/bin/env python3
"""Download Bible audio files from public domain sources.

Supports downloading KJV and CUV audio chapter by chapter,
organized into assets/audio/{version}/{testament}/{book_dir}/ directories.

Usage:
    python3 scripts/download_audio.py --version KJV --book 1 --chapter 1
    python3 scripts/download_audio.py --version KJV --all
    python3 scripts/download_audio.py --version CUV --book 43 --chapter 3
"""

import argparse
import os
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

from bible_metadata import BOOKS, get_book_by_number, get_book_dir


# Base URLs for audio sources (public domain KJV audio)
# These are placeholder URLs - replace with actual source URLs
AUDIO_SOURCES = {
    'KJV': 'https://audio.publicdomain.kjv.example.com/{testament}/{book_dir}/chapter_{chapter:03d}.mp3',
    'CUV': 'https://audio.publicdomain.cuv.example.com/{testament}/{book_dir}/chapter_{chapter:03d}.mp3',
}

ASSETS_DIR = Path(__file__).parent.parent / 'app' / 'bible_player' / 'assets' / 'audio'


def download_file(url: str, dest: Path, retries: int = 3) -> bool:
    """Download a file from url to dest with retry logic."""
    for attempt in range(retries):
        try:
            print(f'  Downloading: {url}')
            urllib.request.urlretrieve(url, str(dest))
            print(f'  Saved to: {dest}')
            return True
        except urllib.error.URLError as e:
            print(f'  Attempt {attempt + 1}/{retries} failed: {e}')
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
    return False


def download_chapter(version: str, book_number: int, chapter: int) -> bool:
    """Download a single chapter's audio file."""
    book = get_book_by_number(book_number)
    book_dir = get_book_dir(book)
    testament = book.testament

    url_template = AUDIO_SOURCES.get(version)
    if not url_template:
        print(f'Error: Unknown version {version}')
        return False

    url = url_template.format(
        testament=testament,
        book_dir=book_dir,
        chapter=chapter,
    )

    dest_dir = ASSETS_DIR / version / testament / book_dir
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f'chapter_{chapter:03d}.mp3'

    if dest.exists():
        print(f'  Already exists: {dest}')
        return True

    return download_file(url, dest)


def download_book(version: str, book_number: int) -> None:
    """Download all chapters of a book."""
    book = get_book_by_number(book_number)
    print(f'\nDownloading {version} - {book.name_en} ({book.chapters} chapters)')
    for ch in range(1, book.chapters + 1):
        download_chapter(version, book_number, ch)


def download_all(version: str) -> None:
    """Download all chapters of all books for a version."""
    print(f'Downloading all {version} audio...')
    for book in BOOKS:
        download_book(version, book.number)


def main() -> None:
    parser = argparse.ArgumentParser(description='Download Bible audio files')
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
