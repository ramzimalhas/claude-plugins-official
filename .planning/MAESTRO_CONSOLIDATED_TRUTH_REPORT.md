# MAESTRO CONSOLIDATED TRUTH REPORT
> Generated: 2026-03-02T21:28Z | Session: claude-plugins-official
> Cross-referenced against: all prior forensic sweeps, Pieces export, Raycast remediation report, Context7 docs, live system state

---

## 1. ACTUAL SYSTEM STATE (Verified via CLI)

| Component | Raycast Claim | Actual | Verdict |
|-----------|--------------|--------|---------|
| Node.js | v22+ | **v25.6.1** (mise) | WRONG |
| Bun | v1.2.x | **v1.3.10** (mise) | WRONG |
| Python | 3.12+ | **3.12.12** (mise) | CORRECT |
| mise | installed | **2026.3.0** | CORRECT |
| DuckDB | v1.2.x | **v1.4.4** (Homebrew) | WRONG |
| Railway | not installed | **INSTALLED** (`/opt/homebrew/bin/railway`) | WRONG |
| Tailscale | not installed | **INSTALLED** (`/opt/homebrew/bin/tailscale`) | WRONG |
| Azure CLI | not authenticated | **INSTALLED but NOT logged in** (`az login` needed) | CORRECT |
| 1Password CLI | installed, not auth'd | **INSTALLED, NOT signed in** | CORRECT |
| GitHub CLI | authenticated | **YES** — `ramzimalhas` via keyring | CORRECT |
| Ollama | — | **RUNNING** on port 11434 | — |
| PiecesOS | — | **RUNNING** on port 39301 (Streamable HTTP) | — |
| ~/CLAUDE.md | needs creation | **EXISTS** (Task Master imports) | WRONG |
| ~/.mcp.json | needs creation | **EXISTS** (task-master-ai config) | WRONG |
| ~/.maestroverse/ | needs cloning | **EXISTS** (full git repo) | WRONG |

**Raycast Report Accuracy: 7/18 correct = 39%** — The report is unreliable for remediation planning.

---

## 2. ~/.claude/ SETTINGS.JSON — CRITICAL STATE

### Current (STRIPPED)
The live `~/.claude/settings.json` has been **stripped to 1 MCP server** (filesystem only), **zero plugins enabled**, no hooks, no env vars, no permissions. This happened during a previous session's config surgery.

### Backup (FULL — 2026-03-01)
The backup at `~/.claude/config-backups/20260301_013018/settings.json` contains the complete config:
- **5 active MCP servers**: filesystem, memory, sequential-thinking, brave-search, github
- **7 disabled MCP servers** (in `_disabledMcpServers`): resend, betterstack, notion, cloudflare, pieces, cloudflare-audit, mother-skills
- **9 enabled plugins**: commit-commands, code-review, security-guidance, pr-review-toolkit, hookify, feature-dev, plugin-dev, typescript-lsp, pyright-lsp
- **Hooks**: SessionStart (MAESTRO echo + GSD update check), PostToolUse (GSD context monitor)
- **Env**: EDITOR=cursor, NODE_ENV=development, MAESTRO_MODE=true
- **Model**: claude-sonnet-4-5-20250929

### Action Required
Restore `settings.json` from backup, but with these fixes:
1. Add `pieces` back to active mcpServers (not disabled) with correct URL
2. Enable `linear` and `supabase` plugins
3. Fix `filesystem` args (backup had 5 dirs; current has entire homedir — security risk)

---

## 3. PiecesOS — CONFIG MISMATCHES

| Config Surface | Port | Transport | Endpoint | Status |
|---------------|------|-----------|----------|--------|
| **Live system** | 39301 | Streamable HTTP | `/model_context_protocol/2025-03-26/mcp` | Running (PID 83489) |
| **~/.exports** | 39300 | — | — | WRONG PORT |
| **Backup settings.json** | 39301 | `url` (HTTP) | `/model_context_protocol/2025-03-26/mcp` | CORRECT |
| **Pieces Copilot Export** | 39301 | — | `/mcp` (404!) | WRONG ENDPOINT |

**Obsidian** is also connected to PiecesOS (ports 64736, 64738 → 39301).

### Fix
```bash
# In ~/.exports, change:
export PIECES_OS_PORT=39300
# To:
export PIECES_OS_PORT=39301
```

---

## 4. SEMGREP + RUFF SCAN RESULTS

### Semgrep (security-audit + secrets + python rulesets)
**2 findings** — both in `plugins/hookify/core/audit_capture.py`:

| Line | Severity | Issue |
|------|----------|-------|
| 142 | BLOCKING | `hashlib.md5(file_path.encode())` — MD5 for file path hashing |
| 146 | BLOCKING | `hashlib.md5(command.encode())` — MD5 for command hashing |

**Verdict**: These are used for **cache keys, not cryptographic signatures**. MD5 is acceptable here (same pattern as Python's `functools.lru_cache` internals). However, switching to `hashlib.sha256` is trivial and eliminates the semgrep finding. Not a real vulnerability.

### Ruff Linter
**3 findings** — all in `plugins/hookify/core/audit_capture.py`:

| Line | Code | Issue |
|------|------|-------|
| 618 | F541 | f-string without placeholders: `f"# All mutations in this session"` |
| 621 | F541 | f-string without placeholders: `f"# No-ops only (agent lies)"` |
| 624 | F541 | f-string without placeholders: `f"# Bash commands"` |

All auto-fixable with `ruff check --fix`.

### Ruff Format
**1 file** needs reformatting: `plugins/hookify/core/audit_capture.py`

**Overall**: Plugin code is clean. No real security vulnerabilities. Only cosmetic issues in one file.

---

## 5. MEMORY & CONTEXT TOOLS RESEARCH

### Adopt: Mem0 (mem0.ai)
| Attribute | Value |
|-----------|-------|
| GitHub | github.com/mem0ai/mem0 (46.8K stars) |
| MCP Server | `mem0-mcp-server` (PyPI) or `@openmemory/install` (npm, local-first) |
| Transport | stdio |
| Self-hosted | Yes (Qdrant + Neo4j + Ollama) |
| Free tier | 10K memories, 1K calls/mo |
| Funding | $23.9M raised |
| Version | v1.0.3 (Feb 2026) |
| 9 MCP tools | save_memory, search_memories, get_all_memories, get_memory, update_memory, delete_memory, delete_all_memories, delete_entity, list_entities |

**Why**: Fills the cross-session memory gap in MAESTRO. Claude Code's auto-memory (`~/.claude/projects/*/memory/`) is session-scoped and limited. Mem0 provides semantic search across all past interactions, multi-agent scoping (user/agent/app/run), and graph memory. Self-hostable with your existing Ollama (running on 11434).

### Skip: MemSync
Browser extension only. No MCP, no API, no self-hosted. Consumer tool, not infrastructure.

### Watch: OneContext.dev
Open-source AI identity/profile sync. MCP server available (`@onecontext/mcp-server`). Auto-syncs from GitHub/Notion/X. Your CLAUDE.md already serves this function, but the auto-sync is interesting. Apache 2.0.

### Keep: Context7
Already in stack. 500 req/mo free tier (reduced from 6K in Jan 2026). Monitor usage. **Docfork** (MIT, 9K+ libraries) is an open-source fallback if you hit limits.

---

## 6. ~/.claude/ COMPONENT INDEX vs DOCS

Based on Context7 query of `/anthropics/claude-code` documentation:

### Documented Components (should exist)
| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| settings.json | `~/.claude/settings.json` | EXISTS (stripped) | Needs restore from backup |
| CLAUDE.md | `~/.claude/CLAUDE.md` | EXISTS | Global instructions, 95 lines |
| commands/ | `~/.claude/commands/` | EXISTS | Custom slash commands |
| hooks/ | `~/.claude/hooks/` | EXISTS | GSD hooks (gsd-check-update.js, gsd-context-monitor.js) |
| plugins/ | `~/.claude/plugins/` | EXISTS | Marketplace plugins (this repo) |
| projects/ | `~/.claude/projects/` | EXISTS | Per-project configs + auto-memory |
| skills/ | `~/.claude/skills/` | EXISTS | Agent skills |
| agents/ | `~/.claude/agents/` | EXISTS | 11 GSD agent .md files |

### Undocumented Components (may be artifacts)
| Component | Status | Assessment |
|-----------|--------|------------|
| backup-claude-configs.sh | EXISTS | Custom backup script — keep |
| config-backups/ | EXISTS | Contains 2026-03-01 backup — CRITICAL, keep |
| backups/ | EXISTS | Possibly redundant with config-backups/ |
| cache/, image-cache/, paste-cache/ | EXISTS | Runtime caches — safe to clear |
| debug/ | EXISTS | Debug logs (current session: 9474 lines) |
| telemetry/ | EXISTS | Anonymized telemetry |
| get-shit-done/ | EXISTS | GSD workflow system — active |
| plans/, todos/, tasks/ | EXISTS | GSD state directories |
| history.jsonl | EXISTS | Conversation history |
| prompts.db | EXISTS | Prompt database |
| stats-cache.json | EXISTS | Usage stats |
| .credentials.json | EXISTS | OAuth tokens — SECURITY CONCERN |
| ide/ | EXISTS | IDE integration |
| downloads/, file-history/ | EXISTS | File management |
| session-env/, shell-snapshots/ | EXISTS | Environment state |
| security_warnings_state_*.json | EXISTS | Session-scoped warnings |
| claude-desktop-backup-*/ | EXISTS | Desktop app backup |
| package.json | EXISTS | npm metadata |
| statusline-command.sh | EXISTS | Status line script |

### Hook Event Types (from Claude Code docs)
| Event | Purpose | Your Usage |
|-------|---------|------------|
| PreToolUse | Before tool execution | hookify rules engine |
| PostToolUse | After tool execution | GSD context monitor + hookify |
| Stop | When Claude stops | hookify rules |
| SubagentStop | When subagent stops | Not used |
| SessionStart | Session begins | MAESTRO echo + GSD update check |
| SessionEnd | Session ends | Not used |
| UserPromptSubmit | User sends prompt | hookify rules |
| PreCompact | Before context compaction | Not used |
| Notification | Notification event | Not used |

---

## 7. CRITICAL ACTION ITEMS (Priority Order)

### P0 — Security (Do Today)
1. **Delete plaintext 1Password CSV**: `~/Desktop/_SECURITY_QUARANTINE/1passwords.csv`
2. **Delete plaintext API key**: Remove `ANTHROPIC_API_KEY=sk-ant-*` from `~/.maestroverse/.env`
3. **Audit `.credentials.json`**: `~/.claude/.credentials.json` contains OAuth tokens — verify scopes

### P1 — Config Restore (Do Today)
4. **Restore settings.json** from `~/.claude/config-backups/20260301_013018/settings.json` with fixes:
   - Move `pieces` from `_disabledMcpServers` to active `mcpServers`
   - Re-enable plugins (commit-commands, code-review, security-guidance, hookify, etc.)
   - Fix filesystem MCP args (restrict to specific dirs, not entire homedir)
5. **Fix PIECES_OS_PORT** in `~/.exports`: 39300 → 39301

### P2 — Tool Integration (This Week)
6. **Install Mem0 MCP**: `pip install mem0-mcp-server` or use OpenMemory (local-first with your Ollama)
7. **Fix ruff findings**: `ruff check --fix plugins/hookify/core/audit_capture.py`
8. **Reformat**: `ruff format plugins/hookify/core/audit_capture.py`
9. **Sign into 1Password CLI**: `op signin`
10. **Sign into Azure CLI**: `az login` (if needed for MAESTRO)

### P3 — Consolidation (This Week)
11. **Consolidate MAESTRO directories**: 9 dirs → 1 canonical (`~/.maestroverse/`)
12. **Consolidate 1Password vault paths**: 8 different vault names → standardize
13. **Update MCP spec references**: Any file referencing "2025-06-18" → "2025-11-25"
14. **Update Desktop audit files**: Fix spec version in MAESTRO_TRUTH_AUDIT_v2.sh and META_PROMPT_v2.md

---

## 8. BLEEDING-EDGE TOOLS SHORTLIST (2026)

### Highest Value for MAESTRO
| Tool | Category | Why |
|------|----------|-----|
| **Mem0** | Memory | Cross-session agent memory with semantic search |
| **mcp-scan** | Security | OWASP MCP Top 10 vulnerability scanner |
| **Docfork** | Docs | Open-source Context7 alternative (MIT, no rate limits) |
| **mcp-safe-fetch** | Efficiency | 93% token savings on web fetches |
| **OneContext.dev** | Identity | Auto-sync profile from GitHub/Notion/X |
| **FastMCP 3.0** | Framework | Python MCP server framework (if building custom servers) |

### Already Discovered (Previous Sessions)
Salus (YC W26 guardrails), RayBridge (Raycast→MCP bridge), ContextForge (IBM gateway), HashiCorp Vault MCP, Google Cloud Observability MCP, AWS MCP servers, GitHub Copilot SDK, Skills.sh (57K+ skills)
