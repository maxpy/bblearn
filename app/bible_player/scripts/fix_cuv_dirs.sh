#!/bin/bash
# Fix CUV dirs: remove underscores within names to match KJV format
# e.g. 09_1_Samuel → 09_1Samuel, 22_Song_of_Solomon → 22_SongofSolomon

set -e
BASE="$(cd "$(dirname "$0")/.." && pwd)"

fix_dirs() {
  local base_dir="$1"
  [ -d "$base_dir" ] || return
  for path in "$base_dir"/*/; do
    name="$(basename "$path")"
    # Split on first underscore to get NN prefix and the rest
    prefix="${name%%_*}_"
    rest="${name#*_}"
    # Remove all underscores from the rest
    newrest="${rest//_/}"
    newname="${prefix}${newrest}"
    if [ "$name" != "$newname" ]; then
      echo "Renaming: $name → $newname"
      mv "$base_dir/$name" "$base_dir/$newname"
    fi
  done
}

echo "=== Fixing CUV audio dirs ==="
fix_dirs "$BASE/assets/audio/CUV/OT"
fix_dirs "$BASE/assets/audio/CUV/NT"

echo "=== Fixing CUV text dirs ==="
fix_dirs "$BASE/assets/text/CUV/OT"
fix_dirs "$BASE/assets/text/CUV/NT"

echo "Done."
