#!/usr/bin/env python3
"""
Export bible.db verses to Cloudflare KV bulk JSON files.
Key format: bible:{version}:{book}:{chapter}
Value: JSON array of {verse, text, start, end}
"""

import sqlite3
import json
import os
import sys

DB_PATH = os.path.join(os.path.dirname(__file__), "../app/bible_player/assets/data/bible.db")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "../tmp/kv_bulk")

os.makedirs(OUTPUT_DIR, exist_ok=True)

conn = sqlite3.connect(DB_PATH)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

# Group verses by version/book/chapter
cur.execute("""
    SELECT version, book, chapter, verse, text, start, end
    FROM verses
    ORDER BY version, book, chapter, verse
""")

chapters = {}
for row in cur.fetchall():
    key = f"bible:{row['version']}:{row['book']}:{row['chapter']}"
    if key not in chapters:
        chapters[key] = []
    chapters[key].append({
        "verse": row["verse"],
        "text": row["text"],
        "start": row["start"],
        "end": row["end"],
    })

conn.close()

print(f"Total chapters (keys): {len(chapters)}")

# Build bulk array (wrangler supports up to 10000 per request)
bulk = []
for key, verses in chapters.items():
    bulk.append({
        "key": key,
        "value": json.dumps(verses, ensure_ascii=False),
    })

# Split into chunks of 5000 to stay well within limits
CHUNK = 5000
chunks = [bulk[i:i+CHUNK] for i in range(0, len(bulk), CHUNK)]
print(f"Writing {len(chunks)} bulk file(s)...")

for i, chunk in enumerate(chunks):
    path = os.path.join(OUTPUT_DIR, f"bulk_{i+1}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(chunk, f, ensure_ascii=False)
    print(f"  {path}: {len(chunk)} keys, {os.path.getsize(path)/1024/1024:.1f} MB")

print("Done.")
