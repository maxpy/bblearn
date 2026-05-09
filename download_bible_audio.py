#!/usr/bin/env python3
"""
圣经多版本音频下载器
从 archive.org 下载 KJV / CUV 圣经音频，统一命名格式

命名规范:
  {version}/{testament}/{book_num}_{book_name}/{book_num}_{book_name}_{chapter:03d}.mp3
  例: KJV/OT/01_Genesis/01_Genesis_001.mp3
      CUV/OT/01_创世记/01_创世记_001.mp3
"""

import os
import sys
import json
import urllib.request
import urllib.parse
import time
import re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# 代理设置
PROXY = "http://127.0.0.1:7897"
proxy_handler = urllib.request.ProxyHandler({
    'http': PROXY,
    'https': PROXY,
})
opener = urllib.request.build_opener(proxy_handler)
urllib.request.install_opener(opener)

BASE_DIR = Path.home() / "bible-audio"

# 圣经66卷书信息: (书号, 英文名, 中文名, 章数, 约)
BOOKS = [
    # 旧约 39 卷
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
    # 新约 27 卷
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

# KJV 文件名映射 (archive.org: kjvaudionondrama)
# 格式: A{book:02d}___{chapter:02d}_{BookName}_____ENGKJVO1DA.mp3 (OT)
#        B{book_nt:02d}___{chapter:02d}_{BookName}_____ENGKJVN1DA.mp3 (NT)
KJV_BOOK_NAMES = {
    1: "Genesis", 2: "Exodus", 3: "Leviticus", 4: "Numbers", 5: "Deuteronomy",
    6: "Joshua", 7: "Judges", 8: "Ruth", 9: "1Samuel", 10: "2Samuel",
    11: "1Kings", 12: "2Kings", 13: "1Chronicles", 14: "2Chronicles",
    15: "Ezra", 16: "Nehemiah", 17: "Esther", 18: "Job", 19: "Psalms",
    20: "Proverbs", 21: "Ecclesiastes",    22: "SongofSongs", 23: "Isaiah",
    24: "Jeremiah", 25: "Lamentations", 26: "Ezekiel", 27: "Daniel",
    28: "Hosea", 29: "Joel", 30: "Amos", 31: "Obadiah", 32: "Jonah",
    33: "Micah", 34: "Nahum", 35: "Habakkuk", 36: "Zephaniah", 37: "Haggai",
    38: "Zechariah", 39: "Malachi",
    40: "Matthew", 41: "Mark", 42: "Luke", 43: "John", 44: "Acts",
    45: "Romans", 46: "1Corinthians", 47: "2Corinthians", 48: "Galatians",
    49: "Ephesians", 50: "Philippians", 51: "Colossians",
    52: "1Thess", 53: "2Thess", 54: "1Timothy", 55: "2Timothy",
    56: "Titus", 57: "Philemon", 58: "Hebrews", 59: "James",
    60: "1Peter", 61: "2Peter", 62: "1John", 63: "2John", 64: "3John",
    65: "Jude", 66: "Revelation",
}


def get_archive_file_list(identifier):
    """获取 archive.org 集合的文件列表"""
    url = f"https://archive.org/metadata/{identifier}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read())
    return {f['name']: f for f in data.get('files', []) if f['name'].endswith('.mp3')}


def download_file(url, dest, retries=3):
    """下载文件，支持重试"""
    if dest.exists() and dest.stat().st_size > 1000:
        return "skip"
    dest.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                with open(dest, 'wb') as f:
                    while True:
                        chunk = resp.read(8192)
                        if not chunk:
                            break
                        f.write(chunk)
            return "ok"
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                return f"error: {e}"


def build_kjv_tasks(file_list):
    """构建 KJV 下载任务列表"""
    tasks = []
    for book_num, en_name, cn_name, chapters, testament in BOOKS:
        for ch in range(1, chapters + 1):
            # 构建 archive.org 文件名
            if testament == "OT":
                prefix = "A"
                book_idx = book_num
                suffix = "ENGKJVO1DA"
            else:
                prefix = "B"
                book_idx = book_num - 39
                suffix = "ENGKJVN1DA"

            kjv_name = KJV_BOOK_NAMES[book_num]

            # 在文件列表中模糊匹配 - 支持2位和3位章节号
            # 格式: A19___01_ (2位) 或 A19__100_ (3位)
            matched = None
            for fname in file_list:
                # 匹配 book prefix + chapter number + book name
                patterns = [
                    f"{prefix}{book_idx:02d}___{ch:02d}_{kjv_name}",   # 2位章节: ___01_
                    f"{prefix}{book_idx:02d}__{ch:03d}_{kjv_name}",    # 3位章节: __100_
                ]
                for pat in patterns:
                    if fname.startswith(pat):
                        matched = fname
                        break
                if matched:
                    break

            if not matched:
                print(f"  [WARN] KJV not found: book={book_num} ch={ch} name={kjv_name}")
                continue

            url = f"https://archive.org/download/kjvaudionondrama/{urllib.parse.quote(matched)}"
            dest = BASE_DIR / "KJV" / testament / f"{book_num:02d}_{en_name}" / f"{book_num:02d}_{en_name}_{ch:03d}.mp3"
            tasks.append((url, dest, f"KJV {en_name} {ch}"))
    return tasks


def build_cuv_tasks(file_list):
    """构建 CUV 下载任务列表"""
    tasks = []
    for book_num, en_name, cn_name, chapters, testament in BOOKS:
        for ch in range(1, chapters + 1):
            src_name = f"CUV_B{book_num:02d}C{ch:03d}.mp3"
            if src_name not in file_list:
                print(f"  [WARN] CUV not found: {src_name}")
                continue
            url = f"https://archive.org/download/CUV_201910/{urllib.parse.quote(src_name)}"
            dest = BASE_DIR / "CUV" / testament / f"{book_num:02d}_{cn_name}" / f"{book_num:02d}_{cn_name}_{ch:03d}.mp3"
            tasks.append((url, dest, f"CUV {cn_name} {ch}"))
    return tasks


def download_version(version, identifier, build_func):
    """下载一个版本的所有音频"""
    print(f"\n{'='*60}")
    print(f"下载 {version} 音频 (archive.org/{identifier})")
    print(f"{'='*60}")

    print("获取文件列表...")
    file_list = get_archive_file_list(identifier)
    print(f"  找到 {len(file_list)} 个 MP3 文件")

    tasks = build_func(file_list)
    print(f"  构建 {len(tasks)} 个下载任务")

    downloaded = 0
    skipped = 0
    errors = 0

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {}
        for url, dest, label in tasks:
            f = executor.submit(download_file, url, dest)
            futures[f] = label

        for f in as_completed(futures):
            label = futures[f]
            result = f.result()
            if result == "ok":
                downloaded += 1
            elif result == "skip":
                skipped += 1
            else:
                errors += 1
                print(f"  [ERROR] {label}: {result}")

            total = downloaded + skipped + errors
            if total % 50 == 0:
                print(f"  进度: {total}/{len(tasks)} (下载:{downloaded} 跳过:{skipped} 错误:{errors})")

    print(f"\n{version} 完成: 下载={downloaded} 跳过={skipped} 错误={errors}")
    return downloaded, skipped, errors


def generate_metadata():
    """生成元数据 JSON"""
    metadata = {
        "versions": {
            "KJV": {
                "name": "King James Version",
                "language": "en",
                "source": "archive.org/details/kjvaudionondrama",
                "narrator": "Faith Comes By Hearing",
                "license": "Public Domain"
            },
            "CUV": {
                "name": "Chinese Union Version (和合本)",
                "language": "zh",
                "source": "archive.org/details/CUV_201910",
                "narrator": "Unknown",
                "license": "Public Domain"
            }
        },
        "books": [],
        "naming": "{version}/{testament}/{book_num}_{book_name}/{book_num}_{book_name}_{chapter:03d}.mp3"
    }
    for book_num, en_name, cn_name, chapters, testament in BOOKS:
        metadata["books"].append({
            "number": book_num,
            "name_en": en_name,
            "name_zh": cn_name,
            "chapters": chapters,
            "testament": testament
        })

    meta_path = BASE_DIR / "metadata.json"
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    print(f"\n元数据已保存: {meta_path}")


def main():
    version = sys.argv[1] if len(sys.argv) > 1 else "all"

    if version in ("kjv", "all"):
        download_version("KJV", "kjvaudionondrama", build_kjv_tasks)

    if version in ("cuv", "all"):
        download_version("CUV", "CUV_201910", build_cuv_tasks)

    generate_metadata()
    print("\n全部完成!")
    print(f"音频目录: {BASE_DIR}")
    print("目录结构:")
    print("  bible-audio/")
    print("    KJV/OT/01_Genesis/01_Genesis_001.mp3")
    print("    KJV/NT/40_Matthew/40_Matthew_001.mp3")
    print("    CUV/OT/01_创世记/01_创世记_001.mp3")
    print("    CUV/NT/40_马太福音/40_马太福音_001.mp3")
    print("    metadata.json")


if __name__ == "__main__":
    main()
