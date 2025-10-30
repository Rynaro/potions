# 🚀 Potions - AI Agent Quick Reference

## 🎯 Project at a Glance

**Potions** = Cross-platform dev environment setup tool  
**Platforms:** macOS, WSL, Termux, Debian/Linux  
**Language:** Bash  
**Philosophy:** Idempotent, user-safe, cross-platform

---

## ⚡ Critical Rules (MUST FOLLOW)

### 1. Idempotency 🔄
```bash
# ✅ Always check before installing
if ! command_exists package; then
  install_package package
fi
```

### 2. Platform Support 🌍
```bash
# ✅ Always detect platform
if is_macos; then
  brew install package
elif is_wsl || is_linux; then
  sudo apt-get install -y package
fi
```

### 3. User Data Safety 💾
```bash
# ✅ Always backup user files
if [ -f "$user_file" ]; then
  cp "$user_file" "$user_file.backup"
fi
```

### 4. Error Handling ⚠️
```bash
# ✅ Check commands
command || {
  log_error "Failed: command"
  exit 1
}
```

### 5. Path Resolution 📁
```bash
# ✅ Use variables, never hardcode
cd "$POTIONS_HOME"  # NOT: cd ~/.potions
source "$REPO_ROOT/packages/accessories.sh"  # NOT: source packages/accessories.sh
```

---

## 📦 Architecture

```
potions/
├── drink.sh              # One-line installer
├── install.sh            # Main installer
├── upgrade.sh            # Upgrade system
├── packages/
│   ├── accessories.sh    # 🔑 Core utilities (READ FIRST!)
│   ├── common/           # Cross-platform logic
│   ├── macos/            # macOS installers
│   ├── wsl/              # WSL installers
│   ├── termux/           # Termux installers
│   └── debian/           # Debian/Linux installers
└── plugins/              # Plugin system
```

---

## 🔧 Essential Functions

### Platform Detection
```bash
is_macos()      # Returns true if macOS
is_wsl()        # Returns true if WSL
is_termux()     # Returns true if Termux
is_linux()      # Returns true if Linux
```

### Utilities (from `accessories.sh`)
```bash
log(message)                    # Basic logging
command_exists(command)          # Check if command exists
safe_source(file)                # Source file if exists
ensure_directory(dir)            # Create directory
install_package(package)         # Install platform package
exit_with_message(message)       # Exit with error
```

### Logging (from `upgrade.sh`)
```bash
log_info(message)               # Info message
log_success(message)            # Success message
log_error(message)              # Error message
log_warning(message)            # Warning message
```

---

## 📝 Code Patterns

### Package Installation Script
```bash
#!/bin/bash
# packages/macos/example.sh

# Check if already installed
if command_exists example; then
  log "example is already installed."
  return 0
fi

# Install
log "Installing example..."
brew install example || {
  log_error "Failed to install example"
  return 1
}

# Verify
if ! command_exists example; then
  log_error "example installation may have failed"
  return 1
fi

log "example installation completed."
```

### Platform-Specific Logic
```bash
if is_macos; then
  brew install package
elif is_termux; then
  pkg install -y package
elif is_wsl || is_linux; then
  sudo apt-get install -y package
else
  log_error "Unsupported platform"
  exit 1
fi
```

### Safe File Operations
```bash
# Backup existing file
if [ -f "$target_file" ]; then
  cp "$target_file" "$target_file.backup"
fi

# Copy new file
cp "$source_file" "$target_file"
```

### Temporary Files
```bash
TEMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT
```

---

## 🚫 Common Mistakes

| ❌ WRONG | ✅ CORRECT |
|----------|-----------|
| `cd ~/.potions` | `cd "$POTIONS_HOME"` |
| `source packages/accessories.sh` | `source "$REPO_ROOT/packages/accessories.sh"` |
| `brew install package` | `if is_macos; then brew install package; fi` |
| `cp new_file ~/.zshrc` | Backup first, then copy |
| `make install` | `make install \|\| { log_error "..."; exit 1; }` |
| `echo "Done"` | `log_success "Done"` |

---

## 🧪 Testing Checklist

Before submitting code:
- [ ] ✅ Idempotent (runs twice without issues)
- [ ] ✅ All platforms supported (or clearly documented if not)
- [ ] ✅ Error handling (graceful failures)
- [ ] ✅ User data preserved (backups created)
- [ ] ✅ Script syntax valid (`bash -n script.sh`)
- [ ] ✅ Uses standardized logging
- [ ] ✅ No hardcoded paths

---

## 📚 Key Files to Read

1. **`packages/accessories.sh`** - Core utilities (always read first!)
2. **`install.sh`** - Main installation flow
3. **`upgrade.sh`** - Upgrade and backup logic
4. **`packages/macos/zsh.sh`** - Example package installer
5. **`README.md`** - User documentation

---

## 🎓 Quick Learning Path

1. Read `README.md` → Understand what Potions does
2. Read `install.sh` → See main flow
3. Read `packages/accessories.sh` → Learn utilities
4. Compare `packages/macos/zsh.sh` vs `packages/wsl/zsh.sh` → See platform differences
5. Read `upgrade.sh` → Understand upgrade/backup logic

---

## 💡 Tips

- **Always read `accessories.sh` first** - Contains core patterns
- **Look for similar implementations** - Don't reinvent the wheel
- **Test incrementally** - One platform at a time
- **Think about users** - Preserve their data, clear error messages
- **Document complex logic** - Comments explain WHY, not WHAT

---

## 🔗 Related Documents

- **`AGENT.md`** - Comprehensive agent guide (full details)
- **`.cursorrules`** - Cursor IDE specific rules
- **`README.md`** - User-facing documentation
- **`CHEATSHEET.md`** - User keybindings reference

---

**Remember:** Potions is about **developer productivity**. Every change should make it more reliable, faster, or easier to use.
