#!/bin/bash

PLUGINS_DIR="plugins"

# Function to create a new plugin scaffold
create_plugin() {
  local plugin_name=$1

  if [ -z "$plugin_name" ]; then
    echo "Usage: $0 create <plugin_name>"
    exit 1
  fi

  # Create the plugin directory structure
  local plugin_dir="$PLUGINS_DIR/$plugin_name"
  mkdir -p "$plugin_dir/packages"

  # Create the blank install.sh script
  cat <<EOL > "$plugin_dir/install.sh"
#!/bin/bash

# Function to prepare to install packages
prepare() {
  # sudo apt update
}

# Function to install packages
install_packages() {
  echo "Installing Plugin: $plugin_name..."
  safe_source "packages/package1.sh"
  bash "packages/package2.sh"
}

# Function to consolidate post-installation scripts
post_install() {
  # Add your post install scripts
}

# Run pipeline
configure
install_packages
post_install

EOL

  # Create utilities.sh
  cat packages/accessories.sh > "$plugin_dir/utilities.sh"


  # Create a blank package1.sh script
  cat <<EOL > "$plugin_dir/packages/package1.sh"
#!/bin/bash

# Function to install package 1
install_package1() {
  echo "Installing package 1..."
  # Installation commands for package 1
}

# Run installation
install_package1
EOL

  # Create a blank package2.sh script
  cat <<EOL > "$plugin_dir/packages/package2.sh"
#!/bin/bash

# Function to install package 2
install_package2() {
  echo "Installing package 2..."
  # Installation commands for package 2
}

# Run installation
install_package2
EOL

  # Make the scripts executable
  chmod +x "$plugin_dir/install.sh"
  chmod +x "$plugin_dir/packages/package1.sh"
  chmod +x "$plugin_dir/packages/package2.sh"

  echo "Plugin $plugin_name has been created at $plugin_dir"
}

# Execute the create_plugin function with provided arguments
create_plugin "$@"
