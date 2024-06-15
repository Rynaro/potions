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

# Function to install package 1
install_package1() {
  echo "Installing package 1..."
  bash "\$(dirname "\$0")/packages/package1.sh"
}

# Function to install package 2
install_package2() {
  echo "Installing package 2..."
  bash "\$(dirname "\$0")/packages/package2.sh"
}

# Function to configure package 1
configure_package1() {
  echo "Configuring package 1..."
  # Configuration commands for package 1
}

# Function to configure package 2
configure_package2() {
  echo "Configuring package 2..."
  # Configuration commands for package 2
}

# Run installations
install_package1
install_package2

# Run configurations
configure_package1
configure_package2
EOL

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
