#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/packages/accessories.sh"

safe_source "$SCRIPT_DIR/plugins/manage.sh"

# Execute the manage_plugins function with provided arguments
manage_plugins "$@"

