#!/bin/bash
# User and Group Security Checks

OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/users.json"

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

# Check for users with UID 0 (root)
uid0_users=$(getent passwd | awk -F: '$3 == 0 {print $1}' | grep -v "^root$")
if [ -z "$uid0_users" ]; then
    add_result "UID 0 Users" "PASS" "LOW" "Only root has UID 0"
else
    add_result "UID 0 Users" "FAIL" "HIGH" "Users with UID 0 found: $uid0_users"
fi

# Check for empty password accounts
empty_pass=$(getent passwd | awk -F: '($2 == "" || $2 == "!") {print $1}')
if [ -z "$empty_pass" ]; then
    add_result "Empty Password Accounts" "PASS" "LOW" "No accounts with empty passwords"
else
    add_result "Empty Password Accounts" "FAIL" "HIGH" "Accounts with empty passwords: $empty_pass"
fi

# Check for users without passwords (locked accounts should have ! or *)
getent passwd | while IFS=: read -r user pass uid gid gecos home shell; do
    if [ -n "$pass" ] && [ "$pass" != "*" ] && [ "$pass" != "!" ] && [ "$uid" -ge 1000 ]; then
        # Check if password is actually set (this is a basic check)
        if [ "$pass" != "x" ]; then
            # This might indicate password in /etc/passwd (very bad)
            add_result "User Password Storage" "WARN" "HIGH" "User $user may have password in /etc/passwd"
        fi
    fi
done

# Check password expiration
getent passwd | awk -F: '$3 >= 1000 {print $1}' | while read user; do
    if chage -l "$user" &>/dev/null; then
        max_days=$(chage -l "$user" 2>/dev/null | grep "Maximum number of days" | awk -F: '{print $2}' | tr -d ' ')
        if [ -z "$max_days" ] || [ "$max_days" = "99999" ]; then
            add_result "Password Expiration: $user" "WARN" "MEDIUM" "User $user has no password expiration"
        fi
    fi
done

# Check for default/system accounts with shells
system_accounts_with_shells=$(getent passwd | awk -F: '$3 < 1000 && $7 != "/usr/sbin/nologin" && $7 != "/bin/false" && $7 != "/sbin/nologin" {print $1}')
if [ -z "$system_accounts_with_shells" ]; then
    add_result "System Accounts with Shells" "PASS" "LOW" "System accounts have restricted shells"
else
    add_result "System Accounts with Shells" "WARN" "MEDIUM" "System accounts with shells: $system_accounts_with_shells"
fi

# Check sudo configuration
if command -v sudo &>/dev/null; then
    sudo_users=$(getent group sudo 2>/dev/null | cut -d: -f4)
    if [ -n "$sudo_users" ]; then
        add_result "Sudo Users" "INFO" "LOW" "Users with sudo access: $sudo_users"
    fi
    
    # Check sudoers file permissions
    if [ -f "/etc/sudoers" ]; then
        sudoers_perm=$(stat -c "%a" /etc/sudoers 2>/dev/null)
        if [ "$sudoers_perm" = "440" ] || [ "$sudoers_perm" = "400" ]; then
            add_result "Sudoers File Permissions" "PASS" "LOW" "Sudoers file has secure permissions: $sudoers_perm"
        else
            add_result "Sudoers File Permissions" "FAIL" "HIGH" "Sudoers file permissions: $sudoers_perm (should be 440)"
        fi
    fi
fi

# Check for users in administrative groups
admin_groups="sudo wheel adm admin"
for group in $admin_groups; do
    if getent group "$group" &>/dev/null; then
        members=$(getent group "$group" | cut -d: -f4)
        if [ -n "$members" ]; then
            add_result "Admin Group: $group" "INFO" "LOW" "Members of $group: $members"
        fi
    fi
done

# Check /etc/passwd permissions
passwd_perm=$(stat -c "%a" /etc/passwd 2>/dev/null)
if [ "$passwd_perm" = "644" ]; then
    add_result "/etc/passwd Permissions" "PASS" "LOW" "/etc/passwd has correct permissions: $passwd_perm"
else
    add_result "/etc/passwd Permissions" "WARN" "MEDIUM" "/etc/passwd permissions: $passwd_perm (should be 644)"
fi

# Check /etc/shadow permissions
shadow_perm=$(stat -c "%a" /etc/shadow 2>/dev/null)
if [ "$shadow_perm" = "640" ] || [ "$shadow_perm" = "0" ]; then
    add_result "/etc/shadow Permissions" "PASS" "LOW" "/etc/shadow has secure permissions: $shadow_perm"
else
    add_result "/etc/shadow Permissions" "FAIL" "HIGH" "/etc/shadow permissions: $shadow_perm (should be 640 or 0)"
fi

# Check /etc/group permissions
group_perm=$(stat -c "%a" /etc/group 2>/dev/null)
if [ "$group_perm" = "644" ]; then
    add_result "/etc/group Permissions" "PASS" "LOW" "/etc/group has correct permissions: $group_perm"
else
    add_result "/etc/group Permissions" "WARN" "MEDIUM" "/etc/group permissions: $group_perm (should be 644)"
fi

# Check for recent login failures
if [ -f "/var/log/auth.log" ] || [ -f "/var/log/secure" ]; then
    recent_failures=$(grep -i "failed password" /var/log/auth.log /var/log/secure 2>/dev/null | tail -20 | wc -l)
    if [ "$recent_failures" -gt 0 ]; then
        add_result "Recent Login Failures" "WARN" "MEDIUM" "Found $recent_failures recent failed login attempts"
    fi
fi

echo "Users scan completed. Results saved to $RESULTS_FILE"

