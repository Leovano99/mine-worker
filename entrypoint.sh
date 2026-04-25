#!/bin/bash
set -e
set -x

echo "=== START ENTRYPOINT ==="

echo "Node: $(node -v)"
echo "NPM: $(npm -v)"
echo "Python: $(python --version)"

# =========================
# AWP WALLET SETUP
# =========================

if [ ! -d "/app/awp-wallet" ]; then
  git clone https://github.com/awp-core/awp-wallet /app/awp-wallet
fi

cd /app/awp-wallet

if ! command -v awp-wallet >/dev/null 2>&1; then
  echo "Installing awp-wallet..."

  chmod +x install.sh

  if [ -n "$MNEMONIC" ]; then
    bash ./install.sh --mnemonic "$MNEMONIC"
  else
    bash ./install.sh
  fi
else
  echo "awp-wallet already installed"
fi

# Normalize awp-wallet binary
AWP_PATH="$(which awp-wallet || true)"

if [ -z "$AWP_PATH" ]; then
  if [ -f "$HOME/.local/bin/awp-wallet" ]; then
    AWP_PATH="$HOME/.local/bin/awp-wallet"
  elif [ -f "/usr/bin/awp-wallet" ]; then
    AWP_PATH="/usr/bin/awp-wallet"
  else
    echo "FATAL: awp-wallet not found"
    exit 1
  fi
fi

ln -sf "$AWP_PATH" /usr/local/bin/awp-wallet

which awp-wallet
awp-wallet --help || true

# =========================
# MINE SKILL SETUP
# =========================

echo "=== MINE SKILL SETUP ==="

cd /app

# Clone if not exists
if [ ! -d "mine-skill" ]; then
  echo "Cloning repository..."
  git clone https://github.com/Leovano99/mine-skill
fi

cd mine-skill

# Create venv if not exists
if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  python3 -m venv .venv
fi

# Activate venv and install dependencies
echo "Installing dependencies..."
. .venv/bin/activate
pip install -r requirements-core.txt
deactivate

# Ensure scripts are executable
chmod +x start.sh stop.sh loop.sh

# =========================
# WALLET POST ACTION
# =========================

if [ -z "$MNEMONIC" ]; then
  echo "No mnemonic → showing wallet info"
  awp-wallet receive
  awp-wallet export
else
  echo "Mnemonic provided → wallet already initialized"
fi

echo "=== ENTRYPOINT DONE ==="

# keep container alive
tail -f /dev/null
