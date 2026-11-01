#!/usr/bin/env bash
set -e

echo "=== Provisioning Hermes Agent in Cloud Environment (0 MB Local Footprint) ==="

# Install system dependencies
sudo apt-get update && sudo apt-get install -y ffmpeg ripgrep curl git sqlite3

# Install uv package manager
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"

# Run Hermes Agent official installer
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Ensure hermes is in PATH for all shells
if [ -d "$HOME/.hermes/bin" ]; then
    echo 'export PATH="$HOME/.hermes/bin:$PATH"' >> ~/.bashrc
    echo 'export PATH="$HOME/.hermes/bin:$PATH"' >> ~/.zshrc
    export PATH="$HOME/.hermes/bin:$PATH"
fi

echo "=== Hermes Agent Cloud Provisioning Complete! ==="
echo "Type 'hermes' or 'hermes setup' to begin."
