#!/bin/bash

# AWX on Kind - Main Setup Script
# This is a convenience wrapper that delegates to the main setup script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎯 AWX on Kind - Interactive Setup"
echo "Launching main setup script..."
echo ""

# Execute the main setup script
exec "$SCRIPT_DIR/scripts/setup.sh" "$@"
