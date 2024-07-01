#!/bin/bash
source "$(dirname "$0")/packages/accessories.sh"

safe_source 'plugins/manage.sh'

# Execute the manage_plugins function with provided arguments
manage_plugins "$@"

