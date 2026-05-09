#!/usr/bin/env python3
"""
KJV 字幕重新对齐脚本
策略:
  1. Whisper 转录 MP3 → word-level timestamps (英文)
  2. DTW 单词级对齐: 把转录单词序列对齐到经文单词序列
  3. 找每个经节边界对应的时间戳
  4. 输出新的 subtitle.json 到 app assets 目录

用法:
  python3 realign_kjv.py --book 41 --chapter 1   # 测试单章
  python3 realign_kjv.py --book 41               # 整本书
  python3 realign_kjv.py                          # 全部 KJV
  python3 realign_kjv.py --dry-run               # 只打印不写文件
"""

import os, sys, json, re, argparse
import numpy as np
from pathlib import Path

BASE = Path.home() / "bible-audio"
KJV_SRC = BASE / "KJV"
APP_ASSETS = BASE / "app/bible_player/assets/audio/KJV"

BOOK_EN = {
    1:"Genesis",2:"Exodus",3:"Leviticus",4:"Numbers",5:"Deuteronomy",
    6:"Joshua",7:"Judges",8:"Ruth",9:"1Samuel",10:"2Samuel",
    11:"1Kings",12:"2Kings",13:"1Chronicles",14:"2Chronicles",
    15:"Ezra",16:"Nehemiah",17:"Esther",18:"Job",19:"Psalms",
    20:"Proverbs",21:"Ecclesiastes",22:"SongOfSolomon",23:"Isaiah",
    24:"Jeremiah",25:"Lamentations",26:"Ezekiel",27:"Daniel",
    28:"Hosea",29:"Joel",30:"Amos",31:"Obadiah",32:"Jonah",
    33:"Micah",34:"Nahum",35:"Habakkuk",36:"Zephaniah",37:"Haggai",
    38:"Zechariah",39:"Malachi",40:"Matthew",41:"Mark",42:"Luke",
    43:"John",44:"Acts",45:"Romans",46:"1Corinthians",47:"2Corinthians",
    48:"Galatians",49:"Ephesians",50:"Philippians",51:"Colossians",
    52:"1Thessalonians",53:"2Thessalonians",54:"1Timothy",55:"2Timothy",
    56:"Titus",57:"Philemon",58:"Hebrews",59:"James",60:"1Peter",
    61:"2Peter",62:"1John",63:"2John",64:"3John",65:"Jude",66:"Revelation",
}

def find_src_dir(book_num):
    testament = "OT" if book_num <= 39 else "NT"
    prefix = f"{book_num:02d}_"
    base = KJV_SRC / testament
    candidates = [d for d in base.iterdir() if d.is_dir() and d.name.startswith(prefix)]
    for d in candidates:
        if any(f.suffix == '.mp3' for f in d.iterdir()):
            return d
    return candidates[0] if candidates else None

def find_mp3(src_dir, chapter):
    prefix = f"{src_dir.name}_{chapter:03d}"
    for f in src_dir.iterdir():
        if f.name.startswith(prefix) and f.suffix == '.mp3':
            return f
    return None

def load_verse_texts(src_dir, chapter):
    prefix = f"{src_dir.name}_{chapter:03d}"
    for f in src_dir.iterdir():
        if f.name.startswith(prefix) and f.suffix == '.json' and 'txt' in f.name:
            with open(f, encoding='utf-8') as fp:
                return json.load(fp).get('verses', [])
    return []

def transcribe(mp3_path, model):
    """Whisper 转录，返回 word-level timestamps"""
    result = model.transcribe(
        str(mp3_path),
        language='en',
        word_timestamps=True,
        verbose=False,
    )
    words = []
    for seg in result['segments']:
        for w in seg.get('words', []):
            text = w.get('word', w.get('text', '')).strip()
            text_clean = clean_english(text)
            if text_clean:
                words.append({
                    'text': text_clean,
                    'start': w['start'],
                    'end': w['end'],
                })
    return words

def clean_english(text):
    """小写，只保留字母数字"""
    return re.sub(r"[^a-z0-9']", '', text.lower())

def dtw_align(transcript_words, verse_words):
    """
    DTW 单词级对齐。
    transcript_words: list of (word, start_time, end_time)
    verse_words: list of (word, verse_num)
    返回: dict {verse_word_idx: transcript_word_idx}
    """
    n = len(transcript_words)
    m = len(verse_words)
    if n == 0 or m == 0:
        return {}

    def cost(i, j):
        tw = transcript_words[i][0]
        vw = verse_words[j][0]
        if tw == vw:
            return 0
        # partial match: one starts with the other
        if tw.startswith(vw) or vw.startswith(tw):
            return 0.3
        return 1

    dtw = np.full((n + 1, m + 1), np.inf)
    dtw[0, 0] = 0
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            c = cost(i - 1, j - 1)
            dtw[i, j] = c + min(dtw[i-1, j], dtw[i, j-1], dtw[i-1, j-1])

    path = []
    i, j = n, m
    while i > 0 and j > 0:
        path.append((i - 1, j - 1))
        choices = [(dtw[i-1, j-1], i-1, j-1),
                   (dtw[i-1, j],   i-1, j),
                   (dtw[i, j-1],   i,   j-1)]
        _, i, j = min(choices, key=lambda x: x[0])
    path.reverse()

    verse_to_transcript = {}
    for ti, vi in path:
        if vi not in verse_to_transcript:
            verse_to_transcript[vi] = ti

    return verse_to_transcript

def align_chapter(mp3_path, verses, model):
    words = transcribe(mp3_path, model)
    if not words:
        print(f"    [WARN] no words from whisper")
        return None

    # 经文单词序列
    transcript_words = [(w['text'], w['start'], w['end']) for w in words]

    verse_words = []
    for v in verses:
        for word in v['text'].split():
            cleaned = clean_english(word)
            if cleaned:
                verse_words.append((cleaned, v['verse']))

    if not transcript_words or not verse_words:
        return None

    verse_to_transcript = dtw_align(transcript_words, verse_words)

    # 找每个经节的起止单词索引
    verse_boundaries = {}
    for vi, (word, vnum) in enumerate(verse_words):
        if vnum not in verse_boundaries:
            verse_boundaries[vnum] = [vi, vi]
        else:
            verse_boundaries[vnum][1] = vi

    aligned = []
    verse_nums = sorted(verse_boundaries.keys())
    for vnum in verse_nums:
        first_vi, last_vi = verse_boundaries[vnum]

        start_ti = verse_to_transcript.get(first_vi)
        end_ti = verse_to_transcript.get(last_vi)

        if start_ti is None or end_ti is None:
            start_time = aligned[-1]['end'] if aligned else 0.0
            end_time = start_time + 5.0
        else:
            start_time = transcript_words[start_ti][1]
            end_time = transcript_words[end_ti][2]

        if aligned and start_time < aligned[-1]['end']:
            start_time = aligned[-1]['end']
        if end_time <= start_time:
            end_time = start_time + 0.5

        verse_text = next(v['text'] for v in verses if v['verse'] == vnum)
        aligned.append({
            'verse': vnum,
            'text': verse_text,
            'start': round(start_time, 3),
            'end': round(end_time, 3),
        })

    # 边界：优先用当前节最后一个 word.end
    # 只有当 word.end >= 下一节 start 时才截断到 下一节start - 80ms
    for i in range(len(aligned) - 1):
        next_start = aligned[i + 1]['start']
        if aligned[i]['end'] >= next_start:
            boundary = round(next_start - 0.08, 3)
            if boundary > aligned[i]['start']:
                aligned[i]['end'] = boundary

    return aligned

def output_path(book_num, chapter):
    testament = "OT" if book_num <= 39 else "NT"
    en = BOOK_EN[book_num]
    book_dir = f"{book_num:02d}_{en}"
    fname = f"{book_num:02d}_{en}_{chapter:03d}.subtitle.json"
    return APP_ASSETS / testament / book_dir / fname

def process_chapter(book_num, chapter, model, dry_run=False, verbose=True):
    src_dir = find_src_dir(book_num)
    if not src_dir:
        print(f"  [SKIP] book {book_num} src dir not found")
        return False

    mp3 = find_mp3(src_dir, chapter)
    if not mp3:
        print(f"  [SKIP] {book_num}:{chapter} mp3 not found")
        return False

    verses = load_verse_texts(src_dir, chapter)
    if not verses:
        print(f"  [SKIP] {book_num}:{chapter} no verse texts")
        return False

    if verbose:
        print(f"  Processing {mp3.name} ({len(verses)} verses)...")

    aligned = align_chapter(mp3, verses, model)
    if not aligned:
        print(f"  [FAIL] {book_num}:{chapter} alignment failed")
        return False

    out = output_path(book_num, chapter)
    result = {
        'book': book_num,
        'chapter': chapter,
        'verses': aligned,
    }

    if dry_run:
        print(f"  OK  v1: {aligned[0]['start']:.3f}-{aligned[0]['end']:.3f}")
        return True

    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    if verbose:
        print(f"  OK  v1: {aligned[0]['start']:.3f}-{aligned[0]['end']:.3f}  → {out.name}")
    return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--book', type=int)
    parser.add_argument('--chapter', type=int)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    import whisper
    print("Loading Whisper model 'base'...")
    model = whisper.load_model('base')
    print("Model loaded.")

    if args.book and args.chapter:
        process_chapter(args.book, args.chapter, model, args.dry_run)
    elif args.book:
        src_dir = find_src_dir(args.book)
        chapters = sorted(set(
            int(f.stem.split('_')[-1])
            for f in src_dir.iterdir()
            if f.suffix == '.mp3'
        ))
        print(f"Book {args.book}: {len(chapters)} chapters")
        ok = sum(process_chapter(args.book, ch, model, args.dry_run) for ch in chapters)
        print(f"Done: {ok}/{len(chapters)}")
    else:
        total_ok = total = 0
        for book_num in range(1, 67):
            src_dir = find_src_dir(book_num)
            if not src_dir:
                continue
            chapters = sorted(set(
                int(f.stem.split('_')[-1])
                for f in src_dir.iterdir()
                if f.suffix == '.mp3'
            ))
            print(f"\nBook {book_num:02d} {BOOK_EN[book_num]}: {len(chapters)} chapters")
            for ch in chapters:
                total += 1
                if process_chapter(book_num, ch, model, args.dry_run, verbose=False):
                    total_ok += 1
                    if total_ok % 50 == 0:
                        print(f"  Progress: {total_ok}/{total}")
        print(f"\nAll done: {total_ok}/{total}")

if __name__ == '__main__':
    main()
