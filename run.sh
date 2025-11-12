#!/bin/bash
# Quick run script for Host Hardening Checker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if virtual environment exists and activate it
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Run the application
python3 main.py "$@"

