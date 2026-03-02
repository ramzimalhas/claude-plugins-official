---
description: Consolidate all 1Password accounts into primary account
allowed-tools: [Bash(op *), AskUserQuestion, Read, Write]
argument-hint: <primary-account-url>
---

# Consolidate 1Password Accounts

Final step: Import unique items from secondary accounts into your primary account.

## Arguments

- `primary-account-url`: Your main account to consolidate into (e.g., trymaestro.1password.com)

## What This Does

1. Verifies all unique items have been exported
2. Prompts for confirmation before each import
3. Imports .1pux files into primary account
4. Creates a "Consolidated" vault (or uses existing vault specified)
5. Verifies all items imported successfully
6. Generates final consolidation report

## Steps

Execute the consolidation script:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/consolidate.sh "$1"
```

## Safety Checks

Before consolidating:
- ✅ Audit report generated
- ✅ Comparison report shows no missed unique items
- ✅ Export files created for all secondary accounts
- ✅ User confirms abandoning secondary accounts

## Output

- Console: Import progress and verification
- File: `~/Desktop/1PASSWORD_CONSOLIDATION_REPORT.json`
- Vault: "Consolidated" vault in primary account with all imported items

## Post-Consolidation

After successful consolidation:
1. Verify all items accessible in primary account
2. Remove secondary accounts from 1Password app
3. Securely delete export files
4. Update Emergency Kit for primary account
5. Disable 2FA on abandoned accounts (if accessible)

## Example

```bash
/consolidate trymaestro.1password.com
```

## Rollback

If anything goes wrong during consolidation:
- Export files remain in `~/Desktop/1PASSWORD_EXPORTS/`
- Secondary accounts remain untouched until you manually remove them
- Can re-import exports into a different account if needed
