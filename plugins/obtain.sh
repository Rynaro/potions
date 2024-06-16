#!/bin/bash

PLUGINS_DIR="plugins"
PLUGINS_FILE="plugins.txt"

# Function to parse plugins.txt and clone repositories
obtain_plugins() {
  while IFS=, read -r repo branch; do
    # Trim spaces
    repo=$(echo $repo | xargs)
    branch=$(echo $branch | xargs)

    # Extract owner and repo name
    owner_repo=$(echo $repo | cut -d '/' -f 1-2)
    repo_name=$(echo $repo | cut -d '/' -f 2)

    # Set default branch if not specified
    if [ -z "$branch" ]; then
      branch="main"
    else
      branch=$(echo $branch | sed 's/branch: //')
    fi

    # Create a directory name by replacing '/' with '-'
    plugin_dir="$PLUGINS_DIR/${owner_repo//\//-}"

    # Clone the repository
    if [ ! -d "$plugin_dir" ]; then
      git clone -b "$branch" "https://github.com/$owner_repo.git" "$plugin_dir"
    else
      echo "Plugin $repo_name is already installed."
    fi
  done < <(grep -v '^#' "$PLUGINS_FILE")
}

