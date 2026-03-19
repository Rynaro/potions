#!/bin/bash

# Zellij is not available in standard Ubuntu/WSL repos
# Download prebuilt binary from GitHub releases

ZELLIJ_VERSION="0.41.2"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)
    ZELLIJ_ARCH="x86_64-unknown-linux-musl"
    ;;
  aarch64|arm64)
    ZELLIJ_ARCH="aarch64-unknown-linux-musl"
    ;;
  *)
    log "Unsupported architecture for zellij: $ARCH"
    exit 1
    ;;
esac

ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${ZELLIJ_ARCH}.tar.gz"
TEMP_DIR=$(mktemp -d)

log "Downloading zellij v${ZELLIJ_VERSION} for ${ARCH}..."
if command_exists curl; then
  curl -fsSL "$ZELLIJ_URL" -o "$TEMP_DIR/zellij.tar.gz"
elif command_exists wget; then
  wget -q "$ZELLIJ_URL" -O "$TEMP_DIR/zellij.tar.gz"
fi

tar -xzf "$TEMP_DIR/zellij.tar.gz" -C "$TEMP_DIR"
sudo install -m 755 "$TEMP_DIR/zellij" /usr/local/bin/zellij
rm -rf "$TEMP_DIR"

log "Zellij v${ZELLIJ_VERSION} installed to /usr/local/bin/zellij"
