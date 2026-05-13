#!/usr/bin/env python3
"""
下载圣经经文文本 (KJV + CUV)
来源: bolls.life API (免费, 无需 API Key)
输出: 每章一个 JSON 文件, 与音频同目录
"""

import os
import sys
import json
import time
import re
import urllib.request
from pathlib import Path

PROXY = "http://127.0.0.1:7897"
proxy_handler = urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY})
opener = urllib.request.build_opener(proxy_handler)
urllib.request.install_opener(opener)

BASE_DIR = Path.home() / "bible-audio"

BOOKS = [
    (1, "Genesis", "创世记", 50, "OT"),
    (2, "Exodus", "出埃及记", 40, "OT"),
    (3, "Leviticus", "利未记", 27, "OT"),
    (4, "Numbers", "民数记", 36, "OT"),
    (5, "Deuteronomy", "申命记", 34, "OT"),
    (6, "Joshua", "约书亚记", 24, "OT"),
    (7, "Judges", "士师记", 21, "OT"),
    (8, "Ruth", "路得记", 4, "OT"),
    (9, "1Samuel", "撒母耳记上", 31, "OT"),
    (10, "2Samuel", "撒母耳记下", 24, "OT"),
    (11, "1Kings", "列王纪上", 22, "OT"),
    (12, "2Kings", "列王纪下", 25, "OT"),
    (13, "1Chronicles", "历代志上", 29, "OT"),
    (14, "2Chronicles", "历代志下", 36, "OT"),
    (15, "Ezra", "以斯拉记", 10, "OT"),
    (16, "Nehemiah", "尼希米记", 13, "OT"),
    (17, "Esther", "以斯帖记", 10, "OT"),
    (18, "Job", "约伯记", 42, "OT"),
    (19, "Psalms", "诗篇", 150, "OT"),
    (20, "Proverbs", "箴言", 31, "OT"),
    (21, "Ecclesiastes", "传道书", 12, "OT"),
    (22, "SongOfSolomon", "雅歌", 8, "OT"),
    (23, "Isaiah", "以赛亚书", 66, "OT"),
    (24, "Jeremiah", "耶利米书", 52, "OT"),
    (25, "Lamentations", "耶利米哀歌", 5, "OT"),
    (26, "Ezekiel", "以西结书", 48, "OT"),
    (27, "Daniel", "但以理书", 12, "OT"),
    (28, "Hosea", "何西阿书", 14, "OT"),
    (29, "Joel", "约珥书", 3, "OT"),
    (30, "Amos", "阿摩司书", 9, "OT"),
    (31, "Obadiah", "俄巴底亚书", 1, "OT"),
    (32, "Jonah", "约拿书", 4, "OT"),
    (33, "Micah", "弥迦书", 7, "OT"),
    (34, "Nahum", "那鸿书", 3, "OT"),
    (35, "Habakkuk", "哈巴谷书", 3, "OT"),
    (36, "Zephaniah", "西番雅书", 3, "OT"),
    (37, "Haggai", "哈该书", 2, "OT"),
    (38, "Zechariah", "撒迦利亚书", 14, "OT"),
    (39, "Malachi", "玛拉基书", 4, "OT"),
    (40, "Matthew", "马太福音", 28, "NT"),
    (41, "Mark", "马可福音", 16, "NT"),
    (42, "Luke", "路加福音", 24, "NT"),
    (43, "John", "约翰福音", 21, "NT"),
    (44, "Acts", "使徒行传", 28, "NT"),
    (45, "Romans", "罗马书", 16, "NT"),
    (46, "1Corinthians", "哥林多前书", 16, "NT"),
    (47, "2Corinthians", "哥林多后书", 13, "NT"),
    (48, "Galatians", "加拉太书", 6, "NT"),
    (49, "Ephesians", "以弗所书", 6, "NT"),
    (50, "Philippians", "腓立比书", 4, "NT"),
    (51, "Colossians", "歌罗西书", 4, "NT"),
    (52, "1Thessalonians", "帖撒罗尼迦前书", 5, "NT"),
    (53, "2Thessalonians", "帖撒罗尼迦后书", 3, "NT"),
    (54, "1Timothy", "提摩太前书", 6, "NT"),
    (55, "2Timothy", "提摩太后书", 4, "NT"),
    (56, "Titus", "提多书", 3, "NT"),
    (57, "Philemon", "腓利门书", 1, "NT"),
    (58, "Hebrews", "希伯来书", 13, "NT"),
    (59, "James", "雅各书", 5, "NT"),
    (60, "1Peter", "彼得前书", 5, "NT"),
    (61, "2Peter", "彼得后书", 3, "NT"),
    (62, "1John", "约翰一书", 5, "NT"),
    (63, "2John", "约翰二书", 1, "NT"),
    (64, "3John", "约翰三书", 1, "NT"),
    (65, "Jude", "犹大书", 1, "NT"),
    (66, "Revelation", "启示录", 22, "NT"),
]


def clean_text(text):
    """清理 bolls.life 返回的文本 (去除 Strong's 编号等标记)"""
    text = re.sub(r'<S>\d+</S>', '', text)
    text = re.sub(r'<sup>.*?</sup>', '', text)
    text = re.sub(r'<.*?>', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def fetch_chapter(translation, book_id, chapter, retries=3):
    """从 bolls.life 获取一章经文"""
    url = f"https://bolls.life/get-chapter/{translation}/{book_id}/{chapter}/"
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read())
            verses = []
            for v in data:
                verses.append({
                    "verse": v["verse"],
                    "text": clean_text(v["text"])
                })
            return verses
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1 + attempt)
            else:
                raise e


def download_version(version, translation):
    """下载一个版本的所有经文"""
    print(f"\n{'='*60}")
    print(f"下载 {version} 经文文本 (bolls.life/{translation})")
    print(f"{'='*60}")

    from concurrent.futures import ThreadPoolExecutor, as_completed
    import threading

    total = sum(ch for _, _, _, ch, _ in BOOKS)
    done = 0
    skipped = 0
    errors = 0
    lock = threading.Lock()

    def download_one(book_num, en_name, cn_name, ch, testament):
        name = en_name if version == "KJV" else cn_name
        book_dir = BASE_DIR / version / testament / f"{book_num:02d}_{name}"
        text_file = book_dir / f"{book_num:02d}_{name}_{ch:03d}.txt.json"

        if text_file.exists() and text_file.stat().st_size > 10:
            return "skip"

        try:
            verses = fetch_chapter(translation, book_num, ch)
            text_file.parent.mkdir(parents=True, exist_ok=True)
            with open(text_file, 'w', encoding='utf-8') as f:
                json.dump({
                    "book": book_num,
                    "book_name": name,
                    "chapter": ch,
                    "verses": verses,
                    "full_text": " ".join(v["text"] for v in verses)
                }, f, ensure_ascii=False, indent=2)
            return "ok"
        except Exception as e:
            return f"error: {e}"

    tasks = []
    for book_num, en_name, cn_name, chapters, testament in BOOKS:
        for ch in range(1, chapters + 1):
            tasks.append((book_num, en_name, cn_name, ch, testament))

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {}
        for args in tasks:
            f = executor.submit(download_one, *args)
            futures[f] = args

        for f in as_completed(futures):
            result = f.result()
            if result == "skip":
                skipped += 1
            elif result == "ok":
                pass
            else:
                errors += 1
                args = futures[f]
                print(f"  [ERROR] book={args[0]} ch={args[3]}: {result}")
            done += 1
            if done % 100 == 0:
                print(f"  进度: {done}/{total} (跳过:{skipped} 错误:{errors})")

    print(f"\n{version} 完成: 总计={done} 跳过={skipped} 错误={errors}")


def main():
    version = sys.argv[1] if len(sys.argv) > 1 else "all"

    if version in ("kjv", "all"):
        download_version("KJV", "KJV")

    if version in ("cuv", "all"):
        download_version("CUV", "CUNPS")

    print("\n经文文本下载完成!")
    print("文件格式: {book}_{chapter}.txt.json")
    print("每个文件包含: book, chapter, verses[{verse, text}], full_text")


if __name__ == "__main__":
    main()
