---
name: file-organizer
description: >
  AI-powered file organization, classification, and filesystem auditing for macOS.
  Use this skill whenever the user mentions organizing files, sorting downloads, cleaning up
  folders, file classification, filesystem audit, AI file sorting, Sortio, Floxtop, Hazel,
  smart folders, file categorization, DuckDB file index, filesystem inventory, file triage,
  bulk file moves, downloads cleanup, or asks to build an organizational structure for any
  directory. Also triggers when the user wants a dry-run preview of file moves, a read-only
  filesystem audit, or wants to generate prompts for external file organizer tools (Sortio,
  Floxtop, Sparkle). Works with any directory — Downloads, Desktop, Documents, project folders,
  or MaestroVault. Complements download-normalizer (source-based routing) and screenshot-organizer
  (OCR-based classification) by providing general-purpose AI file organization.
version: 1.0.0
---

# File Organizer

## Overview

Organize files across any directory using AI-driven classification, content-aware categorization,
and non-destructive move operations. This skill bridges Claude Code with external file organizer
tools (Sortio, Floxtop, Hazel) and MCP-based file management servers.

The core principle: **audit first, preview always, move only with confirmation.**

## Architecture

```
┌─────────────────────────────────────────────┐
│              Claude Code Skill              │
│  (this file — orchestration + intelligence) │
└─────────┬───────────────────────┬───────────┘
          │                       │
    ┌─────▼─────┐          ┌─────▼──────┐
    │  Built-in  │          │  External   │
    │  Pipeline  │          │  Tools      │
    │            │          │             │
    │ • Glob     │          │ • Sortio    │
    │ • Bash     │          │ • Floxtop   │
    │ • Read     │          │ • Hazel     │
    │ • DuckDB   │          │ • MCP       │
    └────────────┘          └─────────────┘
```

## When to Use Which Path

| Scenario | Path |
|----------|------|
| User wants Claude to organize files directly | **Built-in Pipeline** (Steps 1-6 below) |
| User wants a prompt for Sortio/Floxtop | Read `references/sortio-prompts.md` |
| User wants a universal LLM meta-prompt | Read `references/meta-prompt.md` |
| User wants a read-only audit first | Run `scripts/audit.sh` |
| User wants DuckDB-indexed filesystem | Run `scripts/index.sql` via `duckdb` |
| User has `file-organizer-mcp` installed | Use MCP tools with dry-run |

## Built-in Pipeline

### Step 1: Inventory (Read-Only)

Scan the target directory and build a file manifest. Never modify anything in this step.

```bash
# Count and categorize files (excludes hidden files and .DS_Store)
find "$TARGET_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '.DS_Store' | wc -l

# List with sizes and dates for classification
ls -lhS "$TARGET_DIR" | head -50
```

If the target has fewer than 5 files, report clean and stop.

For deeper analysis, run the audit script:

```bash
bash scripts/audit.sh "$TARGET_DIR"
```

This produces a read-only report: file counts by extension, size distribution, age distribution,
duplicate candidates (by size), and classification preview — without moving anything.

### Step 2: Classify

Classify each file using this priority chain (first match wins):

1. **Content detection** — Read first 512 bytes of text files to detect source context
   (1Password exports, Claude logs, Pieces exports, Link Roamer data)
2. **Filename pattern** — Match against known naming conventions
   (Screenshot*, collected_page_structure*, MAESTRO*, pieces_*)
3. **Extension + context** — Use extension with filename keywords as signals
4. **Extension only** — Fall back to pure extension-based classification
5. **Fallback** — Route to INBOX/unsorted for human review

Classify into these categories (derived from Sortio's proven output + MAESTRO conventions):

| Category | Extensions / Signals |
|----------|---------------------|
| **Archives** | .zip .tar .gz .bz2 .xz .rar .7z |
| **Audits** | Files with "audit", "scan", "check" in name; .sh audit scripts |
| **Backups** | Files with "backup", "bak"; 1Password backups |
| **Books** | .epub .mobi .pdf (with "book" or "guide" in name) |
| **Code** | .py .js .ts .jsx .tsx .go .rs .java .kt .swift .sh .sql .html .css |
| **Config** | .json .yaml .yml .toml .xml .ini .conf .env .plist .lock .editorconfig |
| **Data** | .csv .tsv .parquet .avro .feather .arrow .pickle .pkl |
| **Databases** | .sqlite .duckdb .db .realm |
| **Design** | .fig .sketch .xd .psd .ai (Adobe) |
| **Documents** | .pdf .doc .docx .txt .rtf .md .tex .ppt .pptx .key .xls .xlsx .numbers |
| **Extensions** | Browser extensions, .crx, plugin packages |
| **Images** | .png .jpg .jpeg .heic .webp .tif .bmp .svg .gif |
| **Installers** | .dmg .pkg .ipa .apk .app .deb .rpm |
| **Logs** | .log .trace .crash .diag; Claude logs; 1Password logs |
| **Media** | .mp4 .mov .mkv .avi .webm .m4v .mp3 .wav .flac .m4a .aac |
| **Messages** | Chat exports, Pieces exports, copilot messages |
| **ML Models** | .pt .pth .safetensors .onnx .gguf .ckpt .bin (model files) |
| **Notes** | Short .txt .md files without code content |
| **Privacy** | Files with "privacy", "gdpr", "consent" in name |
| **Projects** | Directories with project structure; multi-file exports |
| **Reports** | .pdf with "report", "summary", "analysis" in name |
| **Screenshots** | Files starting with "Screenshot" or "CleanShot" |
| **Spreadsheets** | .xlsx .xls .csv .numbers (standalone, not data pipelines) |
| **Telemetry** | .jsonl .ndjson; trace/span/metrics files |
| **Web** | .html pages, saved websites, web scrapes |

### Step 3: Build Move Plan

Create a table showing every proposed action:

```
| # | File | Size | Category | Destination | Reason |
|---|------|------|----------|-------------|--------|
| 1 | Screenshot_2026-03-02.png | 285K | Screenshots | Images/Screenshots/ | Filename pattern |
| 2 | MAESTRO_audit.sh | 4.8K | Audits | Audits/ | Content: audit script |
```

**Critical rules for the plan:**
- NEVER propose moving hidden files, .git directories, node_modules, or symlinks
- NEVER propose moving into /Applications, /Library, /System, /private, /var, /usr, /bin, /opt
- NEVER overwrite existing files — use timestamp suffix on collision
- NEVER rename binaries, executables, libraries, or .app bundles
- ALWAYS use `mv -n` (no-clobber) for moves
- Prefer reusing existing folder structure over creating new folders

### Step 4: Present & Confirm

Show the move plan to the user. Ask:

> "Organize {N} files into {M} categories? (Y to proceed, N to cancel, or edit specific rows)"

**Never execute without explicit confirmation.**

### Step 5: Execute

```bash
# Create destination directories
mkdir -p "$DEST/{category}"

# Move with no-clobber
mv -n "$SOURCE/$file" "$DEST/$category/"

# On collision: add timestamp suffix
# mv "$SOURCE/$file" "$DEST/$category/${name}_$(date +%Y%m%d_%H%M%S).${ext}"
```

### Step 6: Report

```
Organized {N} files into {M} categories:
  Archives:     3 files (2.3 MB)
  Images:      12 files (15.1 MB)
  Messages:     8 files (1.2 MB)
  ...
  Skipped:      2 files (already at destination)
  Collisions:   1 file (renamed with timestamp)
```

## Integration with External Tools

### Sortio

Sortio is a macOS AI file organizer ($12.99 lifetime) with a natural language instruction box.
To generate an optimized Sortio prompt for the user's specific files, read `references/sortio-prompts.md`.

Sortio has **no API, no CLI, no MCP** — it is GUI-only. The skill generates prompts the user
pastes into Sortio's instruction field.

### Floxtop

Floxtop uses on-device Sentence Transformers + OCR for content-based classification.
**No API, no CLI, no MCP** — GUI-only, requires macOS 15+ Apple Silicon.
$20 one-time purchase. Best for content-aware classification (reads inside images/PDFs).

### Hazel (Noodlesoft)

Hazel 6 ($42) is rule-based with full shell script support. No AI, but can execute
any CLI tool as an action. Claude can generate Hazel-compatible shell scripts that
Hazel then runs automatically on folder changes.

### file-organizer-mcp (npm)

The only MCP server with AI-powered file organization + dry-run:

```bash
npx file-organizer-mcp --setup
```

Features: directory scanning with metadata, EXIF extraction (images), ID3 extraction (audio),
security screening, SHA-256 checksums, rollback support. Dry-run enabled by default.

If the user has this MCP server configured, use its tools directly instead of the built-in pipeline.

### DuckDB Metadata Index

For the "knowledge OS" pattern — build a queryable file metadata catalog:

```bash
duckdb "$HOME/.maestroverse/maestro.duckdb" < scripts/index.sql
```

This creates a `file_index` table with path, name, extension, size, modified date, and category.
Query it to answer questions like "show me all PDFs modified this week" or "find duplicate files
by size".

## Relationship to Other Skills

| Skill | Scope | When to defer |
|-------|-------|---------------|
| **download-normalizer** | `~/Downloads` → `~/MaestroVault` by source context | Files from known tools (Link Roamer, 1Password, Claude exports) |
| **screenshot-organizer** | Screenshots with OCR + metadata | HEIC/PNG screenshots needing text extraction |
| **file-organizer** (this) | Any directory, any file type, general organization | Everything else |

If the user's request involves organizing screenshots specifically, suggest screenshot-organizer.
If organizing Downloads from known export sources, suggest download-normalizer.
For general-purpose organization of any directory, use this skill.

## References

- `references/sortio-prompts.md` — Optimized prompts for Sortio, Floxtop, and generic AI organizers
- `references/meta-prompt.md` — Universal meta-prompt for any LLM/terminal/notebook
- `references/format-universe.md` — Complete file format classification reference
- `references/tool-registry.md` — Full landscape of AI file organization tools (2026)

## Scripts

- `scripts/audit.sh` — Read-only filesystem audit (dry-run, no modifications)
- `scripts/index.sql` — DuckDB file metadata indexer
