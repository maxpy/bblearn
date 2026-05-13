#!/usr/bin/env python3
"""
韩语圣经下载脚本 - 使用并行curl下载
"""
import os
import sys
import json
import subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import time

PROXY = "http://127.0.0.1:7897"
ARCHIVE_ID = "bible_Audio_Koreanrnksv"
ASSETS_DIR = Path("app/bible_player/assets")
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

KOREAN_BOOKS = [
    ("genesis","창세기",1,50,"OT"),("exodus","출애굽기",2,40,"OT"),
    ("leviticus","레위기",3,27,"OT"),("numbers","민수기",4,36,"OT"),
    ("deuteronomy","신명기",5,34,"OT"),("joshua","여호수아",6,24,"OT"),
    ("judges","사사기",7,21,"OT"),("ruth","룻기",8,4,"OT"),
    ("1samuel","사무엘상",9,31,"OT"),("2samuel","사무엘하",10,24,"OT"),
    ("1kings","열왕기상",11,22,"OT"),("2kings","열왕기하",12,25,"OT"),
    ("1chronicles","역대상",13,29,"OT"),("2chronicles","역대하",14,36,"OT"),
    ("ezra","에스라",15,10,"OT"),("nehemiah","느헤미야",16,13,"OT"),
    ("esther","에스더",17,10,"OT"),("job","욥기",18,42,"OT"),
    ("psalms","시편",19,100,"OT"),("proverbs","잠언",20,31,"OT"),
    ("ecclesiastes","전도서",21,12,"OT"),("songofsolomon","아가",22,8,"OT"),
    ("isaiah","이사야",23,66,"OT"),("jeremiah","예레미야",24,52,"OT"),
    ("lamentations","예레미야애가",25,5,"OT"),("ezekiel","에스겔",26,48,"OT"),
    ("daniel","다니엘",27,12,"OT"),("hosea","호세아",28,14,"OT"),
    ("joel","요엘",29,3,"OT"),("amos","아모스",30,9,"OT"),
    ("obadiah","오바댜",31,1,"OT"),("jonah","요나",32,4,"OT"),
    ("micah","미가",33,7,"OT"),("nahum","나훔",34,3,"OT"),
    ("habakkuk","하박국",35,3,"OT"),("zephaniah","스바냐",36,3,"OT"),
    ("haggai","학개",37,2,"OT"),("zechariah","스가랴",38,14,"OT"),
    ("malachi","말라기",39,4,"OT"),
    ("matthew","마태복음",40,28,"NT"),("mark","마가복음",41,16,"NT"),
    ("luke","누가복음",42,24,"NT"),("john","요한복음",43,21,"NT"),
    ("acts","사도행전",44,28,"NT"),("romans","로마서",45,16,"NT"),
    ("1corinthians","고린도전서",46,16,"NT"),("2corinthians","고린도후서",47,13,"NT"),
    ("galatians","갈라디아서",48,6,"NT"),("ephesians","에베소서",49,6,"NT"),
    ("philippians","빌립보서",50,4,"NT"),("colossians","골로새서",51,4,"NT"),
    ("1thessalonians","데살로니가전서",52,5,"NT"),("2thessalonians","데살로니가후서",53,3,"NT"),
    ("1timothy","디모데전서",54,6,"NT"),("2timothy","디모데후서",55,4,"NT"),
    ("titus","디도서",56,3,"NT"),("philemon","빌레몬서",57,1,"NT"),
    ("hebrews","히브리서",58,13,"NT"),("james","야고보서",59,5,"NT"),
    ("1peter","베드로전서",60,5,"NT"),("2peter","베드로후서",61,3,"NT"),
    ("1john","요한일서",62,5,"NT"),("2john","요한이서",63,1,"NT"),
    ("3john","요한삼서",64,1,"NT"),("jude","유다서",65,1,"NT"),
    ("revelation","요한계시록",66,22,"NT"),
]

def curl_download(url, dest, timeout=60):
    """使用curl下载文件"""
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        return True
    cmd = [
        "curl", "-s", "--proxy", PROXY,
        "-L", "-A", UA,
        "-o", str(dest), "--max-time", str(timeout), url
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, timeout=timeout + 10)
        return dest.exists() and dest.stat().st_size > 1000
    except subprocess.TimeoutExpired:
        if dest.exists():
            dest.unlink()
        return False
    except Exception:
        return False


def download_worker(book_key, book_name_ko, book_num, chapter, testament):
    """下载单个音频文件的工作函数"""
    archive_name = f"{book_key}/{chapter:03d}.mp3"
    url = f"https://archive.org/download/{ARCHIVE_ID}/{archive_name}"
    audio_dir = ASSETS_DIR / "audio" / "KOR" / testament / f"{book_num:02d}_{book_name_ko}"
    dest = audio_dir / f"{book_num:02d}_{book_name_ko}_{chapter:03d}.mp3"

    ok = curl_download(url, dest)
    return book_key, chapter, ok


def main():
    print("韩语圣经音频下载")
    print("=" * 50)

    # 构建下载任务列表
    tasks = []
    for book_key, book_name_ko, book_num, num_chapters, testament in KOREAN_BOOKS:
        for ch in range(1, num_chapters + 1):
            tasks.append((book_key, book_name_ko, book_num, ch, testament))

    print(f"总任务数: {len(tasks)}")
    print("使用5个并行线程下载...")

    downloaded = 0
    failed = []
    lock_count = 0

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(download_worker, *t): t for t in tasks}

        for future in as_completed(futures):
            book_key, chapter, ok = future.result()
            if ok:
                downloaded += 1
            else:
                failed.append((book_key, chapter))

            lock_count += 1
            if lock_count % 50 == 0:
                print(f"  进度: {lock_count}/{len(tasks)} (成功:{downloaded} 失败:{len(failed)})")

    print(f"\n完成! 成功: {downloaded}, 失败: {len(failed)}")
    if failed:
        print(f"失败任务(前20): {failed[:20]}")

    # 生成pubspec条目
    print("\n=== pubspec.yaml 资产配置 ===")
    entries = []
    for testament in ["OT", "NT"]:
        base = ASSETS_DIR / "audio" / "KOR" / testament
        if base.exists():
            for book_dir in sorted(base.iterdir()):
                if book_dir.is_dir():
                    entries.append(f"    - assets/audio/KOR/{testament}/{book_dir.name}/")
    for e in entries[:5]:
        print(e)
    print(f"  ... 共 {len(entries)} 个音频目录")

    text_entries = []
    for testament in ["OT", "NT"]:
        base = ASSETS_DIR / "text" / "KOR" / testament
        if base.exists():
            for book_dir in sorted(base.iterdir()):
                if book_dir.is_dir():
                    text_entries.append(f"    - assets/text/KOR/{testament}/{book_dir.name}/")
    print(f"  共 {len(text_entries)} 个文本目录(如已有文本)")

if __name__ == "__main__":
    main()
