---
description: Audit all 1Password accounts and generate inventory report
allowed-tools: [Bash(op *), Read, Write]
---

# 1Password Multi-Account Audit

Discovers all accessible 1Password accounts and generates a complete inventory report.

## What This Does

1. Lists all signed-in 1Password accounts via `op account list`
2. For each account, fetches complete item inventory
3. Generates audit report with:
   - Account URL and email
   - Total vaults and items per account
   - Last signin date (if available)
   - Item breakdown by category (Login, API Credential, Secure Note, etc.)
4. Saves report to `~/Desktop/1PASSWORD_AUDIT_REPORT.json`

## Steps

Execute the audit script:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/audit.sh
```

## Output

- Console: Summary table of all accounts
- File: `~/Desktop/1PASSWORD_AUDIT_REPORT.json` with full inventory
- Recommendation: Which accounts to keep vs abandon based on item counts

## Next Steps

After reviewing the audit report, use:
- `/compare-inventories` to find unique items in each account
- `/export-unique` to backup items before abandoning accounts
- `/consolidate` to merge everything into your primary account
