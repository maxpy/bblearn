#!/usr/bin/env python3
"""Bible metadata definitions for KJV and CUV versions.

Contains book names, chapter counts, and abbreviations for both
Old Testament and New Testament.
"""

from dataclasses import dataclass
from typing import Dict, List, Tuple


@dataclass
class BookInfo:
    """Information about a single Bible book."""
    number: int           # 1-66
    name_en: str          # English name (KJV)
    name_zh: str          # Chinese name (CUV)
    abbrev_en: str        # English abbreviation
    abbrev_zh: str        # Chinese abbreviation
    chapters: int         # Number of chapters
    testament: str        # 'OT' or 'NT'


# Complete list of 66 Bible books with metadata
BOOKS: List[BookInfo] = [
    # Old Testament (39 books)
    BookInfo(1,  'Genesis',        '创世记',    'Gen',  '创', 50, 'OT'),
    BookInfo(2,  'Exodus',         '出埃及记',  'Exod', '出', 40, 'OT'),
    BookInfo(3,  'Leviticus',      '利未记',    'Lev',  '利', 27, 'OT'),
    BookInfo(4,  'Numbers',        '民数记',    'Num',  '民', 36, 'OT'),
    BookInfo(5,  'Deuteronomy',    '申命记',    'Deut', '申', 34, 'OT'),
    BookInfo(6,  'Joshua',         '约书亚记',  'Josh', '书', 24, 'OT'),
    BookInfo(7,  'Judges',         '士师记',    'Judg', '士', 21, 'OT'),
    BookInfo(8,  'Ruth',           '路得记',    'Ruth', '得', 4,  'OT'),
    BookInfo(9,  '1 Samuel',       '撒母耳记上','1Sam', '撒上', 31, 'OT'),
    BookInfo(10, '2 Samuel',       '撒母耳记下','2Sam', '撒下', 24, 'OT'),
    BookInfo(11, '1 Kings',        '列王纪上',  '1Kgs', '王上', 22, 'OT'),
    BookInfo(12, '2 Kings',        '列王纪下',  '2Kgs', '王下', 25, 'OT'),
    BookInfo(13, '1 Chronicles',   '历代志上',  '1Chr', '代上', 29, 'OT'),
    BookInfo(14, '2 Chronicles',   '历代志下',  '2Chr', '代下', 36, 'OT'),
    BookInfo(15, 'Ezra',           '以斯拉记',  'Ezra', '拉', 10, 'OT'),
    BookInfo(16, 'Nehemiah',       '尼希米记',  'Neh',  '尼', 13, 'OT'),
    BookInfo(17, 'Esther',         '以斯帖记',  'Esth', '斯', 10, 'OT'),
    BookInfo(18, 'Job',            '约伯记',    'Job',  '伯', 42, 'OT'),
    BookInfo(19, 'Psalms',         '诗篇',      'Ps',   '诗', 150, 'OT'),
    BookInfo(20, 'Proverbs',       '箴言',      'Prov', '箴', 31, 'OT'),
    BookInfo(21, 'Ecclesiastes',   '传道书',    'Eccl', '传', 12, 'OT'),
    BookInfo(22, 'Song of Solomon','雅歌',      'Song', '歌', 8,  'OT'),
    BookInfo(23, 'Isaiah',         '以赛亚书',  'Isa',  '赛', 66, 'OT'),
    BookInfo(24, 'Jeremiah',       '耶利米书',  'Jer',  '耶', 52, 'OT'),
    BookInfo(25, 'Lamentations',   '耶利米哀歌','Lam',  '哀', 5,  'OT'),
    BookInfo(26, 'Ezekiel',        '以西结书',  'Ezek', '结', 48, 'OT'),
    BookInfo(27, 'Daniel',         '但以理书',  'Dan',  '但', 12, 'OT'),
    BookInfo(28, 'Hosea',          '何西阿书',  'Hos',  '何', 14, 'OT'),
    BookInfo(29, 'Joel',           '约珥书',    'Joel', '珥', 3,  'OT'),
    BookInfo(30, 'Amos',           '阿摩司书',  'Amos', '摩', 9,  'OT'),
    BookInfo(31, 'Obadiah',        '俄巴底亚书','Obad', '俄', 1,  'OT'),
    BookInfo(32, 'Jonah',          '约拿书',    'Jonah','拿', 4,  'OT'),
    BookInfo(33, 'Micah',          '弥迦书',    'Mic',  '弥', 7,  'OT'),
    BookInfo(34, 'Nahum',          '那鸿书',    'Nah',  '鸿', 3,  'OT'),
    BookInfo(35, 'Habakkuk',       '哈巴谷书',  'Hab',  '哈', 3,  'OT'),
    BookInfo(36, 'Zephaniah',      '西番雅书',  'Zeph', '番', 3,  'OT'),
    BookInfo(37, 'Haggai',         '哈该书',    'Hag',  '该', 2,  'OT'),
    BookInfo(38, 'Zechariah',      '撒迦利亚书','Zech', '亚', 14, 'OT'),
    BookInfo(39, 'Malachi',        '玛拉基书',  'Mal',  '玛', 4,  'OT'),
    # New Testament (27 books)
    BookInfo(40, 'Matthew',        '马太福音',  'Matt', '太', 28, 'NT'),
    BookInfo(41, 'Mark',           '马可福音',  'Mark', '可', 16, 'NT'),
    BookInfo(42, 'Luke',           '路加福音',  'Luke', '路', 24, 'NT'),
    BookInfo(43, 'John',           '约翰福音',  'John', '约', 21, 'NT'),
    BookInfo(44, 'Acts',           '使徒行传',  'Acts', '徒', 28, 'NT'),
    BookInfo(45, 'Romans',         '罗马书',    'Rom',  '罗', 16, 'NT'),
    BookInfo(46, '1 Corinthians',  '哥林多前书','1Cor', '林前', 16, 'NT'),
    BookInfo(47, '2 Corinthians',  '哥林多后书','2Cor', '林后', 13, 'NT'),
    BookInfo(48, 'Galatians',      '加拉太书',  'Gal',  '加', 6,  'NT'),
    BookInfo(49, 'Ephesians',      '以弗所书',  'Eph',  '弗', 6,  'NT'),
    BookInfo(50, 'Philippians',    '腓立比书',  'Phil', '腓', 4,  'NT'),
    BookInfo(51, 'Colossians',     '歌罗西书',  'Col',  '西', 4,  'NT'),
    BookInfo(52, '1 Thessalonians','帖撒罗尼迦前书','1Thess','帖前', 5, 'NT'),
    BookInfo(53, '2 Thessalonians','帖撒罗尼迦后书','2Thess','帖后', 3, 'NT'),
    BookInfo(54, '1 Timothy',      '提摩太前书','1Tim', '提前', 6, 'NT'),
    BookInfo(55, '2 Timothy',      '提摩太后书','2Tim', '提后', 4, 'NT'),
    BookInfo(56, 'Titus',          '提多书',    'Titus','多', 3,  'NT'),
    BookInfo(57, 'Philemon',       '腓利门书',  'Phlm', '门', 1,  'NT'),
    BookInfo(58, 'Hebrews',        '希伯来书',  'Heb',  '来', 13, 'NT'),
    BookInfo(59, 'James',          '雅各书',    'Jas',  '雅', 5,  'NT'),
    BookInfo(60, '1 Peter',        '彼得前书',  '1Pet', '彼前', 5, 'NT'),
    BookInfo(61, '2 Peter',        '彼得后书',  '2Pet', '彼后', 3, 'NT'),
    BookInfo(62, '1 John',         '约翰一书',  '1John','约壹', 5, 'NT'),
    BookInfo(63, '2 John',         '约翰二书',  '2John','约贰', 1, 'NT'),
    BookInfo(64, '3 John',         '约翰三书',  '3John','约叁', 1, 'NT'),
    BookInfo(65, 'Jude',           '犹大书',    'Jude', '犹', 1,  'NT'),
    BookInfo(66, 'Revelation',     '启示录',    'Rev',  '启', 22, 'NT'),
]


def get_book_by_number(number: int) -> BookInfo:
    """Look up a book by its canonical number (1-66)."""
    for book in BOOKS:
        if book.number == number:
            return book
    raise ValueError(f'No book with number {number}')


def get_book_by_abbrev(abbrev: str) -> BookInfo:
    """Look up a book by English abbreviation."""
    for book in BOOKS:
        if book.abbrev_en.lower() == abbrev.lower():
            return book
    raise ValueError(f'No book with abbreviation {abbrev}')


def get_ot_books() -> List[BookInfo]:
    """Return all Old Testament books."""
    return [b for b in BOOKS if b.testament == 'OT']


def get_nt_books() -> List[BookInfo]:
    """Return all New Testament books."""
    return [b for b in BOOKS if b.testament == 'NT']


def get_book_dir(book: BookInfo) -> str:
    """Return the directory name for a book, e.g. '01_Gen'."""
    return f'{book.number:02d}_{book.abbrev_en}'


def total_chapters() -> int:
    """Return the total number of chapters in the Bible."""
    return sum(b.chapters for b in BOOKS)


if __name__ == '__main__':
    print(f'Total books: {len(BOOKS)}')
    print(f'OT books: {len(get_ot_books())}')
    print(f'NT books: {len(get_nt_books())}')
    print(f'Total chapters: {total_chapters()}')
