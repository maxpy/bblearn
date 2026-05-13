#!/usr/bin/env python3
"""重试韩语圣经失败的文件"""
import subprocess
from pathlib import Path

PROXY = "http://127.0.0.1:7897"
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
ARCHIVE_ID = "bible_Audio_Koreanrnksv"

FAILED = [
    ("genesis",22),("leviticus",19),("judges",1),("1samuel",25),("nehemiah",11),
    ("psalms",10),("psalms",13),("psalms",21),("psalms",61),("psalms",95),
    ("proverbs",11),("isaiah",52),("isaiah",63),("jeremiah",35),("ezekiel",16),
    ("hosea",6),("jonah",1),("micah",6),("micah",7),("zechariah",4),
    # 以下是部分失败文件需要检查
]

BOOK_MAP = {
    "genesis":"창세기","exodus":"출애굽기","leviticus":"레위기","numbers":"민수기",
    "deuteronomy":"신명기","joshua":"여호수아","judges":"사사기","ruth":"룻기",
    "1samuel":"사무엘상","2samuel":"사무엘하","1kings":"열왕기상","2kings":"열왕기하",
    "1chronicles":"역대상","2chronicles":"역대하","ezra":"에스라","nehemiah":"느헤미야",
    "esther":"에스더","job":"욥기","psalms":"시편","proverbs":"잠언",
    "ecclesiastes":"전도서","songofsolomon":"아가","isaiah":"이사야","jeremiah":"예레미야",
    "lamentations":"예레미야애가","ezekiel":"에스겔","daniel":"다니엘","hosea":"호세아",
    "joel":"요엘","amos":"아모스","obadiah":"오바댜","jonah":"요나","micah":"미가",
    "nahum":"나훔","habakkuk":"하박국","zephaniah":"스바냐","haggai":"학개",
    "zechariah":"스가랴","malachi":"말라기","matthew":"마태복음","mark":"마가복음",
    "luke":"누가복음","john":"요한복음","acts":"사도행전","romans":"로마서",
    "1corinthians":"고린도전서","2corinthians":"고린도후서","galatians":"갈라디아서",
    "ephesians":"에베소서","philippians":"빌립보서","colossians":"골로새서",
    "1thessalonians":"데살로니가전서","2thessalonians":"데살로니가후서","1timothy":"디모데전서",
    "2timothy":"디모데후서","titus":"디도서","philemon":"빌레몬서","hebrews":"히브리서",
    "james":"야고보서","1peter":"베드로전서","2peter":"베드로후서","1john":"요한일서",
    "2john":"요한이서","3john":"요한삼서","jude":"유다서","revelation":"요한계시록",
}

OT_BOOKS = {"genesis","exodus","leviticus","numbers","deuteronomy","joshua","judges","ruth",
            "1samuel","2samuel","1kings","2kings","1chronicles","2chronicles","ezra",
            "nehemiah","esther","job","psalms","proverbs","ecclesiastes","songofsolomon",
            "isaiah","jeremiah","lamentations","ezekiel","daniel","hosea","joel","amos",
            "obadiah","jonah","micah","nahum","habakkuk","zephaniah","haggai","zechariah","malachi"}

BOOK_NUMS = {name: num for num, (_, name, _, _, _) in [
    (1,"genesis"),(2,"exodus"),(3,"leviticus"),(4,"numbers"),(5,"deuteronomy"),
    (6,"joshua"),(7,"judges"),(8,"ruth"),(9,"1samuel"),(10,"2samuel"),
    (11,"1kings"),(12,"2kings"),(13,"1chronicles"),(14,"2chronicles"),(15,"ezra"),
    (16,"nehemiah"),(17,"esther"),(18,"job"),(19,"psalms"),(20,"proverbs"),
    (21,"ecclesiastes"),(22,"songofsolomon"),(23,"isaiah"),(24,"jeremiah"),(25,"lamentations"),
    (26,"ezekiel"),(27,"daniel"),(28,"hosea"),(29,"joel"),(30,"amos"),
    (31,"obadiah"),(32,"jonah"),(33,"micah"),(34,"nahum"),(35,"habakkuk"),
    (36,"zephaniah"),(37,"haggai"),(38,"zechariah"),(39,"malachi"),
    (40,"matthew"),(41,"mark"),(42,"luke"),(43,"john"),(44,"acts"),
    (45,"romans"),(46,"1corinthians"),(47,"2corinthians"),(48,"galatians"),
    (49,"ephesians"),(50,"philippians"),(51,"colossians"),(52,"1thessalonians"),
    (53,"2thessalonians"),(54,"1timothy"),(55,"2timothy"),(56,"titus"),
    (57,"philemon"),(58,"hebrews"),(59,"james"),(60,"1peter"),(61,"2peter"),
    (62,"1john"),(63,"2john"),(64,"3john"),(65,"jude"),(66,"revelation"),
]}

def get_dest(book_key, chapter):
    testament = "OT" if book_key in OT_BOOKS else "NT"
    book_num = BOOK_NUMS[book_key]
    book_name = BOOK_MAP[book_key]
    audio_dir = Path(f"app/bible_player/assets/audio/KOR/{testament}/{book_num:02d}_{book_name}")
    return audio_dir / f"{book_num:02d}_{book_name}_{chapter:03d}.mp3"

# 重新检查失败的文件是否在archive.org存在
print("检查失败文件是否在archive.org存在...")
for book_key, chapter in FAILED:
    dest = get_dest(book_key, chapter)
    url = f"https://archive.org/download/{ARCHIVE_ID}/{book_key}/{chapter:03d}.mp3"
    cmd = ["curl", "-s", "--proxy", PROXY, "-I", "-A", UA, "--max-time", "10", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    exists = "200" in result.stdout or "301" in result.stdout or "302" in result.stdout
    status = "存在" if exists else "不存在"
    print(f"  {book_key} {chapter:03d}: {status} -> {dest.name}")
