#!/bin/zsh
set -euo pipefail

# 1PASSWORD INVENTORY COMPARISON SCRIPT
# Identifies unique items in each account

PRIMARY_ACCOUNT="${1:-}"
REPORT_DIR="$HOME/Desktop"
AUDIT_REPORT="$REPORT_DIR/1PASSWORD_AUDIT_REPORT.json"
COMPARISON_REPORT="$REPORT_DIR/1PASSWORD_COMPARISON_REPORT.json"
TEMP_DIR="/tmp/1password-compare-$$"

if [ -z "$PRIMARY_ACCOUNT" ]; then
  echo "❌ Error: Primary account URL required"
  echo "Usage: $0 <primary-account-url>"
  echo ""
  echo "Available accounts:"
  jq -r '.accounts[] | "  - \(.url) (\(.email))"' "$AUDIT_REPORT" 2>/dev/null || echo "  Run /audit-accounts first"
  exit 1
fi

if [ ! -f "$AUDIT_REPORT" ]; then
  echo "❌ Error: Audit report not found"
  echo "Run /audit-accounts first to generate inventory"
  exit 1
fi

echo "🔍 1Password Inventory Comparison"
echo "=================================="
echo ""
echo "Primary account: $PRIMARY_ACCOUNT"
echo ""

mkdir -p "$TEMP_DIR"

# Step 1: Extract primary account items
echo "📋 Step 1: Loading primary account inventory..."
PRIMARY_UUID=$(jq -r ".accounts[] | select(.url == \"$PRIMARY_ACCOUNT\") | .uuid" "$AUDIT_REPORT")

if [ -z "$PRIMARY_UUID" ]; then
  echo "❌ Error: Primary account not found in audit report"
  exit 1
fi

op item list --format=json --account="$PRIMARY_UUID" > "$TEMP_DIR/primary_items.json"
PRIMARY_COUNT=$(jq 'length' "$TEMP_DIR/primary_items.json")
echo "  Primary account has $PRIMARY_COUNT items"
echo ""

# Step 2: Compare with each secondary account
echo "🔎 Step 2: Comparing with other accounts..."
echo ""

{
  echo "{"
  echo "  \"generated_at\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
  echo "  \"primary_account\": \"$PRIMARY_ACCOUNT\","
  echo "  \"comparisons\": ["

  jq -r ".accounts[] | select(.url != \"$PRIMARY_ACCOUNT\") | @json" "$AUDIT_REPORT" | while read -r account_json; do
    SECONDARY_URL=$(echo "$account_json" | jq -r '.url')
    SECONDARY_UUID=$(echo "$account_json" | jq -r '.uuid')
    SECONDARY_EMAIL=$(echo "$account_json" | jq -r '.email')

    echo "  Comparing: $SECONDARY_URL..."

    # Get secondary account items
    op item list --format=json --account="$SECONDARY_UUID" > "$TEMP_DIR/secondary_${SECONDARY_UUID}_items.json" 2>/dev/null || {
      echo "    ⚠️  Failed to fetch items"
      echo "[]" > "$TEMP_DIR/secondary_${SECONDARY_UUID}_items.json"
    }

    # Find unique items (in secondary but not in primary)
    jq -s '
      .[0] as $primary |
      .[1] as $secondary |
      {
        unique_items: [
          $secondary[] | . as $sec_item |
          select(
            # Not in primary by title match
            ($primary | map(.title) | index($sec_item.title)) == null
          )
        ]
      }
    ' "$TEMP_DIR/primary_items.json" "$TEMP_DIR/secondary_${SECONDARY_UUID}_items.json" \
    > "$TEMP_DIR/unique_${SECONDARY_UUID}.json"

    UNIQUE_COUNT=$(jq '.unique_items | length' "$TEMP_DIR/unique_${SECONDARY_UUID}.json")
    TOTAL_SECONDARY=$(jq 'length' "$TEMP_DIR/secondary_${SECONDARY_UUID}_items.json")

    echo "    Unique items: $UNIQUE_COUNT / $TOTAL_SECONDARY"

    # Generate comparison entry
    cat << EOF
    {
      "secondary_account": {
        "url": "$SECONDARY_URL",
        "email": "$SECONDARY_EMAIL",
        "uuid": "$SECONDARY_UUID"
      },
      "stats": {
        "total_items": $TOTAL_SECONDARY,
        "unique_items": $UNIQUE_COUNT,
        "duplicates": $((TOTAL_SECONDARY - UNIQUE_COUNT))
      },
      "unique_item_list": $(jq -c '.unique_items | map({id, title, category})' "$TEMP_DIR/unique_${SECONDARY_UUID}.json"),
      "recommendation": $([ $UNIQUE_COUNT -eq 0 ] && echo '"SAFE_TO_ABANDON"' || echo '"EXPORT_FIRST"')
    },
EOF
  done | sed '$ s/,$//'

  echo "  ]"
  echo "}"
} > "$COMPARISON_REPORT"

echo ""
echo "✅ Comparison complete!"
echo ""
echo "Report saved to: $COMPARISON_REPORT"
echo ""

# Display summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "COMPARISON SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r '.comparisons[] | "
Secondary Account: \(.secondary_account.url)
Total Items: \(.stats.total_items)
Unique Items: \(.stats.unique_items)
Duplicates: \(.stats.duplicates)
Recommendation: \(.recommendation)
"' "$COMPARISON_REPORT"

# Show unique items details
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "UNIQUE ITEMS DETAILS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r '.comparisons[] |
  "\nAccount: \(.secondary_account.url)\n" +
  if (.stats.unique_items > 0) then
    (.unique_item_list[] | "  - \(.title) (\(.category))") + "\n"
  else
    "  ✅ No unique items - safe to abandon\n"
  end
' "$COMPARISON_REPORT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
jq -r '.comparisons[] |
  if .recommendation == "EXPORT_FIRST" then
    "  1. Export unique items: /export-unique \(.secondary_account.url)"
  else
    "  ✅ \(.secondary_account.url) - safe to abandon (no unique items)"
  end
' "$COMPARISON_REPORT"

# Cleanup
rm -rf "$TEMP_DIR"
