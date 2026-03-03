#!/bin/zsh
set -euo pipefail

# 1PASSWORD MULTI-ACCOUNT AUDIT SCRIPT
# Discovers all accessible accounts and generates inventory report

REPORT_DIR="$HOME/Desktop"
REPORT_FILE="$REPORT_DIR/1PASSWORD_AUDIT_REPORT.json"
TEMP_DIR="/tmp/1password-audit-$$"

echo "🔐 1Password Multi-Account Audit"
echo "================================="
echo ""

# Create temp directory
mkdir -p "$TEMP_DIR"

# Step 1: List all accounts
echo "📋 Step 1: Discovering accounts..."
op account list --format=json > "$TEMP_DIR/accounts.json"

ACCOUNT_COUNT=$(jq 'length' "$TEMP_DIR/accounts.json")
echo "Found $ACCOUNT_COUNT account(s)"
echo ""

# Step 2: Audit each account
echo "📊 Step 2: Auditing inventories..."
jq -r '.[] | @json' "$TEMP_DIR/accounts.json" | while read account_json; do
  URL=$(echo "$account_json" | jq -r '.url')
  EMAIL=$(echo "$account_json" | jq -r '.email')
  UUID=$(echo "$account_json" | jq -r '.account_uuid')

  echo "  → $URL ($EMAIL)"

  # Fetch items for this account
  op item list --format=json --account="$UUID" > "$TEMP_DIR/items_${UUID}.json" 2>/dev/null || {
    echo "    ⚠️  Failed to fetch items (may need re-authentication)"
    echo "[]" > "$TEMP_DIR/items_${UUID}.json"
  }

  ITEM_COUNT=$(jq 'length' "$TEMP_DIR/items_${UUID}.json")
  echo "    Items: $ITEM_COUNT"

  # Fetch vaults for this account
  op vault list --format=json --account="$UUID" > "$TEMP_DIR/vaults_${UUID}.json" 2>/dev/null || {
    echo "[]" > "$TEMP_DIR/vaults_${UUID}.json"
  }

  VAULT_COUNT=$(jq 'length' "$TEMP_DIR/vaults_${UUID}.json")
  echo "    Vaults: $VAULT_COUNT"
  echo ""
done

# Step 3: Generate comprehensive report
echo "📝 Step 3: Generating report..."

jq -s '
  # Combine all data
  .[0] as $accounts |
  {
    generated_at: (now | strftime("%Y-%m-%d %H:%M:%S")),
    total_accounts: ($accounts | length),
    accounts: [
      $accounts[] | . as $account |
      {
        url: .url,
        email: .email,
        uuid: .account_uuid,
        user_uuid: .user_uuid,
        vaults: (
          $accounts | map(select(.account_uuid == $account.account_uuid)) | .[0] |
          "/tmp/1password-audit-\($ENV.PID)/vaults_\(.account_uuid).json" | @sh |
          "cat \(.)" | @sh
        ),
        items: (
          $accounts | map(select(.account_uuid == $account.account_uuid)) | .[0] |
          "/tmp/1password-audit-\($ENV.PID)/items_\(.account_uuid).json" | @sh |
          "cat \(.)" | @sh
        ),
        stats: {
          total_items: (
            $accounts | map(select(.account_uuid == $account.account_uuid)) | .[0] |
            "/tmp/1password-audit-\($ENV.PID)/items_\(.account_uuid).json" | @sh |
            "jq length \(.)" | @sh
          ),
          total_vaults: (
            $accounts | map(select(.account_uuid == $account.account_uuid)) | .[0] |
            "/tmp/1password-audit-\($ENV.PID)/vaults_\(.account_uuid).json" | @sh |
            "jq length \(.)" | @sh
          )
        }
      }
    ]
  }
' "$TEMP_DIR/accounts.json" > "$TEMP_DIR/report_template.json"

# Build final report with actual data
{
  echo "{"
  echo "  \"generated_at\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
  echo "  \"total_accounts\": $ACCOUNT_COUNT,"
  echo "  \"accounts\": ["

  jq -r '.[] | @json' "$TEMP_DIR/accounts.json" | while read -r account_json; do
    UUID=$(echo "$account_json" | jq -r '.account_uuid')
    URL=$(echo "$account_json" | jq -r '.url')
    EMAIL=$(echo "$account_json" | jq -r '.email')
    USER_UUID=$(echo "$account_json" | jq -r '.user_uuid // "N/A"')

    ITEM_COUNT=$(jq 'length' "$TEMP_DIR/items_${UUID}.json")
    VAULT_COUNT=$(jq 'length' "$TEMP_DIR/vaults_${UUID}.json")

    # Category breakdown
    LOGINS=$(jq '[.[] | select(.category == "LOGIN")] | length' "$TEMP_DIR/items_${UUID}.json")
    API_CREDS=$(jq '[.[] | select(.category == "API_CREDENTIAL")] | length' "$TEMP_DIR/items_${UUID}.json")
    SECURE_NOTES=$(jq '[.[] | select(.category == "SECURE_NOTE")] | length' "$TEMP_DIR/items_${UUID}.json")

    cat << EOF
    {
      "url": "$URL",
      "email": "$EMAIL",
      "uuid": "$UUID",
      "user_uuid": "$USER_UUID",
      "stats": {
        "total_items": $ITEM_COUNT,
        "total_vaults": $VAULT_COUNT,
        "by_category": {
          "logins": $LOGINS,
          "api_credentials": $API_CREDS,
          "secure_notes": $SECURE_NOTES,
          "other": $((ITEM_COUNT - LOGINS - API_CREDS - SECURE_NOTES))
        }
      },
      "recommendation": $([ $ITEM_COUNT -lt 20 ] && echo '"CONSIDER_ABANDONING"' || echo '"KEEP"')
    },
EOF
  done | sed '$ s/,$//'

  echo "  ]"
  echo "}"
} > "$REPORT_FILE"

echo "✅ Audit complete!"
echo ""
echo "Report saved to: $REPORT_FILE"
echo ""

# Display summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r '.accounts[] | "
Account: \(.url)
Email: \(.email)
Items: \(.stats.total_items) (\(.stats.by_category.logins) logins, \(.stats.by_category.api_credentials) API keys)
Vaults: \(.stats.total_vaults)
Recommendation: \(.recommendation)
"' "$REPORT_FILE"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Review the report: cat $REPORT_FILE | jq"
echo "  2. Compare inventories: /compare-inventories <primary-account>"
echo "  3. Export unique items: /export-unique <account-to-abandon>"
echo "  4. Consolidate: /consolidate <primary-account>"

# Cleanup
rm -rf "$TEMP_DIR"
