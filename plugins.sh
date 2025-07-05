#!/bin/bash

# Function to safely source a script if it exists
safe_source() {
  [ -f "$1" ] && source "$1"
}

safe_source "$(dirname "$0")/plugins/manage.sh"

# Execute the manage_plugins function with provided arguments
manage_plugins "$@"

