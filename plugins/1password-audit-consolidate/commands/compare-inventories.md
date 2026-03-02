---
description: Compare inventories across 1Password accounts to identify unique items
allowed-tools: [Bash(op *), Bash(jq *), Read, Write]
argument-hint: <primary-account-url> [secondary-account-url...]
---

# Compare 1Password Account Inventories

Identifies unique items in each account by comparing titles, URLs, and categories.

## Arguments

- `primary-account-url`: Your main account to keep (e.g., trymaestro.1password.com)
- `secondary-account-url`: Accounts to compare (optional, defaults to all non-primary)

## What This Does

1. Loads inventory from all accounts
2. Compares items by:
   - Title (fuzzy match to catch duplicates)
   - URL/website (for Login items)
   - Category (API Credential, Secure Note, etc.)
3. Identifies items that exist ONLY in secondary accounts
4. Generates comparison report with recommendations

## Steps

Execute the comparison script:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/compare.sh "$@"
```

## Output

- Console: List of unique items per account
- File: `~/Desktop/1PASSWORD_COMPARISON_REPORT.json`
- Recommendations:
  - If secondary account has 0 unique items → SAFE TO ABANDON
  - If secondary account has unique items → EXPORT FIRST

## Example

```bash
/compare-inventories trymaestro.1password.com ramzimalhas.1password.com
```

## Next Steps

- If unique items found → use `/export-unique` to backup
- If no unique items → safe to abandon secondary accounts
- Use `/consolidate` after exporting to merge accounts
