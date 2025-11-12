#!/bin/bash
# Setup script for Host Hardening Checker

# Don't exit on error for checks, but do for critical failures
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Host Hardening Checker - Setup Script"
echo "======================================"
echo ""

# Check if running as root for system package installation
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Install jq if not present
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    $SUDO apt-get update
    $SUDO apt-get install -y jq
else
    echo "✓ jq is already installed"
fi

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "✓ Python $PYTHON_VERSION found"

# Check if virtual environment should be used
USE_VENV=true
if [ "$1" == "--system" ]; then
    USE_VENV=false
    echo "Warning: Installing system-wide (requires --break-system-packages)"
fi

if [ "$USE_VENV" = true ]; then
    # Check if python3-venv is installed
    if ! python3 -c "import venv" 2>/dev/null; then
        echo "Warning: python3-venv module not found. Installing..."
        $SUDO apt-get install -y python3-venv python3-full || {
            echo "Error: Could not install python3-venv. Please install manually:"
            echo "  sudo apt-get install python3-venv python3-full"
            exit 1
        }
    fi
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        echo "Creating virtual environment..."
        python3 -m venv venv || {
            echo "Error: Failed to create virtual environment"
            exit 1
        }
    else
        echo "✓ Virtual environment already exists"
    fi
    
    # Activate virtual environment
    echo "Activating virtual environment..."
    source venv/bin/activate || {
        echo "Error: Failed to activate virtual environment"
        exit 1
    }
    
    # Upgrade pip
    echo "Upgrading pip..."
    pip install --upgrade pip || {
        echo "Warning: Failed to upgrade pip, continuing..."
    }
    
    # Install requirements
    echo "Installing Python dependencies..."
    pip install -r requirements.txt || {
        echo "Error: Failed to install dependencies"
        exit 1
    }
    
    echo ""
    echo "======================================"
    echo "Setup complete!"
    echo ""
    echo "To use the application:"
    echo "  1. Activate the virtual environment:"
    echo "     source venv/bin/activate"
    echo ""
    echo "  2. Run the application:"
    echo "     python3 main.py"
    echo ""
    echo "  3. Or use the run script:"
    echo "     ./run.sh"
    echo ""
else
    # System-wide installation
    echo "Installing Python dependencies system-wide..."
    pip3 install --break-system-packages -r requirements.txt || {
        echo "Error: Failed to install dependencies"
        exit 1
    }
    
    echo ""
    echo "======================================"
    echo "Setup complete!"
    echo ""
    echo "You can now run the application with:"
    echo "  python3 main.py"
    echo ""
fi

# Make scripts executable
chmod +x bash_checks/*.sh
chmod +x main.py
chmod +x verify_setup.py 2>/dev/null || true

echo "✓ All setup steps completed"

