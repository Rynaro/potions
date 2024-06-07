command_exists() {
  command -v "$1" &> /dev/null
}

# Function to install Git
install_git() {
  echo "Update Repositories..."
  if [ "$OS_TYPE" = "Darwin" ]; then
    brew update
  elif [ -n "$(command -v apt-get)" ]; then
    sudo apt-get update
  fi
}
