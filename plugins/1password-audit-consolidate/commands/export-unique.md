---
description: Export unique items from secondary accounts before abandoning
allowed-tools: [Bash(op *), Bash(jq *), Write]
argument-hint: <account-url-to-export>
---

# Export Unique Items from 1Password Account

Backs up items that exist only in a secondary account before abandoning it.

## Arguments

- `account-url-to-export`: The account to export unique items from (e.g., ramzimalhas.1password.com)

## What This Does

1. Loads comparison report from `/compare-inventories`
2. Identifies items unique to the specified account
3. Exports each unique item to 1PUX format
4. Saves export to `~/Desktop/1PASSWORD_EXPORTS/<account-name>_unique_items_<timestamp>.1pux`
5. Generates import instructions for later

## Steps

Execute the export script:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/export.sh "$1"
```

## Output

- File: `~/Desktop/1PASSWORD_EXPORTS/<account>_unique_items_YYYYMMDD_HHMMSS.1pux`
- Console: List of exported items with categories
- Import Instructions: How to import into primary account later

## Security Note

The .1pux export file is encrypted with your account password. Store it securely and delete after successful import to primary account.

## Example

```bash
/export-unique ramzimalhas.1password.com
```

## Next Steps

- Review exported items in `~/Desktop/1PASSWORD_EXPORTS/`
- Use `/consolidate` to import into primary account
- After successful consolidation, securely delete export files
