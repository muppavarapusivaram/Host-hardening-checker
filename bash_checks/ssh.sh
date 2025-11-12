#!/bin/bash
# SSH Configuration Checks

OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/ssh.json"

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

SSH_CONFIG="/etc/ssh/sshd_config"

if [ ! -f "$SSH_CONFIG" ]; then
    add_result "SSH Config File" "WARN" "MEDIUM" "SSH config file not found at $SSH_CONFIG"
    echo "SSH scan completed. Results saved to $RESULTS_FILE"
    exit 0
fi

# Check if SSH is running
if systemctl is-active sshd &>/dev/null || systemctl is-active ssh &>/dev/null; then
    add_result "SSH Service" "INFO" "LOW" "SSH service is running"
else
    add_result "SSH Service" "WARN" "MEDIUM" "SSH service is not running"
fi

# Use sshd -T to get effective configuration
if command -v sshd &>/dev/null; then
    # Check PermitRootLogin
    root_login=$(sshd -T 2>/dev/null | grep -i permitrootlogin | awk '{print $2}')
    if [ "$root_login" = "no" ] || [ "$root_login" = "prohibit-password" ]; then
        add_result "SSH PermitRootLogin" "PASS" "LOW" "Root login is restricted: $root_login"
    else
        add_result "SSH PermitRootLogin" "FAIL" "HIGH" "Root login is permitted: $root_login"
    fi
    
    # Check PasswordAuthentication
    password_auth=$(sshd -T 2>/dev/null | grep -i passwordauthentication | awk '{print $2}')
    if [ "$password_auth" = "no" ]; then
        add_result "SSH PasswordAuthentication" "PASS" "LOW" "Password authentication is disabled"
    else
        add_result "SSH PasswordAuthentication" "WARN" "MEDIUM" "Password authentication is enabled"
    fi
    
    # Check PubkeyAuthentication
    pubkey_auth=$(sshd -T 2>/dev/null | grep -i pubkeyauthentication | awk '{print $2}')
    if [ "$pubkey_auth" = "yes" ]; then
        add_result "SSH PubkeyAuthentication" "PASS" "LOW" "Public key authentication is enabled"
    else
        add_result "SSH PubkeyAuthentication" "WARN" "MEDIUM" "Public key authentication is disabled"
    fi
    
    # Check X11Forwarding
    x11_forward=$(sshd -T 2>/dev/null | grep -i x11forwarding | awk '{print $2}')
    if [ "$x11_forward" = "no" ]; then
        add_result "SSH X11Forwarding" "PASS" "LOW" "X11 forwarding is disabled"
    else
        add_result "SSH X11Forwarding" "WARN" "MEDIUM" "X11 forwarding is enabled"
    fi
    
    # Check Protocol version
    protocol=$(sshd -T 2>/dev/null | grep -i protocol | awk '{print $2}')
    if echo "$protocol" | grep -q "2"; then
        add_result "SSH Protocol" "PASS" "LOW" "SSH Protocol 2 is enabled"
    else
        add_result "SSH Protocol" "FAIL" "HIGH" "SSH Protocol 1 may be enabled"
    fi
    
    # Check MaxAuthTries
    max_auth=$(sshd -T 2>/dev/null | grep -i maxauthtries | awk '{print $2}')
    if [ -n "$max_auth" ] && [ "$max_auth" -le 3 ]; then
        add_result "SSH MaxAuthTries" "PASS" "LOW" "MaxAuthTries is set to $max_auth"
    else
        add_result "SSH MaxAuthTries" "WARN" "MEDIUM" "MaxAuthTries is $max_auth (should be <= 3)"
    fi
    
    # Check PermitEmptyPasswords
    empty_pass=$(sshd -T 2>/dev/null | grep -i permitemptypasswords | awk '{print $2}')
    if [ "$empty_pass" = "no" ]; then
        add_result "SSH PermitEmptyPasswords" "PASS" "LOW" "Empty passwords are not permitted"
    else
        add_result "SSH PermitEmptyPasswords" "FAIL" "HIGH" "Empty passwords are permitted"
    fi
fi

# Check SSH config file permissions
if [ -f "$SSH_CONFIG" ]; then
    ssh_perm=$(stat -c "%a" "$SSH_CONFIG" 2>/dev/null)
    if [ "$ssh_perm" = "644" ] || [ "$ssh_perm" = "600" ]; then
        add_result "SSH Config Permissions" "PASS" "LOW" "SSH config has secure permissions: $ssh_perm"
    else
        add_result "SSH Config Permissions" "WARN" "MEDIUM" "SSH config permissions: $ssh_perm (should be 644 or 600)"
    fi
fi

# Check for default SSH keys
if [ -d "/etc/ssh" ]; then
    default_keys=$(find /etc/ssh -name "ssh_host_*_key" -type f 2>/dev/null | wc -l)
    if [ "$default_keys" -gt 0 ]; then
        add_result "SSH Host Keys" "INFO" "LOW" "Found $default_keys SSH host keys"
    fi
fi

echo "SSH scan completed. Results saved to $RESULTS_FILE"

