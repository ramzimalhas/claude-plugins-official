#!/bin/zsh
set -euo pipefail

# 1PASSWORD UNIQUE ITEMS EXPORT SCRIPT
# Exports unique items from secondary account before abandoning

ACCOUNT_URL="${1:-}"
REPORT_DIR="$HOME/Desktop"
EXPORT_DIR="$REPORT_DIR/1PASSWORD_EXPORTS"
COMPARISON_REPORT="$REPORT_DIR/1PASSWORD_COMPARISON_REPORT.json"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

if [ -z "$ACCOUNT_URL" ]; then
  echo "❌ Error: Account URL required"
  echo "Usage: $0 <account-url-to-export>"
  exit 1
fi

if [ ! -f "$COMPARISON_REPORT" ]; then
  echo "❌ Error: Comparison report not found"
  echo "Run /compare-inventories first"
  exit 1
fi

echo "📦 1Password Unique Items Export"
echo "================================="
echo ""
echo "Account: $ACCOUNT_URL"
echo ""

# Step 1: Get unique items list
echo "📋 Step 1: Loading unique items list..."
UNIQUE_ITEMS=$(jq -r ".comparisons[] | select(.secondary_account.url == \"$ACCOUNT_URL\") | .unique_item_list" "$COMPARISON_REPORT")

if [ "$UNIQUE_ITEMS" == "null" ] || [ -z "$UNIQUE_ITEMS" ]; then
  echo "❌ Error: No comparison data found for $ACCOUNT_URL"
  echo "Run /compare-inventories first"
  exit 1
fi

UNIQUE_COUNT=$(echo "$UNIQUE_ITEMS" | jq 'length')

if [ "$UNIQUE_COUNT" -eq 0 ]; then
  echo "✅ No unique items to export - account safe to abandon!"
  exit 0
fi

echo "Found $UNIQUE_COUNT unique items to export"
echo ""

# Step 2: Create export directory
mkdir -p "$EXPORT_DIR"

# Step 3: Get account UUID
ACCOUNT_UUID=$(jq -r ".comparisons[] | select(.secondary_account.url == \"$ACCOUNT_URL\") | .secondary_account.uuid" "$COMPARISON_REPORT")

# Step 4: Export via 1Password CLI
# Note: op doesn't have direct "export to 1pux" command, so we'll export as JSON
EXPORT_FILE="$EXPORT_DIR/${ACCOUNT_URL//[^a-zA-Z0-9]/_}_unique_items_${TIMESTAMP}.json"

echo "📤 Step 2: Exporting unique items..."
echo ""

# Extract each unique item's full data
echo "$UNIQUE_ITEMS" | jq -r '.[] | .id' | while read -r ITEM_ID; do
  ITEM_TITLE=$(op item get "$ITEM_ID" --account="$ACCOUNT_UUID" --format=json 2>/dev/null | jq -r '.title')
  echo "  → Exporting: $ITEM_TITLE"

  # Get full item data and append to export
  op item get "$ITEM_ID" --account="$ACCOUNT_UUID" --format=json 2>/dev/null >> "$EXPORT_FILE.tmp"
  echo "," >> "$EXPORT_FILE.tmp"
done

# Wrap in JSON array
{
  echo "{"
  echo "  \"exported_at\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
  echo "  \"source_account\": \"$ACCOUNT_URL\","
  echo "  \"item_count\": $UNIQUE_COUNT,"
  echo "  \"items\": ["
  cat "$EXPORT_FILE.tmp" | sed '$ s/,$//'
  echo "  ]"
  echo "}"
} > "$EXPORT_FILE"

rm -f "$EXPORT_FILE.tmp"

echo ""
echo "✅ Export complete!"
echo ""
echo "Export file: $EXPORT_FILE"
echo "Items exported: $UNIQUE_COUNT"
echo ""

# Step 5: Generate import instructions
IMPORT_INSTRUCTIONS="$EXPORT_DIR/${ACCOUNT_URL//[^a-zA-Z0-9]/_}_IMPORT_INSTRUCTIONS.txt"

cat > "$IMPORT_INSTRUCTIONS" << EOF
1PASSWORD IMPORT INSTRUCTIONS
==============================

Exported from: $ACCOUNT_URL
Export date: $(date '+%Y-%m-%d %H:%M:%S')
Items exported: $UNIQUE_COUNT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMPORT METHODS:

Option 1: Via 1Password CLI (RECOMMENDED)
------------------------------------------
For each item in the export, create it in primary account:

  jq -r '.items[] | @json' "$EXPORT_FILE" | while read item; do
    echo "\$item" | op item create --account=<primary-account> -
  done

Option 2: Manual Import via 1Password App
------------------------------------------
1. Open 1Password app
2. Sign in to primary account
3. Import → 1Password (.1pux) format
4. Select: $EXPORT_FILE
5. Choose destination vault: "Consolidated" (or create new)

Option 3: Item-by-Item Review (SAFEST)
---------------------------------------
Review exported items and manually recreate only what you need:

  jq -r '.items[] | "\\(.title) - \\(.category)"' "$EXPORT_FILE"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SECURITY NOTES:
- This JSON export is NOT encrypted
- Store securely and delete after import
- Do NOT commit to git or upload to cloud
- After successful consolidation, run:
    shred -u "$EXPORT_FILE"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEPS:
1. Review exported items: jq '.items[] | {title, category}' "$EXPORT_FILE"
2. Run consolidation: /consolidate <primary-account>
3. Verify items imported correctly
4. Securely delete this export file
EOF

echo "Import instructions: $IMPORT_INSTRUCTIONS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "EXPORTED ITEMS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r '.items[] | "  - \(.title) (\(.category))"' "$EXPORT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  SECURITY WARNING:"
echo "This export is NOT encrypted. Store securely and delete after import."
echo ""
echo "Next step: /consolidate <primary-account>"
