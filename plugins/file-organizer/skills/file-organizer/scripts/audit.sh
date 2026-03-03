#!/bin/zsh
# =============================================================================
# FILE ORGANIZER — READ-ONLY FILESYSTEM AUDIT
# Non-destructive one-shot audit of any directory
# Usage: bash audit.sh [target_dir] [max_depth]
# Default: ~/Downloads, depth 2
# =============================================================================
set -euo pipefail

TARGET="${1:-$HOME/Downloads}"
DEPTH="${2:-2}"
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

# Validate target exists
if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: Directory not found: $TARGET"
  exit 1
fi

echo "# Filesystem Audit Report"
echo "> Generated: $TIMESTAMP"
echo "> Target: $TARGET"
echo "> Depth: $DEPTH"
echo ""

# ─── SECTION 1: Summary ───────────────────────────────────────────────────────
echo "## Summary"
echo ""

TOTAL_FILES=$(find "$TARGET" -maxdepth "$DEPTH" -type f ! -name '.*' ! -name '.DS_Store' 2>/dev/null | wc -l | tr -d ' ')
TOTAL_DIRS=$(find "$TARGET" -maxdepth "$DEPTH" -type d ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')
TOTAL_SIZE=$(du -sh "$TARGET" 2>/dev/null | awk '{print $1}')

echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Total files | $TOTAL_FILES |"
echo "| Total directories | $TOTAL_DIRS |"
echo "| Total size | $TOTAL_SIZE |"
echo ""

# ─── SECTION 2: Files by Extension ────────────────────────────────────────────
echo "## Files by Extension"
echo ""
echo "| Extension | Count | Example |"
echo "|-----------|-------|---------|"

find "$TARGET" -maxdepth "$DEPTH" -type f ! -name '.*' ! -name '.DS_Store' 2>/dev/null | \
  sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20 | \
  while read count ext; do
    example=$(find "$TARGET" -maxdepth "$DEPTH" -type f -name "*.$ext" ! -name '.*' 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "—")
    printf "| .%-8s | %5d | %s |\n" "$ext" "$count" "$example"
  done

echo ""

# ─── SECTION 3: Largest Files ──────────────────────────────────────────────────
echo "## Largest Files (Top 15)"
echo ""
echo "| Size | Modified | File |"
echo "|------|----------|------|"

find "$TARGET" -maxdepth "$DEPTH" -type f ! -name '.*' ! -name '.DS_Store' \
  -exec stat -f '%z %Sm %N' -t '%Y-%m-%d' {} \; 2>/dev/null | \
  sort -rn | head -15 | \
  while read size date filepath; do
    filename=$(basename "$filepath")
    if [[ $size -gt 1048576 ]]; then
      human=$(awk "BEGIN {printf \"%.1fM\", $size/1048576}")
    elif [[ $size -gt 1024 ]]; then
      human=$(awk "BEGIN {printf \"%.0fK\", $size/1024}")
    else
      human="${size}B"
    fi
    printf "| %-8s | %s | %s |\n" "$human" "$date" "$filename"
  done

echo ""

# ─── SECTION 4: Age Distribution ──────────────────────────────────────────────
echo "## Age Distribution"
echo ""
echo "| Age | Count |"
echo "|-----|-------|"

TODAY_EPOCH=$(date +%s)
WEEK_AGO=$((TODAY_EPOCH - 604800))
MONTH_AGO=$((TODAY_EPOCH - 2592000))
QUARTER_AGO=$((TODAY_EPOCH - 7776000))

count_today=0
count_week=0
count_month=0
count_quarter=0
count_older=0

while IFS= read -r filepath; do
  mod_epoch=$(stat -f '%m' "$filepath" 2>/dev/null || echo 0)
  if [[ $mod_epoch -gt $((TODAY_EPOCH - 86400)) ]]; then
    ((count_today++))
  elif [[ $mod_epoch -gt $WEEK_AGO ]]; then
    ((count_week++))
  elif [[ $mod_epoch -gt $MONTH_AGO ]]; then
    ((count_month++))
  elif [[ $mod_epoch -gt $QUARTER_AGO ]]; then
    ((count_quarter++))
  else
    ((count_older++))
  fi
done < <(find "$TARGET" -maxdepth "$DEPTH" -type f ! -name '.*' ! -name '.DS_Store' 2>/dev/null)

echo "| Today | $count_today |"
echo "| This week | $count_week |"
echo "| This month | $count_month |"
echo "| This quarter | $count_quarter |"
echo "| Older | $count_older |"
echo ""

# ─── SECTION 5: Potential Duplicates ───────────────────────────────────────────
echo "## Potential Duplicates (same size)"
echo ""

DUP_COUNT=$(find "$TARGET" -maxdepth "$DEPTH" -type f ! -name '.*' ! -name '.DS_Store' \
  -exec stat -f '%z %N' {} \; 2>/dev/null | \
  awk '{sizes[$1]++; files[$1]=files[$1] ? files[$1] ", " $2 : $2} END {for(s in sizes) if(sizes[s]>1) print sizes[s], s, files[s]}' | \
  wc -l | tr -d ' ')

if [[ $DUP_COUNT -gt 0 ]]; then
  echo "Found $DUP_COUNT size-based duplicate groups:"
  echo ""
  echo "| Size | Count | Files |"
  echo "|------|-------|-------|"

  find "$TARGET" -maxdepth "$DEPTH" -type f ! -name '.*' ! -name '.DS_Store' \
    -exec stat -f '%z %N' {} \; 2>/dev/null | \
    awk '{sizes[$1]++; files[$1]=files[$1] ? files[$1] " | " $2 : $2} END {for(s in sizes) if(sizes[s]>1) printf "%s %d %s\n", s, sizes[s], files[s]}' | \
    sort -rn | head -10 | \
    while read size count rest; do
      if [[ $size -gt 1048576 ]]; then
        human=$(awk "BEGIN {printf \"%.1fM\", $size/1048576}")
      else
        human=$(awk "BEGIN {printf \"%.0fK\", $size/1024}")
      fi
      # Show only basenames
      names=$(echo "$rest" | tr '|' '\n' | while read f; do basename "$f" 2>/dev/null; done | paste -sd ',' -)
      printf "| %s | %d | %s |\n" "$human" "$count" "$names"
    done
else
  echo "No size-based duplicates found."
fi

echo ""

# ─── SECTION 6: Classification Preview ────────────────────────────────────────
echo "## Classification Preview"
echo ""
echo "| Category | Count | Extensions |"
echo "|----------|-------|------------|"

# Count by proposed category
declare -A categories
while IFS= read -r filepath; do
  ext="${filepath##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  case "$ext" in
    zip|tar|gz|bz2|xz|rar|7z) cat="Archives" ;;
    pdf|doc|docx|txt|rtf|md|tex) cat="Documents" ;;
    png|jpg|jpeg|heic|webp|tif|bmp|svg|gif) cat="Images" ;;
    mp4|mov|mkv|avi|webm|m4v) cat="Media/Video" ;;
    mp3|wav|flac|m4a|aac) cat="Media/Audio" ;;
    py|js|ts|jsx|tsx|go|rs|java|kt|swift|sh|sql) cat="Code" ;;
    json|yaml|yml|toml|xml|plist|ini|conf) cat="Config" ;;
    csv|xlsx|xls|parquet|avro|numbers) cat="Data" ;;
    dmg|pkg|ipa|apk) cat="Installers" ;;
    log|trace|crash|diag) cat="Logs" ;;
    epub|mobi) cat="Books" ;;
    html|htm) cat="Web" ;;
    pt|pth|safetensors|onnx|gguf) cat="ML-Models" ;;
    fig|sketch|psd|xd) cat="Design" ;;
    jsonl|ndjson) cat="Telemetry" ;;
    sqlite|duckdb|db) cat="Databases" ;;
    *) cat="Uncategorized" ;;
  esac
  categories[$cat]=$(( ${categories[$cat]:-0} + 1 ))
done < <(find "$TARGET" -maxdepth "$DEPTH" -type f ! -name '.*' ! -name '.DS_Store' 2>/dev/null)

for cat in $(echo "${!categories[@]}" | tr ' ' '\n' | sort); do
  printf "| %-15s | %5d | — |\n" "$cat" "${categories[$cat]}"
done

echo ""
echo "---"
echo "**This is a read-only audit. No files were moved, renamed, or modified.**"
