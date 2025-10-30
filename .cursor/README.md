# Cursor IDE Configuration for Potions

This directory contains Cursor-specific configuration files. However, the main configuration files are in the repository root:

## Files

- **`.cursorrules`** (in repo root) - Cursor IDE rules and patterns
- **`AGENT.md`** (in repo root) - Comprehensive AI agent instructions
- **`AGENT_QUICK_REF.md`** (in repo root) - Quick reference guide

## Usage

Cursor will automatically read `.cursorrules` from the repository root. This file contains:
- Code style guidelines
- Critical requirements (idempotency, platform support, etc.)
- Common patterns and anti-patterns
- Function references
- Testing requirements

## For AI Agents

When working on Potions in Cursor:

1. **Read `.cursorrules` first** - Quick overview of rules
2. **Reference `AGENT.md`** - Detailed explanations and examples
3. **Use `AGENT_QUICK_REF.md`** - Quick lookup during coding

## Cursor Features Used

- **Semantic Search** - Use for finding similar implementations
- **Codebase Understanding** - Leverages RAG from these docs
- **Composer** - Uses rules from `.cursorrules` for code generation

---

See `AGENT.md` for comprehensive documentation.
