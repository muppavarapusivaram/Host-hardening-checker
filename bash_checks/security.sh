#!/bin/bash
# Security Framework Checks (SELinux, AppArmor, Audit)

OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/security.json"

# Initialize JSON array
echo "[]" > "$RESULTS_FILE"

# Function to add result to JSON
add_result() {
    local check_name="$1"
    local result="$2"
    local status="$3"
    local details="$4"
    
    jq -c --arg name "$check_name" \
          --arg result "$result" \
          --arg status "$status" \
          --arg details "$details" \
          '. += [{"check_name": $name, "result": $result, "status": $status, "details": $details}]' \
          "$RESULTS_FILE" > "${RESULTS_FILE}.tmp" && mv "${RESULTS_FILE}.tmp" "$RESULTS_FILE"
}

# Check SELinux status
if command -v getenforce &>/dev/null; then
    selinux_status=$(getenforce 2>/dev/null)
    if [ "$selinux_status" = "Enforcing" ]; then
        add_result "SELinux Status" "PASS" "LOW" "SELinux is in Enforcing mode"
    elif [ "$selinux_status" = "Permissive" ]; then
        add_result "SELinux Status" "WARN" "MEDIUM" "SELinux is in Permissive mode"
    else
        add_result "SELinux Status" "FAIL" "HIGH" "SELinux is disabled"
    fi
else
    # Check if SELinux is available in kernel
    if [ -d "/sys/fs/selinux" ]; then
        add_result "SELinux Status" "WARN" "MEDIUM" "SELinux kernel support present but tools not installed"
    else
        add_result "SELinux Status" "INFO" "LOW" "SELinux is not available on this system"
    fi
fi

# Check AppArmor status
if command -v aa-status &>/dev/null; then
    if aa-status --enabled &>/dev/null 2>&1; then
        apparmor_profiles=$(aa-status 2>/dev/null | grep "profiles are loaded" | awk '{print $1}')
        add_result "AppArmor Status" "PASS" "LOW" "AppArmor is enabled with $apparmor_profiles profiles"
    else
        add_result "AppArmor Status" "FAIL" "HIGH" "AppArmor is installed but not enabled"
    fi
else
    # Check if AppArmor is available in kernel
    if [ -d "/sys/kernel/security/apparmor" ]; then
        add_result "AppArmor Status" "WARN" "MEDIUM" "AppArmor kernel support present but tools not installed"
    else
        add_result "AppArmor Status" "INFO" "LOW" "AppArmor is not available on this system"
    fi
fi

# Check auditd status
if command -v auditctl &>/dev/null; then
    if systemctl is-active auditd &>/dev/null || systemctl is-active audit &>/dev/null; then
        audit_rules=$(auditctl -l 2>/dev/null | wc -l)
        add_result "Auditd Status" "PASS" "LOW" "Auditd is running with $audit_rules rules"
        
        # Check if auditd is enabled
        if systemctl is-enabled auditd &>/dev/null || systemctl is-enabled audit &>/dev/null; then
            enabled=$(systemctl is-enabled auditd 2>/dev/null || systemctl is-enabled audit 2>/dev/null)
            if [ "$enabled" = "enabled" ]; then
                add_result "Auditd Enabled" "PASS" "LOW" "Auditd is enabled on boot"
            else
                add_result "Auditd Enabled" "WARN" "MEDIUM" "Auditd is not enabled on boot"
            fi
        fi
    else
        add_result "Auditd Status" "FAIL" "HIGH" "Auditd is not running"
    fi
else
    add_result "Auditd Status" "WARN" "MEDIUM" "Auditd is not installed"
fi

# Check for audit rules
if command -v auditctl &>/dev/null; then
    # Check for file system audit rules
    fs_rules=$(auditctl -l 2>/dev/null | grep -c "^-w" || echo "0")
    if [ "$fs_rules" -gt 0 ]; then
        add_result "Audit Filesystem Rules" "PASS" "LOW" "Found $fs_rules filesystem audit rules"
    else
        add_result "Audit Filesystem Rules" "WARN" "MEDIUM" "No filesystem audit rules configured"
    fi
    
    # Check for system call audit rules
    syscall_rules=$(auditctl -l 2>/dev/null | grep -c "^-a" || echo "0")
    if [ "$syscall_rules" -gt 0 ]; then
        add_result "Audit System Call Rules" "PASS" "LOW" "Found $syscall_rules system call audit rules"
    else
        add_result "Audit System Call Rules" "WARN" "MEDIUM" "No system call audit rules configured"
    fi
fi

# Check for installed security packages
security_tools="fail2ban rkhunter chkrootkit aide tripwire"
for tool in $security_tools; do
    if command -v "$tool" &>/dev/null || dpkg -l | grep -q "^ii.*$tool" || rpm -qa | grep -q "$tool"; then
        add_result "Security Tool: $tool" "INFO" "LOW" "$tool is installed"
    fi
done

# Check cron jobs (security-related)
if [ -d "/etc/cron.d" ]; then
    cron_files=$(ls /etc/cron.d/ 2>/dev/null | wc -l)
    add_result "Cron Jobs" "INFO" "LOW" "Found $cron_files files in /etc/cron.d"
fi

# Check /etc/crontab permissions
if [ -f "/etc/crontab" ]; then
    crontab_perm=$(stat -c "%a" /etc/crontab 2>/dev/null)
    if [ "$crontab_perm" = "644" ] || [ "$crontab_perm" = "600" ]; then
        add_result "/etc/crontab Permissions" "PASS" "LOW" "/etc/crontab has secure permissions: $crontab_perm"
    else
        add_result "/etc/crontab Permissions" "WARN" "MEDIUM" "/etc/crontab permissions: $crontab_perm"
    fi
fi

# Check for world-writable cron directories
for cron_dir in /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly; do
    if [ -d "$cron_dir" ]; then
        cron_dir_perm=$(stat -c "%a" "$cron_dir" 2>/dev/null)
        if [ "$cron_dir_perm" = "755" ] || [ "$cron_dir_perm" = "700" ]; then
            add_result "Cron Directory: $cron_dir" "PASS" "LOW" "Cron directory has secure permissions: $cron_dir_perm"
        else
            add_result "Cron Directory: $cron_dir" "WARN" "MEDIUM" "Cron directory permissions: $cron_dir_perm"
        fi
    fi
done

# Check for log files
if [ -d "/var/log" ]; then
    log_files=$(find /var/log -type f -name "*.log" 2>/dev/null | wc -l)
    add_result "Log Files" "INFO" "LOW" "Found $log_files log files in /var/log"
fi

# Check logrotate configuration
if [ -f "/etc/logrotate.conf" ]; then
    add_result "Logrotate Configuration" "INFO" "LOW" "Logrotate is configured"
fi

echo "Security scan completed. Results saved to $RESULTS_FILE"

