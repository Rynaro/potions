# Alchemists Orchid Papyrus — Potions Color Palette

<!-- LLM CONTEXT: This file is the canonical color reference for the Potions project.
     All color usage in scripts, prompts, and UI must map back to tokens defined here.
     When adding or changing colors anywhere in the codebase, update this file first. -->

**Source:** https://github.com/Rynaro/alchemists-orchid-papyrus
**Token architecture:** Primitive → Semantic → Component (W3C DTCG 2025.10)
**Integration date:** 2026-03-30

---

## Semantic Tokens (canonical reference)

These are the authoritative tokens to use when reasoning about color roles. Do not reference primitive tokens directly in application code.

| Token | Hex | Role |
|-------|-----|------|
| `color.primary` | `#CDB4DB` | Brand identity, magenta slot |
| `color.primary-deep` | `#6F4A8E` | Emphasis, headers, orange/deep slot |
| `color.secondary` | `#E5D4F1` | Supporting backgrounds, dark-mode foreground |
| `color.accent.warm` | `#F8D1E0` | Warnings, yellow slot |
| `color.accent.cool` | `#B9C9E6` | Info, calm, blue slot |
| `color.accent.nature` | `#C8E7D5` | Success, growth, green slot |
| `color.surface` | `#F8F5F2` | Light-mode background |
| `color.surface.dark` | `#1E1B2E` | Dark-mode background (orchid-tinted) |
| `color.text.primary` | `#4A4A4A` | Body text on light |
| `color.text.secondary` | `#6D6D6D` | Supporting text on light |
| `input.border.error` | `#D32F2F` | Error states, red slot |

---

## Primitive Tokens (internal reference only)

| Family | Shade | Hex |
|--------|-------|-----|
| orchid | 500 | `#CDB4DB` |
| orchid | 600 | `#A88FBC` |
| orchid | 700 | `#6F4A8E` |
| lavender | 300 | `#E5D4F1` |
| pink | 400 | `#F8D1E0` |
| blue | 400 | `#B9C9E6` |
| mint | 400 | `#C8E7D5` |
| cream | 100 | `#F8F5F2` |
| cream | 300 | `#E5E1DD` |
| neutral | 600 | `#6D6D6D` |
| neutral | 700 | `#4A4A4A` |
| muted-orchid | — | `#9E93B8` |
| deep-dark | — | `#15121F` |

---

## Script Color Role Mapping

Shell scripts emit ANSI 8-color slot references. The Zellij theme maps those slots to Orchid Papyrus hex values. This is the symbiotic link — scripts stay portable while the rendered color matches the design token.

| Role | Script function | ANSI variable | ANSI code | Palette token | Hex |
|------|----------------|--------------|-----------|---------------|-----|
| Success | `log_success` | `GREEN` | `\033[0;32m` | `color.accent.nature` | `#C8E7D5` |
| Warning | `log_warning` | `YELLOW` | `\033[1;33m` | `color.accent.warm` | `#F8D1E0` |
| Error | `log_error` | `RED` | `\033[0;31m` | `input.border.error` | `#D32F2F` |
| Info / arrow | `log_info` | `CYAN` | `\033[0;36m` | `color.accent.cool` | `#B9C9E6` |
| Section header | `log_step` | `BLUE` | `\033[0;34m` | `color.primary-deep` | `#6F4A8E` |
| Brand / accent | misc | `MAGENTA` | `\033[0;35m` | `color.primary` | `#CDB4DB` |
| Paths / values | misc | `CYAN` | `\033[0;36m` | `color.accent.cool` | `#B9C9E6` |
| Body text | misc | `WHITE` | `\033[1;37m` | `color.secondary` | `#E5D4F1` |

---

## Shell Prompt Mapping

| Prompt element | Zsh token | ANSI slot | Palette token |
|---------------|-----------|-----------|---------------|
| Username `%n` | `%F{cyan}` | cyan | `color.accent.cool` |
| Separator `@` | `%F{magenta}` | magenta | `color.primary` |
| Hostname `%m` | `%F{blue}` | blue | `color.primary-deep` |

---

## Zellij Theme Slots

Two variants are defined in `.potions/zellij/config.kdl`. Active theme is `potions-dark`.
To switch, change `theme "potions-dark"` to `theme "potions-light"` in that file.

### Dark (`potions-dark`)

| Slot | Hex | Palette token |
|------|-----|---------------|
| `fg` | `#E5D4F1` | `color.secondary` (lavender.300) |
| `bg` | `#1E1B2E` | `color.surface.dark` |
| `black` | `#15121F` | deep-dark |
| `red` | `#D32F2F` | `input.border.error` |
| `green` | `#C8E7D5` | `color.accent.nature` |
| `yellow` | `#F8D1E0` | `color.accent.warm` |
| `blue` | `#B9C9E6` | `color.accent.cool` |
| `magenta` | `#CDB4DB` | `color.primary` |
| `cyan` | `#A88FBC` | orchid.600 |
| `white` | `#9E93B8` | muted-orchid |
| `orange` | `#6F4A8E` | `color.primary-deep` |

### Light (`potions-light`)

| Slot | Hex | Palette token |
|------|-----|---------------|
| `fg` | `#4A4A4A` | `color.text.primary` |
| `bg` | `#F8F5F2` | `color.surface` |
| `black` | `#E5E1DD` | cream.300 |
| `red` | `#D32F2F` | `input.border.error` |
| `green` | `#C8E7D5` | `color.accent.nature` |
| `yellow` | `#F8D1E0` | `color.accent.warm` |
| `blue` | `#B9C9E6` | `color.accent.cool` |
| `magenta` | `#CDB4DB` | `color.primary` |
| `cyan` | `#6F4A8E` | `color.primary-deep` |
| `white` | `#6D6D6D` | `color.text.secondary` |
| `orange` | `#A88FBC` | orchid.600 |

---

## NeoVim

NeoVim uses the `Rynaro/alchemists-orchid.nvim` plugin from the same design family.
See `.potions/nvim/init.vim` for palette cross-reference comments and highlight overrides.
