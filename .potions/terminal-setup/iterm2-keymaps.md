# iTerm2 Key Mappings for Potions

These key mappings should be added manually in iTerm2 Preferences.

## How to Add

1. Open iTerm2
2. Go to Preferences (Cmd+,) → Profiles → Keys → Key Mappings
3. Click "+" to add each mapping below

## Required Mappings

### Ctrl+Tab (Next Tmux Window)
- **Key Combination**: Press Ctrl+Tab when recording
- **Action**: Send Escape Sequence
- **Esc+**: `[27;5;9~`

### Ctrl+Shift+Tab (Previous Tmux Window)
- **Key Combination**: Press Ctrl+Shift+Tab when recording
- **Action**: Send Escape Sequence
- **Esc+**: `[27;6;9~`

## Optional Mappings (Already Work by Default)

### Ctrl+Right (Forward Word)
- Usually works by default
- If not: Send Escape Sequence `[1;5C`

### Ctrl+Left (Backward Word)
- Usually works by default
- If not: Send Escape Sequence `[1;5D`

## Option Key Configuration

For Alt+key combinations to work properly:

1. Go to Preferences → Profiles → Keys → General
2. Set "Left Option Key" to "Esc+"
3. Optionally set "Right Option Key" to "Esc+"

This allows Alt+f and Alt+b for word navigation.
