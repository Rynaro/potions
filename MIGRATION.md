# Migration Guide - Potions v2.5.0

This document describes the breaking changes in Potions v2.5.0 and how to migrate from previous versions.

---

## What's Changed

### 1. Configuration Directory Restructure

**Old Structure:**
```
~/.potions/
├── .zsh_aliases           # Custom aliases
├── .zsh_secure_aliases    # Private aliases
└── sources/
    ├── macos.sh
    ├── linux.sh
    ├── wsl.sh
    └── termux.sh
```

**New Structure:**
```
~/.potions/
├── config/                 # NEW: All user customizations
│   ├── aliases.zsh        # Custom aliases
│   ├── secure.zsh         # Private aliases (gitignored)
│   ├── local.zsh          # Machine-specific settings
│   ├── macos.zsh          # macOS-specific
│   ├── linux.zsh          # Linux-specific
│   ├── wsl.zsh            # WSL-specific
│   └── termux.zsh         # Termux-specific
├── nvim/
│   ├── init.vim           # Managed config
│   └── user.vim           # NEW: User extensions
├── tmux/
│   ├── tmux.conf          # Managed config
│   └── user.conf          # NEW: User extensions
└── ... (existing files)
```

**Migration:** Run `./migrate.sh` or the migration will happen automatically on upgrade.

### 2. Keybinding Changes

Several keybindings have been changed to resolve conflicts:

| Old Binding | New Binding | Context | Reason |
|-------------|-------------|---------|--------|
| `Ctrl+n` | `Ctrl+a n` | Tmux | Conflicts with shell history & NERDTree |
| `Ctrl+p` | `Ctrl+a p` | Tmux | Conflicts with shell history & buffer pick |
| `Ctrl+p` | `Space bp` | Neovim | Buffer pick, avoid Tmux conflict |
| `Ctrl+x` | `Space bx` | Neovim | Buffer delete, avoid cut conflict |
| `Ctrl+d` | `Space d` | Neovim | Multi-cursor start, avoid scroll conflict |
| `Ctrl+x` | `Space x` | Neovim | Multi-cursor skip, avoid cut conflict |
| `C-a-h/l` | `<` / `>` | Tmux | Swap pane syntax fixed |

**Note:** The old bindings may still work in some contexts for backwards compatibility.

### 3. New User Extension Files

You can now customize Neovim and Tmux without editing the main config files:

- `~/.potions/nvim/user.vim` - Add your Neovim customizations here
- `~/.potions/tmux/user.conf` - Add your Tmux customizations here

These files are preserved on upgrade and loaded after the main configuration.

---

## Automatic Migration

When you upgrade to v2.5.0, Potions will:

1. **Detect legacy files** - Looks for `.zsh_aliases`, `.zsh_secure_aliases`, and `sources/` directory
2. **Create backups** - Saves your existing files before making changes
3. **Migrate content** - Copies your customizations to the new structure
4. **Preserve originals** - Legacy files continue to work for backwards compatibility

---

## Manual Migration

If you prefer to migrate manually:

### Step 1: Create New Config Directory

```bash
mkdir -p ~/.potions/config
```

### Step 2: Migrate Aliases

```bash
# Move aliases
cp ~/.potions/.zsh_aliases ~/.potions/config/aliases.zsh

# Move secure aliases
cp ~/.potions/.zsh_secure_aliases ~/.potions/config/secure.zsh
```

### Step 3: Migrate Platform Configs

```bash
# For macOS users
cp ~/.potions/sources/macos.sh ~/.potions/config/macos.zsh

# For Linux users
cp ~/.potions/sources/linux.sh ~/.potions/config/linux.zsh

# For WSL users
cp ~/.potions/sources/wsl.sh ~/.potions/config/wsl.zsh

# For Termux users
cp ~/.potions/sources/termux.sh ~/.potions/config/termux.zsh
```

### Step 4: Create User Extension Files

```bash
# Create empty user extension files
touch ~/.potions/nvim/user.vim
touch ~/.potions/tmux/user.conf
touch ~/.potions/config/local.zsh
```

### Step 5: Restart Terminal

```bash
exec zsh
```

---

## Reverting Changes

If you encounter issues after migration, you can restore from backup:

```bash
# Find your backup
ls ~/.potions/backups/

# Restore from backup
cp -r ~/.potions/backups/pre-migration-YYYYMMDD-HHMMSS/* ~/.potions/
```

---

## New Keybinding Reference

### Tmux Window Navigation (Changed)

| Old | New | Notes |
|-----|-----|-------|
| `Ctrl+n` (no prefix) | `Ctrl+a n` (with prefix) | Or use `Ctrl+Tab` |
| `Ctrl+p` (no prefix) | `Ctrl+a p` (with prefix) | Or use `Ctrl+Shift+Tab` |

### Tmux Pane Swapping (Fixed)

| Old (Broken) | New (Fixed) |
|--------------|-------------|
| `Ctrl+a C-a-h` | `Ctrl+a <` |
| `Ctrl+a C-a-l` | `Ctrl+a >` |

### Neovim Buffer Management (Changed)

| Old | New | Action |
|-----|-----|--------|
| `Ctrl+p` | `Space bp` | Buffer picker |
| `Ctrl+x` | `Space bx` | Buffer delete picker |
| - | `Space bi` | Pin buffer (was `Space bp`) |

### Neovim Multi-Cursor (Changed)

| Old | New | Action |
|-----|-----|--------|
| `Ctrl+d` | `Space d` | Find/select next |
| `Ctrl+x` | `Space x` | Skip occurrence |

---

## FAQ

### Q: Will my old config files still work?

**A:** Yes! Legacy files (`.zsh_aliases`, `sources/*.sh`) are still loaded for backwards compatibility. You can use either the old or new structure, or both.

### Q: Do I have to migrate?

**A:** No. The old structure continues to work. However, the new structure is recommended for better organization and is the format used going forward.

### Q: What happens if I have both old and new files?

**A:** Both are loaded. Legacy files are loaded first, then new config files. If you have the same alias defined in both, the new config file will override it.

### Q: Are my customizations preserved on upgrade?

**A:** Yes. Both old (`sources/*.sh`) and new (`config/*.zsh`) files are preserved on upgrade.

---

## Getting Help

If you encounter issues during migration:

1. Check your backup at `~/.potions/backups/`
2. Review this migration guide
3. Open an issue at https://github.com/Rynaro/potions/issues
