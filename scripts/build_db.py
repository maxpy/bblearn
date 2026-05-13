#!/usr/bin/env python3
"""
Build bible.db from subtitle JSON files.

Schema:
  verses(version, book, chapter, verse, text, start, end)

Usage:
  python3 build_db.py
  python3 build_db.py --out app/bible_player/assets/data/bible.db
"""

import json
import sqlite3
import argparse
from pathlib import Path

BASE = Path(__file__).parent
ASSETS_AUDIO = BASE / 'app/bible_player/assets/audio'
DEFAULT_OUT = BASE / 'app/bible_player/assets/data/bible.db'


def build(out_path: Path):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if out_path.exists():
        out_path.unlink()

    con = sqlite3.connect(out_path)
    cur = con.cursor()
    cur.execute('''
        CREATE TABLE verses (
            version TEXT NOT NULL,
            book    INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse   INTEGER NOT NULL,
            text    TEXT NOT NULL,
            start   REAL NOT NULL DEFAULT 0,
            end     REAL NOT NULL DEFAULT 0,
            PRIMARY KEY (version, book, chapter, verse)
        )
    ''')
    cur.execute('CREATE INDEX idx_chapter ON verses (version, book, chapter)')
    con.commit()

    total = 0
    for version_dir in sorted(ASSETS_AUDIO.iterdir()):
        if not version_dir.is_dir():
            continue
        version = version_dir.name
        for testament_dir in sorted(version_dir.iterdir()):
            if not testament_dir.is_dir():
                continue
            for book_dir in sorted(testament_dir.iterdir()):
                if not book_dir.is_dir():
                    continue
                for f in sorted(book_dir.glob('*.subtitle.json')):
                    try:
                        data = json.loads(f.read_text(encoding='utf-8'))
                    except Exception as e:
                        print(f'  [SKIP] {f.name}: {e}')
                        continue

                    # Parse book/chapter from filename if not in JSON
                    # Filename: NN_BookName_CCC.subtitle.json
                    stem = f.name.replace('.subtitle.json', '')
                    parts = stem.split('_')
                    book = data.get('book') or int(parts[0])
                    chapter = data.get('chapter') or int(parts[-1])
                    verses = data.get('verses', [])

                    rows = [
                        (version, book, chapter,
                         v['verse'], v['text'],
                         v.get('start', 0.0), v.get('end', 0.0))
                        for v in verses
                    ]
                    cur.executemany(
                        'INSERT OR REPLACE INTO verses '
                        '(version, book, chapter, verse, text, start, end) '
                        'VALUES (?,?,?,?,?,?,?)',
                        rows
                    )
                    total += len(rows)

        print(f'{version}: inserted so far {total} rows')

    con.commit()
    con.close()

    size_mb = out_path.stat().st_size / 1024 / 1024
    print(f'\nDone: {total} verses → {out_path} ({size_mb:.1f} MB)')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', default=str(DEFAULT_OUT))
    args = parser.parse_args()
    build(Path(args.out))


if __name__ == '__main__':
    main()
