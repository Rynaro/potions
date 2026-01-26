# Potions AI Agent Guide

> One command. Powerful dev environment. Any platform.

This document guides AI coding assistants working on Potions. It's designed to be platform-agnostic and works with any AI coding tool (Cursor, GitHub Copilot, Codeium, Continue, Windsurf, etc.).

**What is Potions?** A cross-platform development environment setup tool that installs and configures Zsh, Git, NeoVim, Tmux on macOS, WSL, Termux, Debian/Linux, and Fedora systems.

---

## Table of Contents

1. [Security-First Development](#-security-first-development)
2. [Core Principles](#core-principles)
3. [Architecture](#architecture)
4. [Code Standards](#code-standards)
5. [Common Patterns](#common-patterns)
6. [API Reference](#api-reference)
7. [Anti-Patterns](#anti-patterns)
8. [Testing Requirements](#testing-requirements)
9. [Security Checklist](#security-checklist)
10. [Quick Reference](#quick-reference)

---

## 🔒 Security-First Development

Potions installs software and modifies user configurations. Security is paramount.

### Critical Security Rules

| Rule | Description |
|------|-------------|
| **Never eval untrusted input** | All inputs must be validated before use |
| **Quote all variables** | Prevent word splitting and globbing attacks: `"$VAR"` not `$VAR` |
| **Verify checksums** | Critical files are SHA256 verified during upgrades |
| **Backup before modify** | User files MUST be backed up before overwriting |
| **Minimal sudo** | Document and minimize privilege escalation |
| **No hardcoded secrets** | Never commit credentials, tokens, or API keys |
| **Validate paths** | Prevent path traversal attacks; always sanitize user input |

### Checksum Verification

Critical files are protected by SHA256 checksums in `.checksums`. This ensures file integrity during upgrades and prevents tampering.

#### Critical Requirements

**The `.checksums` file MUST always be sorted alphabetically.** The CI validation compares the committed file with a freshly generated (sorted) version. If the order differs, validation will fail even if checksums are correct.

**Never manually edit `.checksums`.** Always use `./scripts/generate-checksums.sh` which:
- Calculates SHA256 checksums for all critical files
- Sorts entries alphabetically using `LC_ALL=C sort` for consistency
- Ensures the file format matches CI expectations

#### When to Update Checksums

Update checksums when:
- **Version changes** - Always update `.checksums` when bumping `.version`
- **Critical files modified** - Any changes to protected files require checksum updates
- **New critical files added** - Add to `CRITICAL_FILES` array in `generate-checksums.sh`

#### Step-by-Step Process

1. **Make your changes** to critical files or version
2. **Run the script**: `./scripts/generate-checksums.sh`
   - This calculates new checksums and sorts them correctly
   - The script uses `LC_ALL=C sort` for consistent ASCII sorting across platforms
3. **Verify the output** - Check that `.checksums` is sorted (files starting with `.` come first)
4. **Commit together** - Always commit `.checksums` alongside file changes in the same commit
5. **Test locally** - Run `LC_ALL=C sort .checksums | diff - .checksums` to verify it's sorted

#### Why Sorting Matters

The CI workflow (`version-checksum-validation.yml`) generates expected checksums and sorts them. It then compares the committed `.checksums` file using `diff`. If the order differs:
- `diff` will report differences even though checksums match
- CI validation fails with "Checksums file is outdated" error
- The PR may pass (if checksums are correct but unsorted), but main branch CI will fail

#### Files Protected by Checksums

The following files are tracked in `.checksums`:
- `drink.sh` - Remote installer
- `install.sh` - Main installer
- `upgrade.sh` - Upgrade script
- `plugins.sh` - Plugin manager
- `.version` - Version file
- `.potions/.zshrc` - Zsh configuration
- `.potions/bin/potions` - Potions binary

When modifying any of these files, you MUST update `.checksums`.

---

## Core Principles

### 1. Idempotency (Non-Negotiable)

Every script MUST be safe to run multiple times without side effects.

```bash
# ✅ Good: Check before creating
if [ ! -d "$dir" ]; then
  mkdir -p "$dir"
fi

# ✅ Good: Use ensure_directory
ensure_directory "$dir"

# ❌ Bad: Always creates (fails on second run)
mkdir "$dir"
```

### 2. Cross-Platform Support

All code MUST work on: **macOS**, **WSL**, **Termux**, **Debian/Linux**, **Fedora**.

```bash
# ✅ Good: Platform detection
if is_macos; then
  brew install package
elif is_termux; then
  pkg install package
elif is_wsl; then
  sudo apt-get install -y package
elif is_fedora; then
  sudo dnf install -y package
elif is_linux; then
  sudo apt-get install -y package
fi

# ❌ Bad: Platform assumption
brew install package  # Fails on Linux
```

### 3. User Data Safety

NEVER lose user data. Always backup, always preserve customizations.

```bash
# ✅ Good: Backup before overwriting
if [ -f "$user_file" ]; then
  cp "$user_file" "$user_file.backup"
fi
cp "$new_file" "$user_file"

# ❌ Bad: Overwrites without backup
cp "$new_file" "$user_file"
```

### 4. Graceful Failure

Fail with helpful messages. Clean up after failures.

```bash
# ✅ Good: Helpful error message
if ! command_exists git; then
  log_error "Git is required but not installed. Please install git first."
  exit 1
fi

# ❌ Bad: Cryptic failure
git clone repo  # Just fails if git missing
```

### 5. Single Responsibility

Each function/script does one thing well.

---

## Architecture

### Core Files

| File | Purpose | Read Order |
|------|---------|------------|
| `packages/accessories.sh` | Core utilities, platform detection | **READ FIRST** |
| `install.sh` | Main installation orchestrator | 2nd |
| `upgrade.sh` | Safe upgrade with backup | 3rd |
| `drink.sh` | One-line remote installer | Reference |
| `plugins.sh` | Plugin management system | As needed |

### Package Structure

```
packages/
├── accessories.sh      # Core utilities - READ FIRST
├── common/             # Cross-platform shared logic
│   ├── antidote.sh
│   ├── git.sh
│   ├── neovim.sh
│   └── ...
├── macos/              # macOS-specific installers
├── wsl/                # WSL-specific installers
├── termux/             # Termux-specific installers
├── debian/             # Debian/Linux-specific installers
└── fedora/             # Fedora (dnf) installers
```

On Fedora, Neovim is installed via `dnf install neovim` (distro package). Other platforms may build from source. Prefer distro packages when available to reduce install overhead. `update_repositories` uses `sudo dnf makecache` on Fedora and `apt-get update` on apt-based systems.

### User Configuration (Preserved on Upgrade)

These files are **never overwritten** during upgrades:

| File | Purpose |
|------|---------|
| `config/aliases.zsh` | User-defined shell aliases |
| `config/secure.zsh` | Private configs (gitignored) |
| `config/local.zsh` | Local machine-specific settings |
| `nvim/user.vim` | User's NeoVim extensions |
| `tmux/user.conf` | User's Tmux customizations |

### Plugin System

```
plugins/
├── install.sh          # Plugin installation logic
├── manage.sh           # Plugin management commands
├── obtain.sh           # Plugin fetching
├── generators.sh       # Plugin scaffolding
├── utilities.sh        # Plugin helper functions
└── templates/          # Plugin templates
```

---

## Code Standards

### Bash Scripting

```bash
#!/bin/bash

# Use strict mode for error handling
set -eo pipefail

# Quote all variables
local name="$1"
echo "Hello, $name"

# Use local for function-scoped variables
my_function() {
  local result=""
  result=$(some_command)
  echo "$result"
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Functions | `snake_case` | `install_package`, `is_macos` |
| Constants | `UPPER_SNAKE_CASE` | `POTIONS_HOME`, `REPO_ROOT` |
| Local variables | `lower_snake_case` | `user_file`, `package_name` |
| Files | `lowercase.sh` | `install.sh`, `accessories.sh` |
| Directories | `lowercase` | `packages`, `common` |

### File Organization

```bash
#!/bin/bash

# 1. Header comments (purpose, author)
# Package installation script for XYZ
# Handles cross-platform installation

# 2. Source dependencies
source "$(dirname "$0")/packages/accessories.sh"

# 3. Global constants
readonly MY_CONSTANT="value"

# 4. Helper functions
helper_function() {
  local arg="$1"
  # ...
}

# 5. Main logic
main() {
  # ...
}

# 6. Entry point
main "$@"
```

---

## Common Patterns

### Platform-Specific Code

```bash
if is_macos; then
  brew install package
elif is_termux; then
  pkg install package
elif is_wsl; then
  sudo apt-get install -y package
elif is_fedora; then
  sudo dnf install -y package
elif is_linux; then
  sudo apt-get install -y package
fi
```

### Package Installation

```bash
# Preferred: Use the install_package function
install_package git

# With pre-check
if ! command_exists git; then
  install_package git
fi
```

### File Operations with Backup

```bash
backup_and_copy() {
  local src="$1"
  local dest="$2"
  
  if [ -f "$dest" ]; then
    cp "$dest" "$dest.backup"
    log "Backed up $dest to $dest.backup"
  fi
  
  cp "$src" "$dest"
}
```

### Cleanup Pattern

```bash
TEMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Use TEMP_DIR for temporary files
# Automatically cleaned up on exit (success or failure)
```

### Logging

```bash
# From accessories.sh
log "Basic message"                    # Timestamped log

# From upgrade.sh (when available)
log_info "Information"                 # Blue info message
log_success "Success message"          # Green success
log_error "Error message"              # Red error
log_warning "Warning message"          # Yellow warning
log_step "Section Title"               # Section header
```

### Path Resolution

```bash
# ✅ Good: Use defined variables
cd "$POTIONS_HOME"
source "$REPO_ROOT/packages/accessories.sh"

# ❌ Bad: Hardcoded paths
cd ~/.potions
source packages/accessories.sh
```

---

## API Reference

### From `packages/accessories.sh`

#### Platform Detection

| Function | Returns true if... |
|----------|-------------------|
| `is_macos` | Running on macOS |
| `is_wsl` | Running in Windows Subsystem for Linux |
| `is_termux` | Running in Termux on Android |
| `is_linux` | Running on any Linux-based system |
| `is_fedora` | Running on Fedora (or Fedora-based) |
| `is_dnf_package_manager` | dnf is available |
| `is_apt_package_manager` | apt is available |

#### Core Utilities

| Function | Purpose | Example |
|----------|---------|---------|
| `log(msg)` | Timestamped logging | `log "Installing..."` |
| `command_exists(cmd)` | Check if command available | `if command_exists git; then` |
| `safe_source(file)` | Source file if exists | `safe_source "$config"` |
| `install_package(pkg)` | Cross-platform install | `install_package git` |
| `ensure_directory(dir)` | Create dir if not exists | `ensure_directory "$dir"` |
| `ensure_files(dir, files...)` | Create files if not exist | `ensure_files "$dir" "file1" "file2"` |
| `unpack_it(package)` | Source common package script | `unpack_it "git"` |
| `exit_with_message(msg)` | Log error and exit 1 | `exit_with_message "Failed"` |
| `update_repositories` | Update package manager repos | `update_repositories` |

#### Environment Variables

| Variable | Description |
|----------|-------------|
| `POTIONS_HOME` | User's potions directory (`~/.potions`) |
| `REPO_ROOT` | Repository root directory |
| `SCRIPT_DIR` | Current script's directory |
| `OS_TYPE` | Result of `uname -s` |
| `ZDOTDIR` | Zsh configuration directory |

---

## Anti-Patterns

### ❌ DON'T

| Anti-Pattern | Problem | Solution |
|-------------|---------|----------|
| `cd ~/.potions` | Hardcoded path | Use `cd "$POTIONS_HOME"` |
| `source packages/accessories.sh` | Assumes current dir | Use `source "$REPO_ROOT/packages/accessories.sh"` |
| `make install` | No error check | Use `make install \|\| { log_error "..."; exit 1; }` |
| `cp new ~/.zshrc` | Overwrites user data | Backup first |
| `brew install pkg` | Platform assumption | Use `install_package` or platform detection |
| Create temp files without cleanup | Leaves garbage | Use `trap cleanup EXIT` |
| Mix `echo` and `log` | Inconsistent output | Use `log*` functions |
| `eval "$user_input"` | Code injection risk | Never eval untrusted input |

### ✅ DO

```bash
# Use variables for paths
cd "$POTIONS_HOME"

# Resolve paths properly
source "$REPO_ROOT/packages/accessories.sh"

# Check errors
command || { log_error "Command failed"; exit 1; }

# Backup before overwrite
[ -f "$file" ] && cp "$file" "$file.backup"
cp "$new_file" "$file"

# Platform detection
if is_macos; then
  brew install package
fi

# Cleanup pattern
trap cleanup EXIT

# Consistent logging
log "Message"
log_error "Error"
```

---

## Testing Requirements

### Before Committing

- [ ] **Syntax validation**: `bash -n script.sh`
- [ ] **Full test suite**: `./test.sh`
- [ ] **Idempotency test**: Run script twice, verify no errors
- [ ] **Error scenarios**: Test with missing dependencies
- [ ] **User data preservation**: Verify backups are created
- [ ] **Checksums**: Update `.checksums` if critical files changed

### CI/CD Pipeline

The GitHub Actions workflow validates:

1. Syntax validation on all `.sh` files
2. Cross-platform tests (Ubuntu, macOS, Fedora, Termux)
3. Idempotency verification
4. Checksum verification (`.checksums` vs actual files)

#### Termux CI Testing

Termux testing runs in CI using GitHub's native ARM64 runners with the official `termux/termux-docker:aarch64` Docker image:

**How it works:**
- Uses native ARM64 GitHub runners (`ubuntu-24.04-arm`) - no QEMU emulation needed
- Runs `termux-docker:aarch64` container natively on ARM64 hardware
- Uses `/entrypoint.sh` to ensure proper privilege dropping to `system` user
- Runs in privileged mode (required for termux-docker's dnsmasq)
- Executes full integration tests (actual install, not simulation)
- Validates Termux-specific behaviors:
  - Platform detection (`is_termux()`)
  - Package installation via `pkg` command
  - Shell setup via `~/.termux/shell` file
  - Environment variables (`$PREFIX`, `termux-info`)

**Why native ARM64 runners?**
- QEMU emulation on x86 runners was unstable (dnsmasq failures, container startup issues)
- GitHub provides free ARM64 runners for public repositories (since August 2025)
- Native execution is faster and more reliable than emulation

**Running Termux tests locally:**

On ARM64 machines (Apple Silicon Mac, ARM Linux):
```bash
# Run Termux container with tests (native, no emulation needed)
docker run --rm --privileged \
  -v "$PWD:/workspace" \
  termux/termux-docker:aarch64 \
  /entrypoint.sh bash -c "cd /workspace && ./test.sh --no-simulate && ./install.sh"
```

On x86 machines (requires QEMU, may be unstable):
```bash
# Set up QEMU for ARM emulation (one-time setup)
docker run --rm --privileged aptman/qus -s -- -p aarch64

# Run Termux container with tests
docker run --rm --privileged \
  -v "$PWD:/workspace" \
  termux/termux-docker:aarch64 \
  /entrypoint.sh bash -c "cd /workspace && ./test.sh --no-simulate && ./install.sh"
```

**Important notes:**
- Always use `/entrypoint.sh` to invoke commands - this ensures proper privilege dropping
- The CI job has `continue-on-error: true` while stabilizing the pipeline
- Some Termux-specific features may not work in Docker (Android runtime components)

### Debugging Tips

```bash
# Enable command tracing
set -x

# Check key variables
echo "POTIONS_HOME: $POTIONS_HOME"
echo "REPO_ROOT: $REPO_ROOT"
echo "SCRIPT_DIR: $SCRIPT_DIR"

# Verify platform detection
is_macos && echo "macOS" || echo "Not macOS"
is_wsl && echo "WSL" || echo "Not WSL"
is_termux && echo "Termux" || echo "Not Termux"
is_fedora && echo "Fedora" || echo "Not Fedora"
```

---

## Security Checklist

### Pre-Commit Validation

Before every commit, verify:

- [ ] **No hardcoded credentials** - No tokens, passwords, API keys
- [ ] **All variables quoted** - `"$var"` not `$var`
- [ ] **No eval with untrusted data** - Never `eval "$user_input"`
- [ ] **Checksums updated** - Run `./scripts/generate-checksums.sh` if needed
- [ ] **Checksums sorted** - Verify `.checksums` is alphabetically sorted (use `LC_ALL=C sort .checksums | diff - .checksums` to verify)
- [ ] **Never manually edit `.checksums`** - Always use the script to ensure proper formatting and sorting
- [ ] **User files backed up** - Backup logic before any overwrite
- [ ] **Error messages safe** - Don't leak paths or sensitive info
- [ ] **Sudo usage documented** - Explain why privilege escalation is needed
- [ ] **Temp files cleaned** - Use `trap cleanup EXIT`

### Sensitive Files

These files may contain sensitive data and are gitignored:

- `config/secure.zsh` - User secrets
- `config/local.zsh` - Local overrides
- `.potions/sources/*.sh` - Platform-specific sources

---

## Quick Reference

### Adding a New Package

1. Create platform-specific installers:
   ```
   packages/macos/mypackage.sh
   packages/debian/mypackage.sh
   packages/fedora/mypackage.sh
   packages/wsl/mypackage.sh
   packages/termux/mypackage.sh
   ```

2. Optionally create shared logic:
   ```
   packages/common/mypackage.sh
   ```

3. Add to `install.sh` package list

4. Test on all platforms (or at least macOS + Linux)

### Modifying User Config Files

1. Update template in `.potions/`
2. Ensure `upgrade.sh` preserves user customizations
3. Test upgrade path from previous version
4. Update `.checksums` if file is protected

### Creating a Plugin

1. Use the plugin scaffold: `./plugins.sh scaffold my-plugin`
2. Implement the plugin in `plugins/my-plugin/`
3. Test installation and uninstallation
4. Document in plugin README

### Known Limitations

- **Fedora in WSL**: WSL is always treated as `wsl` (apt). Fedora running inside WSL still uses apt-based logic. Native Fedora uses dnf.

### Common Commands

```bash
# Install Potions
./install.sh

# Upgrade Potions
./upgrade.sh

# Run tests
./test.sh

# Generate checksums
./scripts/generate-checksums.sh

# Validate syntax of all scripts
find . -name "*.sh" -exec bash -n {} \;
```

---

## For AI Agents: Decision Framework

When working on Potions, ask yourself:

1. **Platform**: Does this work on macOS, WSL, Termux, Debian, AND Fedora?
2. **Idempotency**: Can I run this twice without errors?
3. **User Data**: Am I backing up before modifying user files?
4. **Errors**: What happens if this fails? Is the message helpful?
5. **Security**: Am I quoting variables? Validating input? Avoiding eval?
6. **Cleanup**: Am I cleaning up temporary files?
7. **Existing Code**: Is there already a utility function for this?

### Key Files to Read First

1. `packages/accessories.sh` - Core utilities and patterns
2. `install.sh` - Main installation flow
3. `upgrade.sh` - Upgrade logic and logging functions

### Existing Patterns

Before implementing something new, check if a pattern already exists:

- **Package installation** → `install_package()`
- **Platform detection** → `is_macos()`, `is_wsl()`, `is_fedora()`, etc.
- **Directory creation** → `ensure_directory()`
- **Safe file sourcing** → `safe_source()`
- **Logging** → `log()`, `log_error()`, etc.

---

*This document is the single source of truth for AI agents working on Potions. Keep it updated as the project evolves.*
