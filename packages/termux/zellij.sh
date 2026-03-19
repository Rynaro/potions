#!/bin/bash

# Download prebuilt binary for Termux (aarch64)

ZELLIJ_VERSION="0.41.2"
ZELLIJ_ARCH="aarch64-unknown-linux-musl"
ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${ZELLIJ_ARCH}.tar.gz"
TEMP_DIR=$(mktemp -d)

log "Downloading zellij v${ZELLIJ_VERSION} for Termux..."
if command_exists curl; then
  curl -fsSL "$ZELLIJ_URL" -o "$TEMP_DIR/zellij.tar.gz"
elif command_exists wget; then
  wget -q "$ZELLIJ_URL" -O "$TEMP_DIR/zellij.tar.gz"
fi

tar -xzf "$TEMP_DIR/zellij.tar.gz" -C "$TEMP_DIR"
install -m 755 "$TEMP_DIR/zellij" "$PREFIX/bin/zellij"
rm -rf "$TEMP_DIR"

log "Zellij v${ZELLIJ_VERSION} installed to $PREFIX/bin/zellij"
