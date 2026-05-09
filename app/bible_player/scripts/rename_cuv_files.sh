#!/bin/bash
# Rename files inside CUV dirs from Chinese names to English names
# e.g. 01_创世记_001.subtitle.json → 01_Genesis_001.subtitle.json
set -e

BASE="$(cd "$(dirname "$0")/.." && pwd)"

en_name_for() {
  case "$1" in
    01) echo "Genesis" ;;        02) echo "Exodus" ;;         03) echo "Leviticus" ;;
    04) echo "Numbers" ;;        05) echo "Deuteronomy" ;;    06) echo "Joshua" ;;
    07) echo "Judges" ;;         08) echo "Ruth" ;;           09) echo "1Samuel" ;;
    10) echo "2Samuel" ;;        11) echo "1Kings" ;;         12) echo "2Kings" ;;
    13) echo "1Chronicles" ;;    14) echo "2Chronicles" ;;    15) echo "Ezra" ;;
    16) echo "Nehemiah" ;;       17) echo "Esther" ;;         18) echo "Job" ;;
    19) echo "Psalms" ;;         20) echo "Proverbs" ;;       21) echo "Ecclesiastes" ;;
    22) echo "SongOfSolomon" ;;  23) echo "Isaiah" ;;         24) echo "Jeremiah" ;;
    25) echo "Lamentations" ;;   26) echo "Ezekiel" ;;        27) echo "Daniel" ;;
    28) echo "Hosea" ;;          29) echo "Joel" ;;           30) echo "Amos" ;;
    31) echo "Obadiah" ;;        32) echo "Jonah" ;;          33) echo "Micah" ;;
    34) echo "Nahum" ;;          35) echo "Habakkuk" ;;       36) echo "Zephaniah" ;;
    37) echo "Haggai" ;;         38) echo "Zechariah" ;;      39) echo "Malachi" ;;
    40) echo "Matthew" ;;        41) echo "Mark" ;;           42) echo "Luke" ;;
    43) echo "John" ;;           44) echo "Acts" ;;           45) echo "Romans" ;;
    46) echo "1Corinthians" ;;   47) echo "2Corinthians" ;;   48) echo "Galatians" ;;
    49) echo "Ephesians" ;;      50) echo "Philippians" ;;    51) echo "Colossians" ;;
    52) echo "1Thessalonians" ;; 53) echo "2Thessalonians" ;; 54) echo "1Timothy" ;;
    55) echo "2Timothy" ;;       56) echo "Titus" ;;          57) echo "Philemon" ;;
    58) echo "Hebrews" ;;        59) echo "James" ;;          60) echo "1Peter" ;;
    61) echo "2Peter" ;;         62) echo "1John" ;;          63) echo "2John" ;;
    64) echo "3John" ;;          65) echo "Jude" ;;           66) echo "Revelation" ;;
    *) echo "" ;;
  esac
}

renamed=0
for testament in OT NT; do
  for asset_type in audio text; do
    base_dir="$BASE/assets/$asset_type/CUV/$testament"
    [ -d "$base_dir" ] || continue
    for book_dir in "$base_dir"/*/; do
      dname="$(basename "$book_dir")"
      nn="${dname%%_*}"
      en_name="$(en_name_for "$nn")"
      if [ -z "$en_name" ]; then
        echo "WARNING: no mapping for $dname (nn=$nn)"
        continue
      fi
      for f in "$book_dir"*; do
        fname="$(basename "$f")"
        if [[ "$fname" =~ ^([0-9]{2})_(.+)_([0-9]{3})\.(.+)$ ]]; then
          fnn="${BASH_REMATCH[1]}"
          fchap="${BASH_REMATCH[3]}"
          fext="${BASH_REMATCH[4]}"
          newname="${fnn}_${en_name}_${fchap}.${fext}"
          if [ "$fname" != "$newname" ]; then
            mv "$book_dir$fname" "$book_dir$newname"
            renamed=$((renamed + 1))
          fi
        fi
      done
    done
  done
done

echo "Done. Renamed $renamed files."
