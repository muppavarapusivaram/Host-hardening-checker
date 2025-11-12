#!/usr/bin/env python3
"""
Main entry point for Host Hardening Checker GUI application.
"""

import sys
import os

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

from scanner.gui import main

if __name__ == "__main__":
    main()

