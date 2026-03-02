#!/bin/zsh
set -euo pipefail

# 1PASSWORD CONSOLIDATION SCRIPT
# Imports unique items from secondary accounts into primary account

PRIMARY_ACCOUNT="${1:-}"
REPORT_DIR="$HOME/Desktop"
EXPORT_DIR="$REPORT_DIR/1PASSWORD_EXPORTS"
CONSOLIDATION_REPORT="$REPORT_DIR/1PASSWORD_CONSOLIDATION_REPORT.json"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

if [ -z "$PRIMARY_ACCOUNT" ]; then
  echo "❌ Error: Primary account URL required"
  echo "Usage: $0 <primary-account-url>"
  exit 1
fi

if [ ! -d "$EXPORT_DIR" ]; then
  echo "❌ Error: Export directory not found"
  echo "Run /export-unique first to export items from secondary accounts"
  exit 1
fi

echo "🔄 1Password Account Consolidation"
echo "==================================="
echo ""
echo "Primary account: $PRIMARY_ACCOUNT"
echo ""

# Step 1: Verify primary account
echo "✓ Step 1: Verifying primary account..."
PRIMARY_UUID=$(op account list --format=json | jq -r ".[] | select(.url == \"$PRIMARY_ACCOUNT\") | .account_uuid")

if [ -z "$PRIMARY_UUID" ]; then
  echo "❌ Error: Primary account not found or not signed in"
  exit 1
fi

echo "  Primary account verified: $PRIMARY_UUID"
echo ""

# Step 2: Find all export files
echo "📦 Step 2: Finding export files..."
EXPORT_FILES=$(find "$EXPORT_DIR" -name "*_unique_items_*.json" -type f)
EXPORT_COUNT=$(echo "$EXPORT_FILES" | wc -l | tr -d ' ')

if [ "$EXPORT_COUNT" -eq 0 ]; then
  echo "❌ Error: No export files found in $EXPORT_DIR"
  echo "Run /export-unique first"
  exit 1
fi

echo "Found $EXPORT_COUNT export file(s)"
echo ""

# Step 3: Create or verify "Consolidated" vault
echo "📁 Step 3: Preparing destination vault..."
VAULT_NAME="Consolidated"

op vault get "$VAULT_NAME" --account="$PRIMARY_UUID" &>/dev/null || {
  echo "  Creating vault: $VAULT_NAME"
  op vault create "$VAULT_NAME" --account="$PRIMARY_UUID"
}

echo "  Destination vault: $VAULT_NAME"
echo ""

# Step 4: Import items from each export
echo "📥 Step 4: Importing items..."
echo ""

TOTAL_IMPORTED=0
TOTAL_FAILED=0

{
  echo "{"
  echo "  \"consolidated_at\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
  echo "  \"primary_account\": \"$PRIMARY_ACCOUNT\","
  echo "  \"destination_vault\": \"$VAULT_NAME\","
  echo "  \"imports\": ["

  echo "$EXPORT_FILES" | while read -r EXPORT_FILE; do
    SOURCE_ACCOUNT=$(jq -r '.source_account' "$EXPORT_FILE")
    ITEM_COUNT=$(jq '.items | length' "$EXPORT_FILE")

    echo "  Importing from: $SOURCE_ACCOUNT ($ITEM_COUNT items)"

    IMPORTED=0
    FAILED=0

    # Import each item
    jq -c '.items[]' "$EXPORT_FILE" | while read -r ITEM_JSON; do
      ITEM_TITLE=$(echo "$ITEM_JSON" | jq -r '.title')
      ITEM_CATEGORY=$(echo "$ITEM_JSON" | jq -r '.category')

      echo -n "    → $ITEM_TITLE ... "

      # Create item in primary account
      echo "$ITEM_JSON" | op item create \
        --vault="$VAULT_NAME" \
        --account="$PRIMARY_UUID" \
        - &>/dev/null && {
        echo "✓"
        ((IMPORTED++))
      } || {
        echo "✗ FAILED"
        ((FAILED++))
      }
    done

    cat << EOF
    {
      "source_account": "$SOURCE_ACCOUNT",
      "items_total": $ITEM_COUNT,
      "items_imported": $IMPORTED,
      "items_failed": $FAILED,
      "export_file": "$EXPORT_FILE"
    },
EOF

    ((TOTAL_IMPORTED += IMPORTED))
    ((TOTAL_FAILED += FAILED))
  done | sed '$ s/,$//'

  echo "  ],"
  echo "  \"summary\": {"
  echo "    \"total_imported\": $TOTAL_IMPORTED,"
  echo "    \"total_failed\": $TOTAL_FAILED"
  echo "  }"
  echo "}"
} > "$CONSOLIDATION_REPORT"

echo ""
echo "✅ Consolidation complete!"
echo ""
echo "Report saved to: $CONSOLIDATION_REPORT"
echo ""

# Display summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONSOLIDATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r '
"Primary Account: \(.primary_account)
Destination Vault: \(.destination_vault)
Total Imported: \(.summary.total_imported)
Total Failed: \(.summary.total_failed)

Per-Account Breakdown:
" +
(.imports[] | "
  \(.source_account):
    Imported: \(.items_imported)/\(.items_total)
    Failed: \(.items_failed)
")
' "$CONSOLIDATION_REPORT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$TOTAL_FAILED" -eq 0 ]; then
  echo "🎉 All items successfully imported!"
  echo ""
  echo "Next steps:"
  echo "  1. Verify items in 1Password app: Vault → $VAULT_NAME"
  echo "  2. Remove secondary accounts from 1Password app"
  echo "  3. Securely delete export files:"
  echo "       shred -u $EXPORT_DIR/*_unique_items_*.json"
  echo "  4. Save new Emergency Kit for primary account"
else
  echo "⚠️  Some items failed to import ($TOTAL_FAILED failures)"
  echo ""
  echo "Review failed items in export files and import manually"
  echo "Do NOT delete export files until all items are verified"
fi
