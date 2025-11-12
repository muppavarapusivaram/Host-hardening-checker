#!/bin/bash
# Kernel Hardening Checks

OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/kernel.json"

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

# Check kernel parameters via sysctl
check_sysctl() {
    local param="$1"
    local expected="$2"
    local check_name="$3"
    local severity="${4:-MEDIUM}"
    
    current=$(sysctl "$param" 2>/dev/null | awk '{print $3}')
    if [ "$current" = "$expected" ]; then
        add_result "$check_name" "PASS" "LOW" "$param is set to $expected"
    else
        add_result "$check_name" "FAIL" "$severity" "$param is set to $current (should be $expected)"
    fi
}

# Network security parameters
check_sysctl "net.ipv4.ip_forward" "0" "IP Forwarding" "MEDIUM"
check_sysctl "net.ipv4.conf.all.send_redirects" "0" "Send Redirects" "MEDIUM"
check_sysctl "net.ipv4.conf.default.send_redirects" "0" "Default Send Redirects" "MEDIUM"
check_sysctl "net.ipv4.conf.all.accept_redirects" "0" "Accept Redirects" "MEDIUM"
check_sysctl "net.ipv4.conf.default.accept_redirects" "0" "Default Accept Redirects" "MEDIUM"
check_sysctl "net.ipv4.conf.all.accept_source_route" "0" "Accept Source Route" "MEDIUM"
check_sysctl "net.ipv4.conf.default.accept_source_route" "0" "Default Accept Source Route" "MEDIUM"
check_sysctl "net.ipv4.icmp_echo_ignore_broadcasts" "1" "Ignore ICMP Broadcasts" "LOW"
check_sysctl "net.ipv4.icmp_ignore_bogus_error_responses" "1" "Ignore Bogus ICMP Errors" "LOW"
check_sysctl "net.ipv4.tcp_syncookies" "1" "TCP SYN Cookies" "MEDIUM"
check_sysctl "net.ipv4.conf.all.log_martians" "1" "Log Martian Packets" "LOW"
check_sysctl "net.ipv4.conf.default.log_martians" "1" "Default Log Martian Packets" "LOW"

# IPv6 security (if IPv6 is enabled)
if [ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]; then
    ipv6_disabled=$(sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | awk '{print $3}')
    if [ "$ipv6_disabled" = "1" ]; then
        add_result "IPv6 Disabled" "INFO" "LOW" "IPv6 is disabled"
    else
        check_sysctl "net.ipv6.conf.all.accept_redirects" "0" "IPv6 Accept Redirects" "MEDIUM"
        check_sysctl "net.ipv6.conf.default.accept_redirects" "0" "IPv6 Default Accept Redirects" "MEDIUM"
        check_sysctl "net.ipv6.conf.all.accept_source_route" "0" "IPv6 Accept Source Route" "MEDIUM"
    fi
fi

# Kernel security parameters
check_sysctl "kernel.dmesg_restrict" "1" "Dmesg Restrict" "MEDIUM"
check_sysctl "kernel.kptr_restrict" "2" "Kptr Restrict" "MEDIUM"
check_sysctl "kernel.yama.ptrace_scope" "1" "Ptrace Scope" "MEDIUM"

# Check if ASLR is enabled
if [ -f /proc/sys/kernel/randomize_va_space ]; then
    aslr=$(sysctl kernel.randomize_va_space 2>/dev/null | awk '{print $3}')
    if [ "$aslr" = "2" ]; then
        add_result "ASLR (Address Space Layout Randomization)" "PASS" "LOW" "ASLR is fully enabled (2)"
    elif [ "$aslr" = "1" ]; then
        add_result "ASLR (Address Space Layout Randomization)" "WARN" "MEDIUM" "ASLR is partially enabled (1)"
    else
        add_result "ASLR (Address Space Layout Randomization)" "FAIL" "HIGH" "ASLR is disabled (0)"
    fi
fi

# Check kernel version
kernel_version=$(uname -r)
add_result "Kernel Version" "INFO" "LOW" "Running kernel: $kernel_version"

# Check if kernel is up to date (basic check)
kernel_release=$(uname -r | cut -d- -f1)
add_result "Kernel Release" "INFO" "LOW" "Kernel release: $kernel_release"

# Check for exposed kernel symbols
if [ -f /proc/kallsyms ]; then
    if [ -r /proc/kallsyms ]; then
        add_result "Kernel Symbols Exposed" "WARN" "MEDIUM" "/proc/kallsyms is readable (consider restricting)"
    else
        add_result "Kernel Symbols Exposed" "PASS" "LOW" "/proc/kallsyms is not readable"
    fi
fi

# Check core dumps
core_dumps=$(sysctl fs.suid_dumpable 2>/dev/null | awk '{print $3}')
if [ "$core_dumps" = "0" ]; then
    add_result "SUID Core Dumps" "PASS" "LOW" "SUID core dumps are disabled"
else
    add_result "SUID Core Dumps" "WARN" "MEDIUM" "SUID core dumps are enabled ($core_dumps)"
fi

# Check for enabled kernel modules (security-related)
if command -v lsmod &>/dev/null; then
    module_count=$(lsmod | wc -l)
    add_result "Kernel Modules Loaded" "INFO" "LOW" "Found $module_count loaded kernel modules"
    
    # Check for specific security modules
    if lsmod | grep -q "apparmor"; then
        add_result "AppArmor Module" "PASS" "LOW" "AppArmor kernel module is loaded"
    fi
    
    if lsmod | grep -q "selinux"; then
        add_result "SELinux Module" "PASS" "LOW" "SELinux kernel module is loaded"
    fi
fi

echo "Kernel scan completed. Results saved to $RESULTS_FILE"

