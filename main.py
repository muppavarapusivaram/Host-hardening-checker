#!/usr/bin/env python3
"""
Main entry point for Host Hardening Checker.
Run this script to launch the GUI application.
"""

import sys
import os

# Add project root to path
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

# Import and run GUI
from scanner.gui import main

if __name__ == "__main__":
    main()

