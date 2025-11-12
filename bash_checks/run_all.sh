#!/bin/bash
# Master script to run all hardening checks

OUTPUT_DIR="/tmp/hardening-scan"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$OUTPUT_DIR"

echo "Starting comprehensive host hardening scan..."
echo "Results will be saved to: $OUTPUT_DIR"
echo ""

# Run all check scripts
if [ -f "$SCRIPT_DIR/services.sh" ]; then
    echo "Running services checks..."
    bash "$SCRIPT_DIR/services.sh"
fi

if [ -f "$SCRIPT_DIR/network.sh" ]; then
    echo "Running network checks..."
    bash "$SCRIPT_DIR/network.sh"
fi

if [ -f "$SCRIPT_DIR/ssh.sh" ]; then
    echo "Running SSH checks..."
    bash "$SCRIPT_DIR/ssh.sh"
fi

if [ -f "$SCRIPT_DIR/users.sh" ]; then
    echo "Running user security checks..."
    bash "$SCRIPT_DIR/users.sh"
fi

if [ -f "$SCRIPT_DIR/permissions.sh" ]; then
    echo "Running permissions checks..."
    bash "$SCRIPT_DIR/permissions.sh"
fi

if [ -f "$SCRIPT_DIR/kernel.sh" ]; then
    echo "Running kernel hardening checks..."
    bash "$SCRIPT_DIR/kernel.sh"
fi

if [ -f "$SCRIPT_DIR/security.sh" ]; then
    echo "Running security framework checks..."
    bash "$SCRIPT_DIR/security.sh"
fi

echo ""
echo "All scans completed. Check $OUTPUT_DIR for results."

