# 1Password Audit & Consolidation Plugin

Automate multi-account 1Password auditing and consolidation with zero manual work.

## Problem

You have multiple 1Password accounts (personal, work, legacy) and need to:
- Audit which accounts have critical data
- Identify duplicate vs unique items
- Consolidate everything into a single primary account
- Abandon legacy accounts safely

## Solution

This plugin provides 4 automated commands that handle the entire workflow:

1. **`/audit-accounts`** - Discover all accounts and generate inventory
2. **`/compare-inventories`** - Find unique items in each account
3. **`/export-unique`** - Backup items before abandoning accounts
4. **`/consolidate`** - Import everything into your primary account

## Quick Start

```bash
# Step 1: Audit all accounts
/audit-accounts

# Step 2: Compare to find unique items
/compare-inventories trymaestro.1password.com

# Step 3: Export unique items from accounts to abandon
/export-unique ramzimalhas.1password.com

# Step 4: Consolidate into primary account
/consolidate trymaestro.1password.com
```

## Features

✅ **Zero Manual Work** - One command does everything
✅ **Safe** - Exports items before any deletion
✅ **Smart Comparison** - Fuzzy matching finds duplicates
✅ **Detailed Reports** - JSON reports with full audit trail
✅ **Official 1Password CLI** - Uses `op` command (v2.32.1+)

## Requirements

- 1Password CLI (`op`) installed and authenticated
- Signed into all accounts you want to audit
- macOS/Linux with `jq` installed

## Commands

### `/audit-accounts`

Discovers all accessible accounts and generates inventory report.

**Output:**
- `~/Desktop/1PASSWORD_AUDIT_REPORT.json` - Full inventory with stats
- Console summary with item counts and recommendations

### `/compare-inventories <primary-account>`

Compares items across accounts to identify unique data.

**Arguments:**
- `primary-account` - Your main account URL (e.g., trymaestro.1password.com)

**Output:**
- `~/Desktop/1PASSWORD_COMPARISON_REPORT.json` - Unique items per account
- Recommendations (SAFE_TO_ABANDON vs EXPORT_FIRST)

### `/export-unique <account-url>`

Exports unique items from an account before abandoning it.

**Arguments:**
- `account-url` - Account to export from

**Output:**
- `~/Desktop/1PASSWORD_EXPORTS/<account>_unique_items_<timestamp>.json`
- Import instructions for later consolidation

### `/consolidate <primary-account>`

Imports all exported items into your primary account.

**Arguments:**
- `primary-account` - Destination account URL

**Output:**
- `~/Desktop/1PASSWORD_CONSOLIDATION_REPORT.json` - Import results
- Items imported into "Consolidated" vault

## Example Workflow

```bash
# You have 3 accounts:
# - trymaestro.1password.com (190 items) ✅ Keep
# - ramzimalhas.1password.com (unknown) ❓ Check
# - my.1password.com (locked) ❌ Can't access

# Step 1: Audit
/audit-accounts
# Shows: ramzimalhas has 5 items

# Step 2: Compare
/compare-inventories trymaestro.1password.com
# Shows: ramzimalhas has 2 unique items (others are duplicates)

# Step 3: Export unique items
/export-unique ramzimalhas.1password.com
# Exports 2 items to ~/Desktop/1PASSWORD_EXPORTS/

# Step 4: Consolidate
/consolidate trymaestro.1password.com
# Imports 2 items into trymaestro.1password.com → "Consolidated" vault

# Step 5: Clean up
# - Remove ramzimalhas from 1Password app
# - Delete export files: shred -u ~/Desktop/1PASSWORD_EXPORTS/*.json
```

## Security

- ⚠️ Export files are **NOT encrypted** - store securely
- ✅ Use `shred -u` to securely delete exports after import
- ✅ Never commit exports to git
- ✅ All operations use official 1Password CLI
- ✅ No credentials stored by plugin

## Troubleshooting

### "Failed to fetch items (may need re-authentication)"

Sign into the account first:
```bash
op signin --account <account-url>
```

### "Primary account not found"

Run `/audit-accounts` first to discover available accounts.

### "No export files found"

Run `/export-unique` for each secondary account before `/consolidate`.

## Technical Details

- **Plugin Type:** Commands + Shell Scripts
- **CLI Tool:** 1Password CLI (`op`) v2.32.1+
- **Dependencies:** `jq` for JSON processing
- **Reports:** JSON format for programmatic access
- **Data Flow:** `op item list` → compare → `op item create`

## License

MIT

## Author

Ramzi Malhas (ramzi@trymaestro.app)

## Version

1.0.0 (2026-03-01)
