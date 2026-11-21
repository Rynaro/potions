#!/bin/bash
# Create a small, standalone plugin repository in the current directory.
SCAFFOLD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_plugin() {
  local name="${1:-}" format=json
  shift || true
  if [ "${1:-}" = --potion ]; then format=yaml; shift; fi
  if [ "$#" -ne 0 ] || ! [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
    printf 'Usage: potions plugin create <name> [--potion]\n' >&2
    return 2
  fi
  local plugin_dir="$PWD/$name"
  if [ -e "$plugin_dir" ] || [ -L "$plugin_dir" ]; then
    printf 'Destination already exists: %s\n' "$plugin_dir" >&2
    return 1
  fi
  mkdir -p "$plugin_dir/config" || return 1
  if [ "$format" = yaml ]; then
    cat > "$plugin_dir/.potion" <<EOF
name: $name
version: "0.1.0"
description: A Potions plugin
author: Your name
potions_min_version: "2.6.0"
EOF
  else
    cat > "$plugin_dir/plugin.potions.json" <<EOF
{
  "name": "$name",
  "version": "0.1.0",
  "description": "A Potions plugin",
  "author": "Your name",
  "potions_min_version": "2.6.0"
}
EOF
  fi
  printf '# Shell aliases and functions loaded while this plugin is active.\n' > "$plugin_dir/config/init.zsh"
  cat > "$plugin_dir/README.md" <<EOF
# $name

Describe the plugin and its supported platforms here.

Edit config/init.zsh to provide shell aliases and functions. Add install.sh
for optional, idempotent setup when needed. Back up user files before modifying them.
Optional uninstall.sh, activate.sh and deactivate.sh hooks run through Bash.

Validate and test from the parent directory.

\`\`\`sh
potions plugin validate ./$name
potions plugin install ./$name
potions plugin deactivate $name
potions plugin activate $name
\`\`\`

Open a new shell to load active configuration. Commit these files to a GitHub
repository and create a version tag. Users can install the tagged repository.

\`\`\`sh
potions plugin install OWNER/$name@v0.1.0
\`\`\`

Users review the repository and allow its code with the interactive trust
prompt or --trust. Plugin code executes with the user's account permissions.
EOF
  printf 'Created %s\nEdit the manifest and config/init.zsh, then run potions plugin validate %s\n' "$plugin_dir" "$plugin_dir"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  create_plugin "$@"
fi
