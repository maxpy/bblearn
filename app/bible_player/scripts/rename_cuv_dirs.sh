#!/bin/bash
# Rename CUV asset directories from Chinese names to English names
# e.g. assets/audio/CUV/OT/01_创世记 → assets/audio/CUV/OT/01_Genesis

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$SCRIPT_DIR/.."

# Book number → English name mapping (66 books)
declare -a BOOKS=(
  "Genesis" "Exodus" "Leviticus" "Numbers" "Deuteronomy"
  "Joshua" "Judges" "Ruth" "1_Samuel" "2_Samuel"
  "1_Kings" "2_Kings" "1_Chronicles" "2_Chronicles" "Ezra"
  "Nehemiah" "Esther" "Job" "Psalms" "Proverbs"
  "Ecclesiastes" "Song_of_Solomon" "Isaiah" "Jeremiah" "Lamentations"
  "Ezekiel" "Daniel" "Hosea" "Joel" "Amos"
  "Obadiah" "Jonah" "Micah" "Nahum" "Habakkuk"
  "Zephaniah" "Haggai" "Zechariah" "Malachi"
  "Matthew" "Mark" "Luke" "John" "Acts"
  "Romans" "1_Corinthians" "2_Corinthians" "Galatians" "Ephesians"
  "Philippians" "Colossians" "1_Thessalonians" "2_Thessalonians" "1_Timothy"
  "2_Timothy" "Titus" "Philemon" "Hebrews" "James"
  "1_Peter" "2_Peter" "1_John" "2_John" "3_John"
  "Jude" "Revelation"
)

rename_dirs() {
  local base_dir="$1"
  if [ ! -d "$base_dir" ]; then return; fi

  for i in "${!BOOKS[@]}"; do
    local num=$(printf "%02d" $((i + 1)))
    local en_name="${BOOKS[$i]}"
    local target="$base_dir/${num}_${en_name}"

    # Find the existing directory with this number prefix
    local existing
    existing=$(find "$base_dir" -maxdepth 1 -type d -name "${num}_*" | head -1)

    if [ -z "$existing" ]; then
      continue
    fi

    if [ "$existing" = "$target" ]; then
      continue  # already correct name
    fi

    echo "Renaming: $existing → $target"
    mv "$existing" "$target"
  done
}

echo "=== Renaming CUV audio directories ==="
rename_dirs "$BASE/assets/audio/CUV/OT"
rename_dirs "$BASE/assets/audio/CUV/NT"

echo "=== Renaming CUV text directories ==="
rename_dirs "$BASE/assets/text/CUV/OT"
rename_dirs "$BASE/assets/text/CUV/NT"

echo "Done."
