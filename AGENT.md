# 🧪 Potions - AI Agent Instructions

**Purpose:** Practical guide for AI agents coding in Potions codebase  
**Format:** Agentic coding patterns, decision trees, actionable rules

---

## 🎯 Core Context

**Potions** = Cross-platform dev environment installer (macOS, WSL, Termux, Debian/Linux)  
**Architecture:** Modular bash scripts with platform-specific installers  
**Critical Rules:** Idempotency, platform support, user data safety

**Key Files:**
- `packages/accessories.sh` - Core utilities (read first!)
- `install.sh` - Main installer flow
- `upgrade.sh` - Upgrade/backup logic
- `packages/{platform}/{package}.sh` - Platform installers

**Important:** AI agent documentation files (`AGENT.md`, `AGENT_QUICK_REF.md`, `.cursorrules`, `.cursor/`) are **git-only** and **never deployed** to user installations. They exist only in the repository for development purposes.

---

## ⚡ Critical Rules (MUST FOLLOW)

### 1. Idempotency
```bash
# ✅ ALWAYS check before installing
if ! command_exists package; then
  install_package package
fi

# ✅ Use existing function (handles idempotency)
install_package package_name
```

### 2. Platform Support
```bash
# ✅ ALWAYS detect platform first
if is_macos; then
  brew install package
elif is_termux; then
  pkg install -y package
elif is_wsl || is_linux; then
  sudo apt-get install -y package
fi
```

### 3. User Data Safety
```bash
# ✅ ALWAYS backup before overwriting
if [ -f "$user_file" ]; then
  cp "$user_file" "$user_file.backup"
fi
cp "$new_file" "$user_file"
```

### 4. Path Resolution
```bash
# ✅ Use variables from accessories.sh
cd "$POTIONS_HOME"           # NOT: cd ~/.potions
source "$REPO_ROOT/packages/accessories.sh"  # NOT: source packages/accessories.sh
```

### 5. Error Handling
```bash
# ✅ Check exit codes
command || {
  log_error "Operation failed"
  return 1  # or exit 1 if critical
}

# ✅ Cleanup temp files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
```

---

## 🔧 Essential Functions Reference

**From `packages/accessories.sh`:**
```bash
log(message)                 # Basic logging: log "Installing..."
command_exists(cmd)           # Check: if command_exists git; then
safe_source(file)             # Source: safe_source "packages/file.sh"
ensure_directory(dir)         # Create: ensure_directory "$POTIONS_HOME"
install_package(pkg)          # Install: install_package git
is_macos(), is_wsl(), is_termux(), is_linux()  # Platform detection
exit_with_message(msg)        # Exit: exit_with_message "Critical error"
```

**From `upgrade.sh`:**
```bash
log_info(msg), log_success(msg), log_error(msg), log_warning(msg)
```

---

## 📝 Code Patterns

### Standard Package Installer
```bash
#!/bin/bash
# packages/macos/example.sh

if command_exists example; then
  log "example is already installed."
  return 0
fi

log "Installing example..."
brew install example || {
  log_error "Failed to install example"
  return 1
}

if ! command_exists example; then
  log_error "example installation may have failed"
  return 1
fi

log "example installation completed."
```

### Platform-Specific Block
```bash
if is_macos; then
  # macOS-specific code
elif is_termux; then
  # Termux-specific code
elif is_wsl || is_linux; then
  # Linux/WSL code
else
  log_error "Unsupported platform"
  exit 1
fi
```

### File Operations (with backup)
```bash
# Always backup user files
if [ -f "$target" ]; then
  cp "$target" "$target.backup"
fi
cp "$source" "$target"
```

---

## 🚫 Anti-Patterns (NEVER DO)

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `cd ~/.potions` | `cd "$POTIONS_HOME"` |
| `source packages/accessories.sh` | `source "$REPO_ROOT/packages/accessories.sh"` |
| `brew install package` | `if is_macos; then brew install package; fi` |
| `cp new_file ~/.zshrc` | Backup first, then copy |
| `make install` | `make install \|\| { log_error "..."; exit 1; }` |
| `echo "Done"` | `log_success "Done"` |

---

## 🎯 Decision Trees

### Adding a New Package
```
1. Create platform files: packages/{macos,wsl,termux,debian}/package.sh
2. Check existing pattern: Look at packages/macos/zsh.sh
3. Follow pattern:
   - Check if installed (idempotency)
   - Install platform-specific way
   - Verify installation
   - Log results
4. Add to install.sh: Add 'package' to packages array
5. Test: Run install.sh twice (idempotency check)
```

### Modifying Configuration Files
```
1. Update template: .potions/config_file
2. Check upgrade.sh: Ensure preserve_user_files() handles it
3. Add to preserved_files array if user-editable
4. Test upgrade: Run upgrade.sh, verify backups created
```

### Error Handling Decision
```
Is error critical (breaks installation)?
├─ YES → Use exit_with_message() or exit 1
└─ NO  → Log warning/error, return 1, continue

Should operation be retried?
├─ YES → Add retry logic with limits
└─ NO  → Log and fail gracefully
```

---

## 🔍 Codebase Search Strategies

**Semantic queries:**
- "How is package installation handled across platforms?"
- "Where are user customizations preserved during upgrade?"
- "How are platform-specific installers invoked?"

**Pattern matching:**
- Find similar: `grep -r "install_package" packages/`
- Check utilities: `read packages/accessories.sh`
- Compare platforms: `diff packages/macos/package.sh packages/wsl/package.sh`

---

## ✅ Pre-Submit Checklist

- [ ] Idempotent (run script twice → no errors)
- [ ] All platforms supported (macOS, WSL, Termux, Debian)
- [ ] Error handling (graceful failures with messages)
- [ ] User data preserved (backups created)
- [ ] Uses standardized logging (`log_*` functions)
- [ ] No hardcoded paths (uses `$POTIONS_HOME`, `$REPO_ROOT`)
- [ ] Platform detection (uses `is_*()` functions)
- [ ] Temp files cleaned (`trap cleanup EXIT`)

---

## 🌳 Tree of Thoughts: Problem Solving

### When Implementing Features

**Step 1: Understand**
- What platforms affected?
- Is it idempotent?
- Does it preserve user data?

**Step 2: Explore**
- Find similar implementations
- Check utilities in `accessories.sh`
- Review platform differences

**Step 3: Implement**
- Follow existing patterns
- Add error handling
- Include logging

**Step 4: Validate**
- Test idempotency
- Test all platforms
- Test error scenarios

### Example: Adding Python Package
```
Problem: Install Python 3.12
├─ Understand: All platforms, check existing Python
├─ Explore: Look at git.sh or zsh.sh for pattern
├─ Solutions:
│   ├─ System package manager (simple, version varies)
│   ├─ Build from source (consistent, complex)
│   └─ pyenv (version mgmt, additional dependency)
├─ Decision: System package + version check
└─ Implement: Create 4 platform files + verify
```

---

## 👀 Quick Reference

**Essential Variables:**
- `$POTIONS_HOME` - User config dir (`~/.potions`)
- `$REPO_ROOT` - Repository root
- `$SCRIPT_DIR` - Current script directory
- `$OS_TYPE` - OS type (`Darwin`, `Linux`)

**Common Operations:**
- Install package: `install_package package_name`
- Log message: `log "message"` or `log_success "message"`
- Check command: `command_exists command_name`
- Platform check: `is_macos && echo "macOS"`

**File Locations:**
- User configs: `$POTIONS_HOME/`
- Package scripts: `packages/{platform}/`
- Common logic: `packages/common/`
- Utilities: `packages/accessories.sh`

---

**Remember:** Potions prioritizes developer productivity. Every change must be idempotent, cross-platform, and user-safe. Always think: "Can this run twice safely? Does it work on all platforms? Is user data preserved?"

**For detailed examples and extended documentation, see `AGENT_QUICK_REF.md`.**
