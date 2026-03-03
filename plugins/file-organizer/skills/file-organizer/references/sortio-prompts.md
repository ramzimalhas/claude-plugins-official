# Sortio & AI File Organizer Prompts

Optimized instruction prompts for AI file organizer tools. Each prompt is designed to be:
- **Dense** — maximum coverage in minimum characters
- **Deterministic** — same input always produces same classification
- **Non-destructive** — never overwrites, deletes, or renames system files

## Character Limits by Tool

| Tool | Instruction Limit | Recommended |
|------|-------------------|-------------|
| Sortio | ~800-1200 chars | Safe Universal (below) |
| Floxtop | Custom categories (no char limit) | Category descriptions |
| Sparkle | No custom instructions | N/A |
| Generic AI organizer | Varies | Power Version (below) |

---

## Safe Universal Prompt (780 chars)

**Paste into: Sortio → Instructions**

```
Analyze files by content filename extension and metadata. Never modify macOS system folders application bundles hidden files git directories node_modules or symlinks. Classify into: Media Documents Code Data Logs Screenshots Config Models Datasets Plugins Extensions Telemetry Research Outputs Archives Backups. Organize using Category/Year/Project structure. Reuse existing folders before creating new ones. Never overwrite files. Never rename binaries executables libraries or app bundles. Avoid duplicates. Always generate preview plan first. Only move user-generated files. Prefer tagging over renaming when unsure. Ignore system paths: Applications Library System private var usr bin opt.
```

---

## Power Version (1180 chars)

**Use when the tool allows longer instructions.**

```
Analyze files using extension filename metadata and safe content inspection. Classify into: Media Documents Code Data Logs Screenshots Config Models Datasets Plugins Extensions Telemetry Research Outputs Archives Backups Assets Scripts Libraries Workflows Projects. Use structure: Category/Year/Project. Prefer reuse of existing folders before creating new ones. Never overwrite files. Never rename executables binaries libraries packages or app bundles. Ignore hidden folders: .git node_modules .cache .venv .gradle .terraform. Do not move symlinks. Ignore macOS system paths: Applications Library System private var usr bin opt. Only operate on user files. Generate preview plan before any execution. Prefer tagging metadata when uncertain. Group screenshots by month. Group chat exports by source app. Keep project directories intact—never split a project across categories.
```

---

## MAESTRO-Specific Prompt (1050 chars)

**Tuned for Ramzi's actual file patterns based on Sortio output analysis.**

```
Classify files into: Archives (zip tar 7z) Audits (scripts with audit/scan in name) Backups (backup files, 1Password exports) Books (epub mobi) Code (py js ts go rs swift sh) Config (json yaml toml plist) Data (csv parquet avro) Design (fig sketch psd) Documents (pdf docx txt md) Extensions (browser extensions) Images (png jpg heic svg with Screenshots subfolder) Installers (dmg pkg) Logs (log files, Claude logs, 1Password logs) Media/Video (mp4 mov) Messages (chat exports from Pieces Claude WhatsApp) ML-Models (pt safetensors onnx gguf) Notes (short txt md) Privacy (privacy-related docs) Projects (multi-file exports, project dirs) Reports (pdf with report/summary) Spreadsheets (xlsx csv numbers) Telemetry (jsonl ndjson) Web (html pages saved sites). Use Category/subcategory structure. Never move hidden files or system paths. Preview before executing.
```

---

## Floxtop Category Descriptions

Floxtop uses custom category descriptions instead of a single instruction prompt.
Create these categories in Floxtop's UI:

| Category | Description for Floxtop |
|----------|------------------------|
| Archives | Compressed files: ZIP, TAR, 7Z, RAR. Backup archives and bundled exports. |
| Audits | System audit scripts, security scan outputs, diagnostic shell scripts. |
| Chat Exports | Conversation exports from Pieces, Claude, WhatsApp, Duck.ai. Markdown, text, or PDF chat logs. |
| Code | Source code files: Python, JavaScript, TypeScript, Go, Rust, Swift, Shell. |
| Design | Design files from Figma, Sketch, Adobe XD, Photoshop, Illustrator. |
| Documents | PDFs, Word documents, presentations, text files, Markdown notes. |
| Images | Photos, screenshots, diagrams. PNG, JPEG, HEIC, SVG, WebP. |
| Installers | Application installers: DMG, PKG, IPA, APK. Flag if older than 30 days. |
| Logs | Application logs, system crash reports, diagnostic output. |
| Media | Video files (MP4, MOV, MKV) and audio files (MP3, WAV, FLAC). |
| Projects | Multi-file project exports, documentation bundles, research collections. |
| Reports | Summary PDFs, analysis documents, system status reports. |
| Spreadsheets | Excel, CSV, Numbers files with tabular data. |
| Web | Saved HTML pages, website archives, web scrapes, browser exports. |

---

## Hazel Rule Template

For Hazel 6, generate rules that call shell scripts. Example rule for Downloads cleanup:

```
Folder: ~/Downloads
Conditions: Date Added is not in the last 1 day
            Kind is not Folder
            Name does not contain ".crdownload"
Action: Run shell script (embedded):

#!/bin/zsh
set -euo pipefail

# Classify by extension
ext="${1##*.}"
case "$ext" in
  zip|tar|gz|7z|rar) dest="Archives" ;;
  pdf|doc|docx|txt|md) dest="Documents" ;;
  png|jpg|jpeg|heic|svg) dest="Images" ;;
  dmg|pkg) dest="Installers" ;;
  mp4|mov|mkv) dest="Media" ;;
  *) dest="Unsorted" ;;
esac

mkdir -p ~/Downloads/Documents/"$dest"
mv -n "$1" ~/Downloads/Documents/"$dest"/ 2>/dev/null || true
```
