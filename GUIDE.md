# Host Hardening Checker - Complete User Guide

This comprehensive guide will walk you through every step of using the Host Hardening Checker application, from installation to advanced usage.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Verification](#verification)
4. [Running the Application](#running-the-application)
5. [Using the GUI](#using-the-gui)
6. [Understanding Results](#understanding-results)
7. [Exporting Reports](#exporting-reports)
8. [Command Line Usage](#command-line-usage)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Usage](#advanced-usage)

---

## Prerequisites

### Step 1: Check Your System

Before installing, verify you have:

1. **Kali Linux** (dual boot or VM)
   ```bash
   cat /etc/os-release
   ```

2. **Python 3.6 or higher** (Python 3.9+ recommended)
   ```bash
   python3 --version
   ```

3. **Internet connection** (for downloading dependencies)

4. **Administrative privileges** (sudo access for installing packages)

### Step 2: Install System Dependencies

Install required system packages:

```bash
sudo apt-get update
sudo apt-get install -y jq python3-venv python3-full
```

- `jq`: Required for JSON processing in bash scripts
- `python3-venv`: Required for creating virtual environments
- `python3-full`: Full Python installation with all modules

---

## Installation

### Method 1: Automated Setup (Recommended)

This is the easiest and recommended method.

#### Step 1: Navigate to Project Directory

```bash
cd /home/umehb/projects/host-hardening-checker
```

#### Step 2: Run Setup Script

```bash
bash setup.sh
```

The script will:
- ✓ Check and install `jq` if needed
- ✓ Create a Python virtual environment
- ✓ Install all Python dependencies (PyQt5, PyYAML)
- ✓ Make all scripts executable
- ✓ Verify installation

#### Step 3: Verify Installation

After setup completes, verify everything is working:

```bash
python3 verify_setup.py
```

You should see all checks passing (✓).

### Method 2: Manual Setup with Virtual Environment

If you prefer to set up manually:

#### Step 1: Navigate to Project Directory

```bash
cd /home/umehb/projects/host-hardening-checker
```

#### Step 2: Install jq

```bash
sudo apt-get update
sudo apt-get install -y jq
```

#### Step 3: Create Virtual Environment

```bash
python3 -m venv venv
```

#### Step 4: Activate Virtual Environment

```bash
source venv/bin/activate
```

You should see `(venv)` in your prompt.

#### Step 5: Upgrade pip

```bash
pip install --upgrade pip
```

#### Step 6: Install Python Dependencies

```bash
pip install -r requirements.txt
```

This installs:
- PyQt5 (GUI framework)
- PyYAML (YAML parser)

#### Step 7: Make Scripts Executable

```bash
chmod +x bash_checks/*.sh
chmod +x main.py
```

### Method 3: System-wide Installation (Not Recommended)

Only use this if you cannot use virtual environments:

```bash
# Install system packages
sudo apt-get install python3-pyqt5 python3-yaml jq

# Or use pip with --break-system-packages
pip3 install --break-system-packages -r requirements.txt
```

---

## Verification

### Step 1: Run Verification Script

```bash
cd /home/umehb/projects/host-hardening-checker
python3 verify_setup.py
```

### Step 2: Check Expected Output

You should see:
```
✓ Bash checks directory
✓ Rules directory
✓ Scanner directory
✓ Reports directory
✓ Main entry point
✓ All bash scripts
✓ All Python modules
✓ PyYAML is installed
✓ PyQt5 is installed
✓ jq is installed
✓ bash is installed
```

If any checks fail, follow the instructions provided by the script.

### Step 3: Test Bash Scripts

Test that bash scripts work:

```bash
# Test a single script
bash bash_checks/services.sh

# Check if JSON was created
ls -lh /tmp/hardening-scan/
```

You should see `services.json` in `/tmp/hardening-scan/`.

---

## Running the Application

### Method 1: Using Quick Run Script (Recommended)

#### Step 1: Navigate to Project Directory

```bash
cd /home/umehb/projects/host-hardening-checker
```

#### Step 2: Run the Script

```bash
./run.sh
```

This script automatically:
- Activates the virtual environment if it exists
- Runs the GUI application

### Method 2: Manual Activation

#### Step 1: Activate Virtual Environment

```bash
cd /home/umehb/projects/host-hardening-checker
source venv/bin/activate
```

#### Step 2: Run the Application

```bash
python3 main.py
```

### Method 3: System-wide Installation

If you installed system-wide:

```bash
cd /home/umehb/projects/host-hardening-checker
python3 main.py
```

### Expected Behavior

After running, you should see:
1. A GUI window opens with the title "Host Hardening Checker"
2. A table with columns: Check Name, Result, Severity, Remediation
3. Three buttons: "Run Full Scan", "Refresh Results", "Export Report to HTML"
4. A status label at the bottom

---

## Using the GUI

### Step 1: Understanding the Interface

The GUI has the following components:

1. **Title Bar**: "Host Hardening Checker"
2. **Button Panel**: Three action buttons
3. **Results Table**: Displays scan results
4. **Summary Label**: Shows statistics
5. **Status Label**: Shows current status

### Step 2: Run Your First Scan

#### Step 2.1: Click "Run Full Scan" Button

1. Click the blue **"Run Full Scan"** button
2. The button will become disabled (grayed out)
3. A progress bar will appear
4. Status messages will display in the status label

#### Step 2.2: Wait for Scan to Complete

The scan will:
- Execute all bash check scripts
- Display progress messages
- Take 1-5 minutes depending on system

You'll see messages like:
```
Starting scan...
Running services checks...
Running network checks...
Running SSH checks...
...
All scans completed.
```

#### Step 2.3: Scan Completion

When complete:
- Progress bar disappears
- Button becomes enabled again
- Status shows "Scan completed successfully"
- Results automatically load into the table

### Step 3: View Results

#### Step 3.1: Understand the Table

The results table has 4 columns:

1. **Check Name**: Name of the security check
   - Hover over to see detailed information
   - Includes sub-checks and details

2. **Result**: Status of the check
   - **PASS** (green): Check passed
   - **FAIL** (red): Check failed
   - **WARN** (yellow): Warning condition
   - **INFO** (blue): Informational message

3. **Severity**: Risk level
   - **HIGH** (red background): Critical issues
   - **MEDIUM** (yellow background): Important issues
   - **LOW** (green background): Minor issues or passed checks

4. **Remediation**: How to fix the issue
   - Hover to see full remediation text
   - Includes specific commands when applicable

#### Step 3.2: Interpret Results

**High Severity (Red)**:
- Critical security issues
- Should be addressed immediately
- Examples: Root login enabled, empty passwords, world-writable system files

**Medium Severity (Yellow)**:
- Important security concerns
- Should be addressed soon
- Examples: Weak SSH settings, missing firewall rules

**Low Severity (Green)**:
- Minor issues or passed checks
- Good security practices
- Examples: Proper permissions, secure configurations

#### Step 3.3: View Summary Statistics

At the bottom of the window, you'll see:
```
Total: 150 | High: 5 | Medium: 12 | Low: 133 | Passed: 120 | Failed: 8 | Warnings: 22
```

This shows:
- **Total**: Total number of checks performed
- **High**: Number of high severity issues
- **Medium**: Number of medium severity issues
- **Low**: Number of low severity issues
- **Passed**: Number of checks that passed
- **Failed**: Number of checks that failed
- **Warnings**: Number of warnings

### Step 4: Refresh Results

If you've run scans manually or want to reload results:

1. Click the green **"Refresh Results"** button
2. Results will reload from JSON files
3. Table will update with latest data
4. Summary statistics will refresh

### Step 5: Export Report

#### Step 5.1: Generate HTML Report

1. Click the red **"Export Report to HTML"** button
2. Wait for report generation (1-2 seconds)
3. A popup will show the report location

#### Step 5.2: View the Report

1. Note the file path shown in the popup
2. Open the report in a web browser:

```bash
# If report is in reports/ directory
xdg-open reports/hardening_report_20240101_120000.html

# Or navigate and open manually
cd reports/
ls -lh *.html
```

#### Step 5.3: Understand the Report

The HTML report includes:

1. **Header**: Title and timestamp
2. **Summary Cards**: Visual summary with statistics
3. **Detailed Results Table**: All checks with:
   - Check names and details
   - Result badges
   - Severity levels (color-coded)
   - Remediation instructions

---

## Understanding Results

### Common Check Categories

#### 1. Services Checks

**What it checks**:
- Unnecessary services (telnet, rsh, rlogin, etc.)
- Listening services and ports
- Failed systemd services

**Example Results**:
- `Service: telnet` - FAIL (HIGH) - Service is enabled
- `Failed Services` - WARN (MEDIUM) - 2 failed services found

**Remediation**:
```bash
sudo systemctl disable telnet
sudo systemctl stop telnet
```

#### 2. Network Checks

**What it checks**:
- Firewall status (UFW, firewalld, iptables)
- Network security parameters
- IP forwarding
- ICMP redirects
- SYN cookies

**Example Results**:
- `UFW Firewall` - FAIL (HIGH) - Firewall is not active
- `IP Forwarding` - FAIL (MEDIUM) - IP forwarding is enabled

**Remediation**:
```bash
sudo ufw enable
sudo sysctl -w net.ipv4.ip_forward=0
```

#### 3. SSH Checks

**What it checks**:
- Root login permissions
- Password authentication
- X11 forwarding
- Protocol version
- Max authentication tries
- Empty passwords
- Config file permissions

**Example Results**:
- `SSH PermitRootLogin` - FAIL (HIGH) - Root login is permitted
- `SSH PasswordAuthentication` - WARN (MEDIUM) - Password auth enabled

**Remediation**:
```bash
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
sudo systemctl restart sshd
```

#### 4. User Security Checks

**What it checks**:
- Users with UID 0 (root)
- Empty password accounts
- Password expiration
- System accounts with shells
- Sudo configuration
- File permissions (/etc/passwd, /etc/shadow, /etc/sudoers)

**Example Results**:
- `UID 0 Users` - FAIL (HIGH) - Multiple users with UID 0
- `/etc/shadow Permissions` - FAIL (HIGH) - Permissions too open

**Remediation**:
```bash
sudo chmod 640 /etc/shadow
sudo chmod 440 /etc/sudoers
```

#### 5. Permissions Checks

**What it checks**:
- World-writable files
- World-writable directories
- SUID/SGID files
- /tmp and /var/tmp permissions
- Home directory permissions
- Root-owned writable files

**Example Results**:
- `World-Writable Files` - FAIL (HIGH) - Found 5 world-writable files
- `/tmp Permissions` - WARN (MEDIUM) - Incorrect permissions

**Remediation**:
```bash
sudo chmod 1777 /tmp
sudo chmod o-w /path/to/file
```

#### 6. Kernel Hardening Checks

**What it checks**:
- Network security parameters
- ASLR (Address Space Layout Randomization)
- Kernel pointer restrictions
- Ptrace scope
- Core dumps
- Kernel version

**Example Results**:
- `ASLR` - FAIL (HIGH) - ASLR is disabled
- `Dmesg Restrict` - FAIL (MEDIUM) - Dmesg is not restricted

**Remediation**:
```bash
sudo sysctl -w kernel.randomize_va_space=2
sudo sysctl -w kernel.dmesg_restrict=1
```

#### 7. Security Framework Checks

**What it checks**:
- SELinux status
- AppArmor status
- Auditd status
- Audit rules
- Cron job permissions
- Security tools installation

**Example Results**:
- `SELinux Status` - FAIL (HIGH) - SELinux is disabled
- `Auditd Status` - FAIL (HIGH) - Auditd is not running

**Remediation**:
```bash
sudo systemctl enable auditd
sudo systemctl start auditd
```

### Understanding Severity Levels

#### HIGH Severity

**Characteristics**:
- Critical security vulnerabilities
- Immediate risk to system security
- Could lead to system compromise
- Red background in GUI

**Examples**:
- Root login enabled via SSH
- Empty password accounts
- World-writable system files
- SELinux/AppArmor disabled
- ASLR disabled

**Action**: Fix immediately

#### MEDIUM Severity

**Characteristics**:
- Important security concerns
- Should be addressed soon
- Potential security risks
- Yellow background in GUI

**Examples**:
- Weak SSH configuration
- Missing firewall rules
- Unnecessary services running
- Weak kernel parameters

**Action**: Fix within days

#### LOW Severity

**Characteristics**:
- Minor issues or passed checks
- Good security practices
- Informational messages
- Green background in GUI

**Examples**:
- Proper file permissions
- Secure configurations
- Passed security checks
- Informational messages

**Action**: Review periodically

---

## Exporting Reports

### Step 1: Generate Report

1. Ensure you have scan results (run a scan first)
2. Click **"Export Report to HTML"** button
3. Wait for confirmation popup

### Step 2: Locate Report File

Reports are saved in the `reports/` directory with timestamp:

```bash
cd /home/umehb/projects/host-hardening-checker/reports
ls -lh *.html
```

Example filename: `hardening_report_20240101_120000.html`

### Step 3: Open Report

**Method 1: Command Line**
```bash
xdg-open reports/hardening_report_20240101_120000.html
```

**Method 2: File Manager**
```bash
nautilus reports/  # GNOME
thunar reports/    # XFCE
```

**Method 3: Web Browser**
- Open your web browser
- Navigate to the reports directory
- Open the HTML file

### Step 4: Understand Report Structure

The HTML report contains:

1. **Header Section**:
   - Title: "Host Hardening Checker"
   - Timestamp: When the report was generated

2. **Summary Cards**:
   - High Severity Issues (red)
   - Medium Severity Issues (yellow)
   - Low Severity / Passed (green)
   - Passed Checks (green)
   - Total Checks (purple)

3. **Detailed Results Table**:
   - Sorted by severity (HIGH first)
   - Color-coded rows
   - Check names with details
   - Result badges
   - Severity indicators
   - Remediation instructions

### Step 5: Share or Archive Reports

Reports can be:
- Shared with security teams
- Archived for compliance
- Compared over time
- Included in security documentation

```bash
# Archive reports
tar -czf hardening_reports_$(date +%Y%m%d).tar.gz reports/
```

---

## Command Line Usage

### Running Individual Scans

You can run individual scan scripts without the GUI:

#### Step 1: Navigate to Project Directory

```bash
cd /home/umehb/projects/host-hardening-checker
```

#### Step 2: Run Individual Scripts

```bash
# Services check
bash bash_checks/services.sh

# Network check
bash bash_checks/network.sh

# SSH check
bash bash_checks/ssh.sh

# User security check
bash bash_checks/users.sh

# Permissions check
bash bash_checks/permissions.sh

# Kernel hardening check
bash bash_checks/kernel.sh

# Security framework check
bash bash_checks/security.sh
```

#### Step 3: Run All Scans

```bash
bash bash_checks/run_all.sh
```

#### Step 4: View Results

```bash
# List all JSON files
ls -lh /tmp/hardening-scan/

# View a specific result file
cat /tmp/hardening-scan/services.json | jq .

# Count checks in a file
cat /tmp/hardening-scan/services.json | jq '. | length'
```

### Using Python Parser Directly

You can use the Python parser from command line:

#### Step 1: Activate Virtual Environment

```bash
cd /home/umehb/projects/host-hardening-checker
source venv/bin/activate
```

#### Step 2: Run Parser

```python
python3
>>> from scanner.parser import ScanParser
>>> parser = ScanParser()
>>> results = parser.parse_results()
>>> summary = parser.get_summary()
>>> print(summary)
```

### Generating Reports from Command Line

#### Step 1: Activate Virtual Environment

```bash
source venv/bin/activate
```

#### Step 2: Generate Report

```python
python3
>>> from scanner.parser import ScanParser
>>> from scanner.report import ReportGenerator
>>> parser = ScanParser()
>>> report_gen = ReportGenerator()
>>> results = parser.parse_results()
>>> summary = parser.get_summary()
>>> report_path = report_gen.save_report(results, summary)
>>> print(f"Report saved to: {report_path}")
```

---

## Troubleshooting

### Problem: GUI Won't Launch

#### Symptom
```
Error: No module named 'PyQt5'
```

#### Solution

**With Virtual Environment**:
```bash
source venv/bin/activate
pip install PyQt5
```

**System-wide**:
```bash
sudo apt-get install python3-pyqt5
# Or
pip3 install --break-system-packages PyQt5
```

### Problem: Scan Fails to Run

#### Symptom
```
Scan failed: bash command not found
```

#### Solution
```bash
# Check if bash is installed
which bash

# Install if missing
sudo apt-get install bash
```

### Problem: JSON Parse Errors

#### Symptom
```
Error parsing services.json: Expecting value
```

#### Solution

1. **Check if jq is installed**:
```bash
which jq
sudo apt-get install jq
```

2. **Check JSON files**:
```bash
cat /tmp/hardening-scan/services.json
jq . /tmp/hardening-scan/services.json
```

3. **Re-run scans**:
```bash
bash bash_checks/run_all.sh
```

### Problem: Permission Denied

#### Symptom
```
Permission denied: bash_checks/services.sh
```

#### Solution
```bash
chmod +x bash_checks/*.sh
```

### Problem: Virtual Environment Issues

#### Symptom
```
Error: Failed to create virtual environment
```

#### Solution

1. **Install python3-venv**:
```bash
sudo apt-get install python3-venv python3-full
```

2. **Recreate virtual environment**:
```bash
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Problem: No Results Displayed

#### Symptom
Table is empty after running scan

#### Solution

1. **Check if scan completed**:
```bash
ls -lh /tmp/hardening-scan/
```

2. **Verify JSON files exist**:
```bash
ls -lh /tmp/hardening-scan/*.json
```

3. **Check JSON file contents**:
```bash
cat /tmp/hardening-scan/services.json | jq .
```

4. **Re-run scan**:
```bash
bash bash_checks/run_all.sh
```

5. **Refresh results in GUI**:
Click "Refresh Results" button

### Problem: Report Generation Fails

#### Symptom
```
Error exporting report: Permission denied
```

#### Solution

1. **Check reports directory**:
```bash
ls -ld reports/
```

2. **Create reports directory**:
```bash
mkdir -p reports
chmod 755 reports
```

3. **Check permissions**:
```bash
ls -la reports/
```

### Problem: GUI Freezes During Scan

#### Symptom
GUI becomes unresponsive during scan

#### Solution

1. **Wait for scan to complete** (scans can take 1-5 minutes)
2. **Check scan progress** in status label
3. **If truly frozen**, close and restart:
   - Close the GUI
   - Check if scan is still running: `ps aux | grep bash_checks`
   - Kill if necessary: `pkill -f bash_checks`
   - Restart GUI

### Problem: Missing Dependencies

#### Symptom
```
ModuleNotFoundError: No module named 'yaml'
```

#### Solution

**With Virtual Environment**:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

**System-wide**:
```bash
sudo apt-get install python3-yaml
# Or
pip3 install --break-system-packages PyYAML
```

---

## Advanced Usage

### Customizing Rules

#### Step 1: Edit Rules File

```bash
nano rules/rules.yaml
```

#### Step 2: Modify Rules

Add or modify rules:

```yaml
rules:
  - check_name: "Your Custom Check"
    severity: "HIGH"
    remediation: "Your remediation instructions"
```

#### Step 3: Reload in GUI

Click "Refresh Results" to reload with new rules.

### Adding New Checks

#### Step 1: Create New Bash Script

```bash
nano bash_checks/custom.sh
```

#### Step 2: Follow Template

```bash
#!/bin/bash
OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"
RESULTS_FILE="$OUTPUT_DIR/custom.json"
echo "[]" > "$RESULTS_FILE"

add_result() {
    jq -c --arg name "$1" \
          --arg result "$2" \
          --arg status "$3" \
          --arg details "$4" \
          '. += [{"check_name": $name, "result": $result, "status": $status, "details": $details}]' \
          "$RESULTS_FILE" > "${RESULTS_FILE}.tmp" && mv "${RESULTS_FILE}.tmp" "$RESULTS_FILE"
}

# Your checks here
add_result "Custom Check" "PASS" "LOW" "Check completed"

echo "Custom scan completed."
```

#### Step 3: Make Executable

```bash
chmod +x bash_checks/custom.sh
```

#### Step 4: Add to run_all.sh

```bash
nano bash_checks/run_all.sh
# Add: bash "$SCRIPT_DIR/custom.sh"
```

#### Step 5: Update Parser

```bash
nano scanner/parser.py
# Add 'custom.json' to json_files list
```

### Automated Scanning

#### Create Cron Job

```bash
crontab -e
```

Add:
```cron
# Run scan daily at 2 AM
0 2 * * * cd /home/umehb/projects/host-hardening-checker && bash bash_checks/run_all.sh
```

### Integration with Other Tools

#### Export to CSV

```python
import csv
from scanner.parser import ScanParser

parser = ScanParser()
results = parser.parse_results()

with open('results.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Check Name', 'Result', 'Severity', 'Remediation'])
    for r in results:
        writer.writerow([r['check_name'], r['result'], r['severity'], r['remediation']])
```

#### Send Reports via Email

```bash
# After generating report
mail -a reports/hardening_report_*.html -s "Security Scan Report" admin@example.com < /dev/null
```

### Batch Processing Multiple Systems

Create a script to scan multiple systems:

```bash
#!/bin/bash
# scan_multiple.sh

for host in host1 host2 host3; do
    ssh $host "cd /path/to/host-hardening-checker && bash bash_checks/run_all.sh"
    scp $host:/tmp/hardening-scan/*.json ./results/$host/
done
```

---

## Best Practices

### 1. Regular Scanning

- Run scans weekly or after system changes
- Compare reports over time
- Track security improvements

### 2. Prioritize Fixes

- Address HIGH severity issues immediately
- Schedule MEDIUM severity fixes
- Review LOW severity issues periodically

### 3. Documentation

- Keep reports for compliance
- Document remediation steps taken
- Track security improvements

### 4. Testing

- Test fixes in non-production first
- Verify fixes don't break functionality
- Re-run scans after fixes

### 5. Automation

- Use cron jobs for regular scans
- Automate report generation
- Set up alerts for critical issues

---

## Quick Reference

### Common Commands

```bash
# Setup
bash setup.sh

# Run GUI
./run.sh
# Or
source venv/bin/activate && python3 main.py

# Run scans
bash bash_checks/run_all.sh

# View results
cat /tmp/hardening-scan/services.json | jq .

# Generate report
# (Use GUI Export button)

# Verify setup
python3 verify_setup.py
```

### File Locations

- **Scan Results**: `/tmp/hardening-scan/*.json`
- **Reports**: `reports/*.html`
- **Rules**: `rules/rules.yaml`
- **Scripts**: `bash_checks/*.sh`
- **Python Modules**: `scanner/*.py`

### Important Files

- `main.py`: Application entry point
- `setup.sh`: Setup script
- `run.sh`: Quick run script
- `verify_setup.py`: Verification script
- `requirements.txt`: Python dependencies
- `README.md`: Project documentation
- `GUIDE.md`: This guide

---

## Support

### Getting Help

1. **Check this guide** for common issues
2. **Review README.md** for project information
3. **Check troubleshooting section** above
4. **Verify setup** with `verify_setup.py`

### Reporting Issues

If you encounter issues:

1. Check error messages carefully
2. Verify all dependencies are installed
3. Check file permissions
4. Review logs and error output
5. Document the issue with steps to reproduce

### Contributing

To contribute improvements:

1. Test changes thoroughly
2. Follow existing code style
3. Update documentation
4. Test on clean Kali Linux installation

---

## Conclusion

This guide covers all aspects of using the Host Hardening Checker. For additional information, refer to:

- `README.md`: Project overview and features
- `rules/rules.yaml`: Security rules and remediation
- Source code: Detailed implementation

**Remember**: Regular security scanning is essential for maintaining a secure system. Use this tool as part of your security routine.

---

*Last Updated: 2024*
*Version: 1.0*

