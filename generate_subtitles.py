#!/usr/bin/env python3
"""
圣经音频字幕生成器
策略: 使用 Whisper 转录 + 经文文本对齐, 生成精确的经节级字幕

输出:
  - .srt  标准字幕文件 (播放器兼容)
  - .json 结构化数据 (含经节编号和时间戳, 适合 App 开发)

用法:
  python3 generate_subtitles.py KJV --model base
  python3 generate_subtitles.py CUV --model small
  python3 generate_subtitles.py all --model base
"""

import os
import sys
import json
import argparse
import re
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path.home() / "bible-audio"


def format_srt_time(seconds):
    """秒 -> SRT 时间格式 HH:MM:SS,mmm"""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds % 1) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def load_verse_text(mp3_path):
    """加载对应的经文文本"""
    text_file = mp3_path.with_suffix('.txt.json')
    if text_file.exists():
        with open(text_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None


def transcribe_with_whisper(mp3_path, model, language):
    """用 Whisper 转录音频, 获取带时间戳的 segments"""
    result = model.transcribe(
        str(mp3_path),
        language=language,
        word_timestamps=True,
        verbose=False,
    )
    return result


def align_verses_to_segments(verses, segments):
    """
    将经节文本对齐到 Whisper 转录的 segments
    策略: 按文本相似度和时间顺序匹配经节边界
    """
    if not segments or not verses:
        return []

    # 收集所有 word-level timestamps
    words = []
    for seg in segments:
        if 'words' in seg:
            for w in seg['words']:
                word_text = w.get('word', w.get('text', '')).strip()
                if word_text:
                    words.append({
                        'text': word_text,
                        'start': w['start'],
                        'end': w['end'],
                    })

    if not words:
        # 没有词级时间戳, 退回到 segment 级别
        return align_verses_to_segments_fallback(verses, segments)

    # 将所有 words 拼成完整转录文本
    full_transcript = ' '.join(w['text'] for w in words).lower()
    full_transcript_clean = re.sub(r'[^\w\s]', '', full_transcript)

    # 按经节数量均分 words (简单但有效的启发式)
    total_words = len(words)
    verse_count = len(verses)

    # 计算每个经节的大致 word 数量 (按经文长度比例分配)
    verse_lengths = [len(v['text'].split()) for v in verses]
    total_verse_words = sum(verse_lengths) or 1

    aligned = []
    word_idx = 0

    for i, verse in enumerate(verses):
        # 按比例分配 words
        proportion = verse_lengths[i] / total_verse_words
        n_words = max(1, round(proportion * total_words))

        # 最后一个经节拿剩余所有
        if i == verse_count - 1:
            n_words = total_words - word_idx

        start_idx = word_idx
        end_idx = min(word_idx + n_words, total_words)

        if start_idx < total_words:
            start_time = words[start_idx]['start']
            end_time = words[min(end_idx - 1, total_words - 1)]['end']

            aligned.append({
                'verse': verse['verse'],
                'text': verse['text'],
                'start': round(start_time, 3),
                'end': round(end_time, 3),
            })

        word_idx = end_idx

    return aligned


def align_verses_to_segments_fallback(verses, segments):
    """退回方案: 按 segment 时间均分经节"""
    if not segments:
        return []

    total_duration = segments[-1]['end']
    verse_count = len(verses)
    verse_lengths = [len(v['text']) for v in verses]
    total_len = sum(verse_lengths) or 1

    aligned = []
    current_time = segments[0]['start']

    for i, verse in enumerate(verses):
        proportion = verse_lengths[i] / total_len
        duration = proportion * total_duration
        start = current_time
        end = current_time + duration

        aligned.append({
            'verse': verse['verse'],
            'text': verse['text'],
            'start': round(start, 3),
            'end': round(end, 3),
        })
        current_time = end

    return aligned


def generate_subtitle_files(mp3_path, aligned_verses, language):
    """生成 SRT 和 JSON 字幕文件"""
    srt_path = mp3_path.with_suffix('.srt')
    json_path = mp3_path.with_suffix('.subtitle.json')

    # SRT
    srt_lines = []
    for i, v in enumerate(aligned_verses, 1):
        start = format_srt_time(v['start'])
        end = format_srt_time(v['end'])
        # SRT 中显示经节号
        text = f"[{v['verse']}] {v['text']}"
        srt_lines.extend([str(i), f"{start} --> {end}", text, ""])

    with open(srt_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(srt_lines))

    # JSON
    json_data = {
        'audio': mp3_path.name,
        'language': language,
        'duration': aligned_verses[-1]['end'] if aligned_verses else 0,
        'verse_count': len(aligned_verses),
        'verses': aligned_verses,
    }
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(json_data, f, ensure_ascii=False, indent=2)

    return srt_path, json_path


def process_version(version_dir, model, language, version_name):
    """处理一个版本的所有音频"""
    mp3_files = sorted(version_dir.rglob("*.mp3"))
    total = len(mp3_files)
    print(f"\n处理 {version_name}: {total} 个文件 (语言: {language})")

    done = 0
    skipped = 0
    errors = 0
    no_text = 0

    for mp3 in mp3_files:
        srt = mp3.with_suffix('.srt')
        if srt.exists() and srt.stat().st_size > 10:
            skipped += 1
            done += 1
            continue

        try:
            # 加载经文文本
            verse_data = load_verse_text(mp3)

            # Whisper 转录
            result = transcribe_with_whisper(mp3, model, language)

            if verse_data and verse_data.get('verses'):
                # 有经文文本: 对齐经节到时间戳
                aligned = align_verses_to_segments(
                    verse_data['verses'],
                    result['segments']
                )
            else:
                # 无经文文本: 直接用 Whisper segments
                no_text += 1
                aligned = []
                for seg in result['segments']:
                    aligned.append({
                        'verse': 0,
                        'text': seg['text'].strip(),
                        'start': round(seg['start'], 3),
                        'end': round(seg['end'], 3),
                    })

            generate_subtitle_files(mp3, aligned, language)
            done += 1

            if done % 20 == 0:
                print(f"  进度: {done}/{total} (跳过:{skipped} 无文本:{no_text} 错误:{errors})")

        except Exception as e:
            errors += 1
            done += 1
            print(f"  [ERROR] {mp3.name}: {e}")

    print(f"  完成: {done}/{total} (跳过:{skipped} 无文本:{no_text} 错误:{errors})")


def main():
    parser = argparse.ArgumentParser(description="圣经音频字幕生成")
    parser.add_argument("version", nargs="?", default="all", help="KJV, CUV, all")
    parser.add_argument("--model", default="base", help="Whisper 模型: tiny, base, small, medium, large")
    args = parser.parse_args()

    print(f"加载 Whisper 模型: {args.model}")
    import whisper
    model = whisper.load_model(args.model)
    print("模型加载完成")

    versions = {
        "KJV": ("en", BASE_DIR / "KJV"),
        "CUV": ("zh", BASE_DIR / "CUV"),
    }

    targets = list(versions.keys()) if args.version == "all" else [args.version.upper()]

    for v in targets:
        if v in versions:
            lang, vdir = versions[v]
            if vdir.exists():
                process_version(vdir, model, lang, v)
            else:
                print(f"  [SKIP] {v} 目录不存在")

    print("\n字幕生成完成!")
    print("每个 MP3 旁边生成:")
    print("  .srt           - 标准字幕 (含经节号)")
    print("  .subtitle.json - 结构化数据 (经节+时间戳)")


if __name__ == "__main__":
    main()
