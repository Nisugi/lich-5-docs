# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository generates YARD documentation for the **Lich 5 Ruby project** using AI (OpenAI, Anthropic, or Gemini). The system uses a modular 3-stage workflow to transform undocumented Ruby files into a complete documentation website hosted on GitHub Pages.

**Documentation Flow:**
```
Stage 1: Generate → documented/ (YARD comments added to Ruby files)
Stage 2: Validate → warnings.txt (YARD validation report)
Stage 3: Build HTML → docs/ (Static website for GitHub Pages)
```

All stages are **manually triggered** via GitHub Actions workflows.

## Core Architecture

### Incremental Build System

The system uses a **manifest-based incremental build** to avoid reprocessing unchanged files:

- **Manifest location:** `output/latest/manifest.json`
- **Tracked in git:** Yes (committed after each generation run)
- **Hash algorithm:** SHA256 of code only (comments excluded)
- **Commit strategy:** Manifest is committed to enable incremental builds across workflow runs

**Critical:** The `is_file_processed()` function checks for documented files at `documented/` (repo root), NOT `output/latest/documented/`. This allows incremental builds to work with committed files.

### Directory Structure

```
documented/               # Committed YARD-documented Ruby files (mirrors lich-5/lib structure)
├── common/
├── gemstone/
├── dragonrealms/
└── ...

docs/                     # Generated HTML documentation (for GitHub Pages)

output/latest/            # Build artifacts
├── manifest.json         # Incremental build tracking (COMMITTED)
└── documented/           # Temporary staging during generation (not committed)

src/providers/            # LLM provider implementations
├── base.py               # Abstract provider interface
├── factory.py            # Provider selection and validation
├── openai_provider.py
├── anthropic_provider.py
├── gemini.py
└── mock.py               # For testing without API calls
```

### Python Scripts

**generate_docs.py** - Main documentation generator
- Processes Ruby files with AI to generate YARD comments
- Supports parallel processing (8 workers for OpenAI, 4 for Anthropic)
- Returns structured JSON: `[{line_number, anchor, indent, comment}, ...]`
- **Output structure:** Mirror mode (preserves source directory hierarchy)
- **Incremental logic:** Compares SHA256 hashes, checks `documented/` for existing files
- **Exclusions:** Skips `/critranks/` directory (large data tables consume too many tokens)

**validate_docs.py** - YARD validation wrapper
- Runs `yard stats` on documented files
- Parses warnings/errors into structured output
- **Exit strategy:** Always exits 0 (warns but continues) unless `--strict` mode
- Can validate all files or single file with `--file`

**build_html.py** - HTML documentation generator
- Runs `yard doc` to generate HTML from documented/ → docs/
- Verifies output (checks for index.html, counts files)
- **Clean flag:** Removes docs/ before building (does NOT touch output/latest/)

## GitHub Actions Workflows

### 1. generate-batch.yml - Batch Documentation Generation

**Purpose:** Generate YARD documentation for all Ruby files in lich-5 repository

**Inputs:**
- `provider`: LLM to use (openai, anthropic, gemini)
- `source_repo`: e.g., `elanthia-online/lich-5`
- `source_branch`: Branch to document (default: main)
- `full_rebuild`: Force reprocess all files (default: false)

**Key steps:**
1. Clone lich-5 repository to `lich-source/`
2. Manifest is already in repo at `output/latest/manifest.json` (from previous commit)
3. Run `generate_docs.py lich-source/lib --output-structure mirror`
4. Copy `output/latest/documented/*` → `documented/`
5. Commit `documented/` and updated `output/latest/manifest.json`

**Cost:** ~$0.00 for incremental (0 files if nothing changed), ~$0.50 for full rebuild (120 files)

### 2. generate-single.yml - Single File Generation

**Purpose:** Fast iteration on single file (seconds vs 9 minutes)

**Usage:** Specify relative path like `gemstone/psms/feat.rb`

### 3. validate-docs.yml - YARD Validation

**Purpose:** Validate documented files for YARD syntax errors

**Usage:**
- All files: Leave `file` input empty
- Single file: Specify path like `documented/global_defs.rb`

**Output:** Creates `warnings.txt` artifact with validation results

### 4. build-html.yml - HTML Generation

**Purpose:** Generate static HTML documentation website

**Inputs:**
- `title`: Documentation title (default: "Lich 5 Documentation")
- `clean`: Remove docs/ before building (default: true)

**Output:** Commits docs/ directory for GitHub Pages deployment

## Common Development Commands

### Local Setup

```bash
# Python dependencies
pip install -r requirements.txt

# Ruby YARD gem (required for validation and HTML generation)
gem install yard

# API key configuration
cp .env.example .env
# Edit .env and add your API key (OPENAI_API_KEY, ANTHROPIC_API_KEY, or GEMINI_API_KEY)
```

### Local Documentation Generation

```bash
# Full rebuild
python generate_docs.py /path/to/lich-5/lib \
  --provider openai \
  --output-structure mirror \
  --force-rebuild

# Incremental (skip unchanged files)
python generate_docs.py /path/to/lich-5/lib \
  --provider openai \
  --output-structure mirror

# Single file
python generate_docs.py \
  --file /path/to/lich-5/lib/gemstone/psms/feat.rb \
  --provider openai \
  --output-structure mirror
```

**Validate docs:**
```bash
# All files
python validate_docs.py --dir documented

# Single file
python validate_docs.py --file documented/global_defs.rb

# Strict mode (exit non-zero on warnings)
python validate_docs.py --dir documented --strict
```

**Build HTML:**
```bash
# Build to docs/
python build_html.py --input ./documented --output ./docs

# Clean before building
python build_html.py --input ./documented --output ./docs --clean

# Custom title
python build_html.py --input ./documented --output ./docs --title "My Documentation"
```

### Testing Provider Without API Calls

```bash
# Use mock provider (no API costs)
python generate_docs.py /path/to/source --provider mock
```

### Viewing Provider Status

```python
from providers import ProviderFactory

# Check which provider will be used
validation = ProviderFactory.validate_environment()
print(validation)  # Shows provider, API key status, warnings
```

## Important Patterns

### Manifest Management

The manifest tracks which files have been processed to enable incremental builds:

```json
{
  "processed_files": {
    "lich-source/lib/init.rb": {
      "timestamp": "2025-11-07T07:29:29",
      "provider": "openai",
      "content_hash": "9c27aeace5c73a06",
      "file_name": "init.rb"
    }
  },
  "failed_files": []
}
```

**To mark manually-fixed files as processed:**
1. Calculate content hash from source file (SHA256 of code, excluding comments)
2. Add entry to `processed_files` with proper metadata
3. Remove from `failed_files` array
4. Commit manifest

### Gitignore Pattern for Manifest

The `.gitignore` uses a specific pattern to allow manifest.json while ignoring other output:

```gitignore
output/*                      # Ignore all in output/
!output/latest/               # But allow latest/ subdirectory
output/latest/*               # Ignore everything in latest/
!output/latest/manifest.json  # Except manifest.json
```

This pattern is **required** because you cannot un-ignore a file inside an ignored directory.

### AI Prompt Guidelines

The generator includes strict rules to prevent common issues:

1. **Skip already-documented code:** Check for existing YARD tags before generating
2. **Parameter syntax:** Use `@param block` NOT `@param &block`, `@param args` NOT `@param *args`
3. **Exact parameter names:** Must match method signature exactly
4. **Validation:** Double-check parameter names before returning JSON

### YARD Cross-Reference Warnings

When building HTML, you may see "Cannot resolve link" warnings for references like `XMLData.game`, `DATA_DIR`, etc. These are **expected** because they reference objects defined outside the documented files (in Lich core runtime). The documentation will still work correctly - these links just won't be clickable.

## Troubleshooting

### "Output file missing, reprocessing" for all files

**Cause:** Script checking wrong location for documented files
**Fix:** Ensure `is_file_processed()` checks `Path('documented')` not `self.output_dir / 'documented'`

### Manifest not being committed

**Cause:** `.gitignore` pattern blocking manifest.json
**Fix:** Use the special gitignore pattern shown above (output/*, !output/latest/, output/latest/*, !manifest.json)

### Incremental builds reprocessing files unexpectedly

**Cause:** Hash mismatch between manifest and current source files
**Fix:** Source repository was updated - calculate new hashes from current lich-5 source and update manifest. The system correctly detects changes by comparing code hashes.

### YARD validation errors for duplicate @param

**Cause:** Generator not detecting existing documentation
**Fix:** Update AI prompt to skip already-documented methods

### Def ClassName.method causing YARD crashes

**Cause:** YARD parser issue with `def ClassName.method` inside class definition
**Fix:** Replace with `def self.method` (standard Ruby convention)

## Maintenance Notes

### When lich-5 Source Changes

1. Run **generate-batch.yml** workflow (incremental mode detects changes via SHA256 hash)
2. Run **validate-docs.yml** to check for YARD issues
3. Run **build-html.yml** to regenerate HTML documentation

### Provider Costs

- **OpenAI (gpt-4o-mini):** ~$0.50 full rebuild, ~$0.00 incremental
- **Anthropic (claude-3-haiku):** ~$0.25-1.00 full rebuild
- **Gemini (gemini-2.0-flash-exp):** Free but severe rate limits (~200 req/day)
- **Mock:** Free, for testing pipeline without API calls
