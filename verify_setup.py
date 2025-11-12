#!/usr/bin/env python3
"""
Quick verification script to check if the project is set up correctly.
"""

import os
import sys

def check_file(filepath, description):
    """Check if a file exists."""
    if os.path.exists(filepath):
        print(f"✓ {description}: {filepath}")
        return True
    else:
        print(f"✗ {description} NOT FOUND: {filepath}")
        return False

def check_directory(dirpath, description):
    """Check if a directory exists."""
    if os.path.isdir(dirpath):
        print(f"✓ {description}: {dirpath}")
        return True
    else:
        print(f"✗ {description} NOT FOUND: {dirpath}")
        return False

def main():
    """Run verification checks."""
    print("Host Hardening Checker - Setup Verification")
    print("=" * 50)
    
    project_root = os.path.dirname(os.path.abspath(__file__))
    all_ok = True
    
    # Check directories
    print("\nChecking directories...")
    all_ok &= check_directory(os.path.join(project_root, "bash_checks"), "Bash checks directory")
    all_ok &= check_directory(os.path.join(project_root, "rules"), "Rules directory")
    all_ok &= check_directory(os.path.join(project_root, "scanner"), "Scanner directory")
    all_ok &= check_directory(os.path.join(project_root, "reports"), "Reports directory")
    
    # Check main files
    print("\nChecking main files...")
    all_ok &= check_file(os.path.join(project_root, "main.py"), "Main entry point")
    all_ok &= check_file(os.path.join(project_root, "requirements.txt"), "Requirements file")
    all_ok &= check_file(os.path.join(project_root, "README.md"), "README file")
    
    # Check bash scripts
    print("\nChecking bash scripts...")
    bash_scripts = [
        "services.sh", "network.sh", "ssh.sh", "users.sh",
        "permissions.sh", "kernel.sh", "security.sh", "run_all.sh"
    ]
    for script in bash_scripts:
        script_path = os.path.join(project_root, "bash_checks", script)
        all_ok &= check_file(script_path, f"Bash script: {script}")
        if os.path.exists(script_path):
            if not os.access(script_path, os.X_OK):
                print(f"  Warning: {script} is not executable")
    
    # Check rules
    print("\nChecking rules...")
    all_ok &= check_file(os.path.join(project_root, "rules", "rules.yaml"), "Rules YAML file")
    
    # Check Python modules
    print("\nChecking Python modules...")
    python_modules = ["__init__.py", "parser.py", "gui.py", "report.py"]
    for module in python_modules:
        module_path = os.path.join(project_root, "scanner", module)
        all_ok &= check_file(module_path, f"Python module: {module}")
    
    # Check Python dependencies
    print("\nChecking Python dependencies...")
    try:
        import yaml
        print("✓ PyYAML is installed")
    except ImportError:
        print("✗ PyYAML is NOT installed (run: pip3 install -r requirements.txt)")
        all_ok = False
    
    try:
        from PyQt5.QtWidgets import QApplication
        print("✓ PyQt5 is installed")
    except ImportError:
        print("✗ PyQt5 is NOT installed (run: pip3 install -r requirements.txt)")
        all_ok = False
    
    # Check system dependencies
    print("\nChecking system dependencies...")
    import shutil
    if shutil.which("jq"):
        print("✓ jq is installed")
    else:
        print("✗ jq is NOT installed (run: sudo apt-get install jq)")
        all_ok = False
    
    if shutil.which("bash"):
        print("✓ bash is installed")
    else:
        print("✗ bash is NOT installed")
        all_ok = False
    
    # Summary
    print("\n" + "=" * 50)
    if all_ok:
        print("✓ All checks passed! The project is set up correctly.")
        print("\nYou can now run the application with:")
        print("  python3 main.py")
        return 0
    else:
        print("✗ Some checks failed. Please fix the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())

