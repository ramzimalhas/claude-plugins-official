# AI File Organization Tool Registry (2026)

Verified tool landscape as of March 2026. Every entry cross-referenced against
npm, GitHub, Smithery, App Store, Product Hunt, and Hacker News.

---

## Tier 1 — MCP-Integrated (works with Claude Code directly)

| Tool | npm / Install | What It Does | Dry-Run | Price |
|------|---------------|--------------|---------|-------|
| **@modelcontextprotocol/server-filesystem** | `npx @modelcontextprotocol/server-filesystem /path` | Read, write, move, list, search files | No | Free (MIT) |
| **file-organizer-mcp** | `npx file-organizer-mcp --setup` | AI-categorized org with EXIF/ID3 extraction, security screening, rollback | **Yes** (default) | Free |
| **@steipete/macos-automator-mcp** | `npx @steipete/macos-automator-mcp@latest` | 200+ macOS automation recipes via AppleScript/JXA | N/A | Free |
| **@wonderwhy-er/desktop-commander** | `npx @wonderwhy-er/desktop-commander@latest setup` | Terminal + file ops + PDF extraction + native Excel | N/A | Free |
| **mcp-server-motherduck** | `uvx mcp-server-motherduck --db-path /path/db.duckdb` | SQL queries over local DuckDB files | N/A | Free |
| **@seed-ship/duckdb-mcp-native** | npm install | query_duckdb, list_tables, load_csv, load_parquet | N/A | Free |
| **llamacloud-mcp** | `npx @llamaindex/mcp-server-llamacloud` | Query LlamaCloud indexes for file content search | N/A | Freemium |

## Tier 2 — macOS Native Apps (GUI only, no programmatic integration)

| Tool | Price | AI Model | On-Device | MCP/API | Key Strength |
|------|-------|----------|-----------|---------|--------------|
| **Sortio** | $12.99 lifetime | Cloud LLM + Ollama | Optional | **None** | Natural language instructions, Smart Folders |
| **Floxtop** | $20 one-time | Sentence Transformers + OCR | **100%** | **None** | Content-aware classification, reads inside images/PDFs |
| **Hazel 6** | $42 one-time | None (rule-based) | N/A | **None** | Shell script actions, Apple Shortcuts, 15+ years mature |
| **Sparkle** | $89 lifetime / $5-20/mo | GPT-4 + Gemini Flash | No | **None** | 10M+ files organized, 10K+ users |
| **Files Magic AI** | Subscription | Cloud AI | No | **None** | macOS native, cloud folder support |
| **Sorted** | $9.99 + API costs | OpenAI | No | **None** | Auto-sort every 60 seconds |

## Tier 3 — Open Source (CLI/Python, composable)

| Tool | GitHub | Stars | AI Model | Dry-Run | Install |
|------|--------|-------|----------|---------|---------|
| **Local-File-Organizer** | QiuYannnn/Local-File-Organizer | ~3.1K | Llama 3.2 3B + LLaVA | No | Python |
| **AI File Sorter** | hyperfield/ai-file-sorter | ~445 | LLaMA/Mistral/GPT/Gemini + LLaVA | **Yes** | Python, v1.6.0 (Feb 2026) |
| **LlamaFS** | iyaja/llama-fs | High | Llama 3 via Groq/Ollama | **Yes** (batch) | Python + Electron |
| **FileWizardAI** | AIxHunter/FileWizardAI | — | Ollama/Groq/OpenAI | No | Python + Angular |
| **aifiles** | jjuliano/aifiles | — | OpenAI ChatGPT | No | `npm install -g aifiles` |
| **Recall** | HN Dec 2025 | — | Llama 3.2 + Ollama | — | Desktop app |

## Tier 4 — YC-Backed / Funded

| Company | Funding | What | Relevance |
|---------|---------|------|-----------|
| **Poly** | $8M seed (Felicis, Bloomberg Beta) | Cloud file storage with AI search/tagging | Cloud-first, not local |
| **o11** | YC | Knowledge management in Microsoft 365 | Enterprise, not macOS files |

---

## Key Gaps in the Ecosystem

1. **No MCP server does content-aware AI classification** (Floxtop's Sentence Transformers + MCP = dream tool that doesn't exist)
2. **No tool combines DuckDB metadata indexing with AI classification** in a single pipeline
3. **No tool generates Hazel rules via natural language** through MCP
4. **Sortio and Floxtop have zero programmatic integration** — GUI-only islands

---

## Recommended Stack

For MAESTRO, the optimal combination:

```
Layer 1 — Intelligence: Claude Code + this skill (classification logic)
Layer 2 — Execution:    file-organizer-mcp (dry-run + rollback)
Layer 3 — Metadata:     DuckDB (queryable file index)
Layer 4 — Automation:   Hazel 6 (watch folders, run shell scripts)
Layer 5 — Deep Content: Floxtop (on-device OCR + AI, manual review)
Layer 6 — Prompt Gen:   Sortio prompts (from references/sortio-prompts.md)
```

This gives you: AI classification (L1) → safe execution (L2) → queryable history (L3) →
automatic ongoing org (L4) → content-aware fallback (L5) → external tool support (L6).
