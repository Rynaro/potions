#!/bin/bash

# Install zellij via Termux's official package. The upstream prebuilt
# musl tarball ships a wasmtime build that hits ENOSYS on Android during
# WASM plugin compilation (zellij #4219), so any subcommand hangs. Termux's
# package is built against the NDK with the Android-specific patches that
# make wasmtime work — that's the only known-good path on Termux.
#
# Remove any orphan binary from prior potions versions that dropped the
# prebuilt at $PREFIX/bin/zellij outside of pkg's tracking.
if [ -f "$PREFIX/bin/zellij" ] && ! pkg list-installed 2>/dev/null | grep -q '^zellij/'; then
  rm -f "$PREFIX/bin/zellij"
fi

pkg install -y zellij
