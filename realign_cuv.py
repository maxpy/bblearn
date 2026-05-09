#!/usr/bin/env python3
"""
CUV 字幕重新对齐脚本
策略:
  1. Whisper 转录 MP3 → word-level timestamps (繁体/有识别错误)
  2. 繁体转简体
  3. DTW 字符级对齐: 把转录字符序列对齐到经文字符序列
  4. 找每个经节边界对应的时间戳
  5. 输出新的 subtitle.json 到 app assets 目录

用法:
  python3 realign_cuv.py --book 41 --chapter 1   # 测试单章
  python3 realign_cuv.py --book 41               # 整本书
  python3 realign_cuv.py                          # 全部 CUV
  python3 realign_cuv.py --dry-run               # 只打印不写文件
"""

import os, sys, json, re, argparse
import numpy as np
from pathlib import Path

BASE = Path.home() / "bible-audio"
CUV_SRC = BASE / "CUV"          # 原始 MP3（中文目录名）
APP_ASSETS = BASE / "app/bible_player/assets/audio/CUV"  # 输出目标

# 书卷号 → 英文名（用于 app assets 路径）
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
    """找原始 MP3 目录（优先选含 MP3 的目录）"""
    testament = "OT" if book_num <= 39 else "NT"
    prefix = f"{book_num:02d}_"
    base = CUV_SRC / testament
    candidates = [d for d in base.iterdir() if d.name.startswith(prefix)]
    # Prefer the directory that actually contains MP3 files
    for d in candidates:
        if any(f.suffix == '.mp3' for f in d.iterdir()):
            return d
    return candidates[0] if candidates else None

def find_mp3(src_dir, chapter):
    """找章节 MP3"""
    prefix = f"{src_dir.name}_{chapter:03d}"
    for f in src_dir.iterdir():
        if f.name.startswith(prefix) and f.suffix == '.mp3':
            return f
    return None

def load_verse_texts(src_dir, chapter):
    """加载经文文本"""
    prefix = f"{src_dir.name}_{chapter:03d}"
    for f in src_dir.iterdir():
        if f.name.startswith(prefix) and f.suffix == '.json' and 'txt' in f.name:
            with open(f, encoding='utf-8') as fp:
                return json.load(fp).get('verses', [])
    return []

def transcribe(mp3_path, model):
    """Whisper 转录，返回 word-level timestamps"""
    import whisper
    result = model.transcribe(
        str(mp3_path),
        language='zh',
        word_timestamps=True,
        verbose=False,
    )
    words = []
    for seg in result['segments']:
        for w in seg.get('words', []):
            text = w.get('word', w.get('text', '')).strip()
            # 去掉标点
            text_clean = re.sub(r'[^\u4e00-\u9fff\u3400-\u4dbf]', '', text)
            if text_clean:
                words.append({
                    'text': text_clean,
                    'start': w['start'],
                    'end': w['end'],
                })
    return words

def t2s(text):
    """繁体转简体"""
    import opencc
    cc = opencc.OpenCC('t2s')
    return cc.convert(text)

def clean_chinese(text):
    """只保留汉字"""
    return re.sub(r'[^\u4e00-\u9fff\u3400-\u4dbf]', '', text)

def dtw_align(transcript_chars, verse_chars):
    """
    DTW 字符级对齐。
    transcript_chars: list of (char, start_time, end_time)
    verse_chars: list of (char, verse_num)
    返回: list of (verse_num, start_idx, end_idx) in transcript_chars
    """
    n = len(transcript_chars)
    m = len(verse_chars)
    if n == 0 or m == 0:
        return []

    # 简单的字符相似度: 相同=0, 不同=1
    def cost(i, j):
        return 0 if transcript_chars[i][0] == verse_chars[j][0] else 1

    # DTW matrix
    dtw = np.full((n + 1, m + 1), np.inf)
    dtw[0, 0] = 0
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            c = cost(i - 1, j - 1)
            dtw[i, j] = c + min(dtw[i-1, j], dtw[i, j-1], dtw[i-1, j-1])

    # 回溯路径
    path = []
    i, j = n, m
    while i > 0 and j > 0:
        path.append((i - 1, j - 1))
        choices = [(dtw[i-1, j-1], i-1, j-1),
                   (dtw[i-1, j],   i-1, j),
                   (dtw[i, j-1],   i,   j-1)]
        _, i, j = min(choices, key=lambda x: x[0])
    path.reverse()

    # 找每个 verse_char 对应的 transcript_char 索引
    verse_to_transcript = {}
    for ti, vi in path:
        if vi not in verse_to_transcript:
            verse_to_transcript[vi] = ti

    return verse_to_transcript

def align_chapter(mp3_path, verses, model, dry_run=False):
    """对齐一章，返回 aligned_verses"""
    # 转录
    words = transcribe(mp3_path, model)
    if not words:
        print(f"    [WARN] no words from whisper")
        return None

    # 转简体
    transcript_chars = []
    for w in words:
        simplified = clean_chinese(t2s(w['text']))
        for ch in simplified:
            transcript_chars.append((ch, w['start'], w['end']))

    # 经文字符序列
    verse_chars = []
    for v in verses:
        text_clean = clean_chinese(v['text'])
        for ch in text_clean:
            verse_chars.append((ch, v['verse']))

    if not transcript_chars or not verse_chars:
        return None

    # DTW 对齐
    verse_to_transcript = dtw_align(transcript_chars, verse_chars)

    # 找每个经节的起止时间
    # 按经节分组 verse_chars 的索引
    verse_boundaries = {}  # verse_num → (first_vi, last_vi)
    for vi, (ch, vnum) in enumerate(verse_chars):
        if vnum not in verse_boundaries:
            verse_boundaries[vnum] = [vi, vi]
        else:
            verse_boundaries[vnum][1] = vi

    aligned = []
    verse_nums = sorted(verse_boundaries.keys())
    for idx, vnum in enumerate(verse_nums):
        first_vi, last_vi = verse_boundaries[vnum]

        # 找 start: 该经节第一个字对应的 transcript 时间
        start_ti = verse_to_transcript.get(first_vi)
        end_ti = verse_to_transcript.get(last_vi)

        if start_ti is None or end_ti is None:
            # fallback: 用前后经节插值
            start_time = aligned[-1]['end'] if aligned else 0.0
            end_time = start_time + 5.0
        else:
            start_time = transcript_chars[start_ti][1]
            end_time = transcript_chars[end_ti][2]

        # 确保时间单调递增
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

    # 相邻经节边界：优先用当前节最后一个字的 word.end
    # 只有当 word.end 超过下一节 start 时，才截断到 下一节start - 80ms
    for i in range(len(aligned) - 1):
        next_start = aligned[i + 1]['start']
        if aligned[i]['end'] >= next_start:
            boundary = round(next_start - 0.08, 3)
            if boundary > aligned[i]['start']:
                aligned[i]['end'] = boundary

    return aligned

def output_path(book_num, chapter):
    """app assets 输出路径"""
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
        print(f"  Processing {src_dir.name} ch.{chapter:03d} ({len(verses)} verses)...", end=' ', flush=True)

    aligned = align_chapter(mp3, verses, model, dry_run)
    if not aligned:
        print("FAILED")
        return False

    if verbose:
        print(f"OK  v1: {aligned[0]['start']:.3f}-{aligned[0]['end']:.3f}")

    if not dry_run:
        out = output_path(book_num, chapter)
        out.parent.mkdir(parents=True, exist_ok=True)
        data = {
            'audio': mp3.name,
            'language': 'zh',
            'duration': aligned[-1]['end'],
            'verse_count': len(aligned),
            'verses': aligned,
        }
        with open(out, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--book', type=int, help='Book number (1-66)')
    parser.add_argument('--chapter', type=int, help='Chapter number')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--model', default='base', help='Whisper model size')
    args = parser.parse_args()

    print(f"Loading Whisper model '{args.model}'...")
    import whisper
    model = whisper.load_model(args.model)
    print("Model loaded.")

    if args.book and args.chapter:
        process_chapter(args.book, args.chapter, model, args.dry_run, verbose=True)
    elif args.book:
        src_dir = find_src_dir(args.book)
        if not src_dir:
            print(f"Book {args.book} not found"); return
        chapters = sorted(set(
            int(f.stem.split('_')[-1])
            for f in src_dir.iterdir()
            if f.suffix == '.mp3'
        ))
        print(f"Book {args.book}: {len(chapters)} chapters")
        ok = sum(process_chapter(args.book, ch, model, args.dry_run) for ch in chapters)
        print(f"Done: {ok}/{len(chapters)}")
    else:
        # All CUV books
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
