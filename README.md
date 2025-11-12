# Host Hardening Checker

A comprehensive cybersecurity tool for checking and auditing Linux system hardening configurations. This project provides a Python PyQt GUI frontend with bash backend scanning scripts to perform extensive security checks on Kali Linux systems.

## Features

- **Comprehensive Security Checks**: Performs system hardening checks using Linux commands including:
  - System services (systemctl, service)
  - Network security (firewall, iptables/nftables, UFW, firewalld)
  - SSH configuration (sshd -T, config file analysis)
  - User and group security (getent, chage, sudo)
  - File permissions (SUID/SGID, world-writable files)
  - Kernel hardening (sysctl parameters)
  - Security frameworks (SELinux, AppArmor, auditd)

- **Structured Output**: Bash scripts write scan results to structured JSON files
- **YAML Rules Engine**: Configurable severity scoring and remediation text via YAML rules
- **Risk Assessment**: Automatic calculation of risk levels (HIGH / MEDIUM / LOW)
- **PyQt GUI**: User-friendly graphical interface with:
  - Results table displaying check name, result, severity, and remediation
  - Run Full Scan button to execute bash scripts
  - Refresh Results button to reload scan data
  - Export Report button to generate HTML reports

- **HTML Report Generator**: Generates detailed HTML reports with:
  - Summary statistics
  - Color-coded severity levels
  - Detailed check results with remediation steps
  - Timestamp information

## Project Structure

```
host-hardening-checker/
├── bash_checks/          # Bash scanning scripts
│   ├── services.sh       # Service and systemd checks
│   ├── network.sh        # Network and firewall checks
│   ├── ssh.sh            # SSH configuration checks
│   ├── users.sh          # User and group security checks
│   ├── permissions.sh    # File permissions checks
│   ├── kernel.sh         # Kernel hardening checks
│   ├── security.sh       # Security framework checks
│   └── run_all.sh        # Master script to run all checks
├── rules/                # YAML rules configuration
│   └── rules.yaml        # Severity scoring and remediation rules
├── scanner/              # Python modules
│   ├── __init__.py
│   ├── parser.py         # JSON result parser and rule application
│   ├── gui.py            # PyQt GUI implementation
│   ├── report.py         # HTML report generator
│   └── main.py           # GUI entry point
├── reports/              # Generated HTML reports
├── venv/                 # Python virtual environment (created by setup.sh)
├── main.py               # Main application entry point
├── setup.sh              # Automated setup script
├── run.sh                # Quick run script (activates venv if exists)
├── verify_setup.py       # Setup verification script
├── requirements.txt      # Python dependencies
├── .gitignore           # Git ignore file
├── README.md            # This file
└── GUIDE.md             # Complete user guide (step-by-step instructions)
```

## Prerequisites

- **Operating System**: Kali Linux (dual boot or VM)
- **Python**: Python 3.6 or higher (Python 3.9+ recommended)
- **System Tools**: 
  - `jq` (JSON processor) - Install with: `sudo apt-get install jq`
  - `python3-venv` (for virtual environment) - Install with: `sudo apt-get install python3-venv python3-full`
  - Standard Linux utilities (systemctl, ss, netstat, etc.)

## Installation

### Quick Setup (Recommended)

Run the automated setup script:

```bash
cd /home/umehb/projects/host-hardening-checker
bash setup.sh
```

This will:
- Install `jq` if not present
- Create a Python virtual environment
- Install all Python dependencies
- Make scripts executable

### Manual Setup

1. **Navigate to the project directory**:
   ```bash
   cd /home/umehb/projects/host-hardening-checker
   ```

2. **Install jq (required for bash scripts)**:
   ```bash
   sudo apt-get update
   sudo apt-get install jq
   ```

3. **Install Python dependencies**:

   **Option A: Using Virtual Environment (Recommended)**
   ```bash
   # Create virtual environment
   python3 -m venv venv
   
   # Activate virtual environment
   source venv/bin/activate
   
   # Install dependencies
   pip install -r requirements.txt
   ```

   **Option B: System-wide Installation (Alternative)**
   ```bash
   # Install system packages if available
   sudo apt-get install python3-pyqt5 python3-yaml
   
   # Or use pip with --break-system-packages (not recommended)
   pip3 install --break-system-packages -r requirements.txt
   ```

   **Option C: Using setup script with system flag**
   ```bash
   bash setup.sh --system
   ```

4. **Make bash scripts executable** (if not already):
   ```bash
   chmod +x bash_checks/*.sh
   ```

## Quick Start

1. **Run the setup script**:
   ```bash
   bash setup.sh
   ```

2. **Launch the application**:
   ```bash
   ./run.sh
   ```

3. **Run a scan**: Click "Run Full Scan" button in the GUI

4. **View results**: Results appear in the table automatically

5. **Export report**: Click "Export Report to HTML" button

For detailed step-by-step instructions, see [GUIDE.md](GUIDE.md).

## Usage

### Running the GUI Application

**If using virtual environment:**
```bash
# Activate virtual environment first
source venv/bin/activate

# Run the application
python3 main.py
```

**Or use the quick run script:**
```bash
./run.sh
```

**If installed system-wide:**
```bash
python3 main.py
```

2. **Using the GUI**:
   - Click **"Run Full Scan"** to execute all bash scanning scripts
   - Wait for the scan to complete (progress will be shown)
   - Click **"Refresh Results"** to reload scan results from JSON files
   - Click **"Export Report to HTML"** to generate an HTML report in the `reports/` directory

### Running Bash Scripts Manually

You can also run the bash scripts manually:

```bash
# Run all checks
bash bash_checks/run_all.sh

# Run individual checks
bash bash_checks/services.sh
bash bash_checks/network.sh
bash bash_checks/ssh.sh
bash bash_checks/users.sh
bash bash_checks/permissions.sh
bash bash_checks/kernel.sh
bash bash_checks/security.sh
```

Scan results will be saved as JSON files in `/tmp/hardening-scan/`:
- `services.json`
- `network.json`
- `ssh.json`
- `users.json`
- `permissions.json`
- `kernel.json`
- `security.json`

### Viewing Reports

HTML reports are saved in the `reports/` directory with timestamps. Open them in any web browser:

```bash
# List generated reports
ls -lh reports/

# Open a report (example)
xdg-open reports/hardening_report_20240101_120000.html
```

## Configuration

### YAML Rules

Edit `rules/rules.yaml` to customize:
- Severity levels for different checks
- Remediation instructions
- Check name matching patterns

Example rule:
```yaml
rules:
  - check_name: "SSH PermitRootLogin"
    severity: "HIGH"
    remediation: "Disable root login: Edit /etc/ssh/sshd_config and set PermitRootLogin no"
```

## How It Works

1. **Bash Scripts**: Execute system commands and checks, outputting results to JSON files
2. **Python Parser**: Reads JSON files, applies YAML rules, and calculates severity levels
3. **GUI**: Displays results in a table, allows running scans, and exporting reports
4. **Report Generator**: Creates HTML reports with formatted results and statistics

## Security Notes

- Some checks require root/sudo privileges to access certain system files
- The scanner reads system configuration but does not modify anything
- Scan results are stored in `/tmp/hardening-scan/` (temporary directory)
- Reports are saved in the `reports/` directory

## Troubleshooting

### Permission Errors

If you encounter permission errors, some checks may require elevated privileges:
```bash
# Run with sudo (be cautious)
sudo bash bash_checks/run_all.sh
```

### Missing Dependencies

If the GUI doesn't launch:

**With virtual environment:**
```bash
source venv/bin/activate
pip install --upgrade PyQt5 PyYAML
```

**System-wide:**
```bash
# Check PyQt5 installation
python3 -c "import PyQt5; print('PyQt5 installed')"

# Reinstall if needed (with virtual env)
source venv/bin/activate
pip install --upgrade PyQt5

# Or system-wide (not recommended)
pip3 install --break-system-packages --upgrade PyQt5
```

### Virtual Environment Issues

If you encounter issues with the virtual environment:

```bash
# Remove and recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### JSON Parse Errors

If you see JSON parsing errors, ensure `jq` is installed:
```bash
sudo apt-get install jq
```

### GUI Not Displaying

If the GUI window doesn't appear:
- Check that you're running in a graphical environment (X11/Wayland)
- Verify display server is running: `echo $DISPLAY`
- Try running with explicit display: `DISPLAY=:0 python3 main.py`

## Development

### Adding New Checks

1. Create a new bash script in `bash_checks/`
2. Follow the JSON output format used by existing scripts
3. Add the script to `run_all.sh`
4. Add corresponding rules to `rules/rules.yaml`

### Extending the GUI

Modify `scanner/gui.py` to add new features or customize the interface.

## License

This project is for educational purposes as part of cybersecurity studies.

## Author

Created for cybersecurity student project on Kali Linux.

## Contributing

This is a student project. Suggestions and improvements are welcome!

## Documentation

- **README.md**: Project overview and quick start
- **GUIDE.md**: Complete step-by-step user guide with detailed instructions

For detailed usage instructions, troubleshooting, and advanced features, see [GUIDE.md](GUIDE.md).

## Acknowledgments

- Built for Kali Linux security auditing
- Uses standard Linux security tools and best practices
- Inspired by security hardening checklists and frameworks

