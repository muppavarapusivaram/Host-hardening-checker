#!/bin/bash
# File Permissions and SUID/SGID Checks

OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/permissions.json"

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

# Check for world-writable files (excluding /tmp, /var/tmp, /dev)
world_writable=$(find / -xdev -type f -perm -0002 ! -path "/tmp/*" ! -path "/var/tmp/*" ! -path "/dev/*" ! -path "/proc/*" ! -path "/sys/*" 2>/dev/null | head -20)
world_writable_count=$(find / -xdev -type f -perm -0002 ! -path "/tmp/*" ! -path "/var/tmp/*" ! -path "/dev/*" ! -path "/proc/*" ! -path "/sys/*" 2>/dev/null | wc -l)

if [ "$world_writable_count" -eq 0 ]; then
    add_result "World-Writable Files" "PASS" "LOW" "No world-writable files found outside /tmp and /var/tmp"
else
    add_result "World-Writable Files" "FAIL" "HIGH" "Found $world_writable_count world-writable files outside standard temp directories"
    echo "$world_writable" | while read file; do
        if [ -n "$file" ]; then
            add_result "World-Writable File: $file" "FAIL" "HIGH" "File is world-writable"
        fi
    done
fi

# Check for world-writable directories
world_writable_dirs=$(find / -xdev -type d -perm -0002 ! -path "/tmp/*" ! -path "/var/tmp/*" ! -path "/dev/*" ! -path "/proc/*" ! -path "/sys/*" ! -path "/run/*" 2>/dev/null | head -20)
world_writable_dirs_count=$(find / -xdev -type d -perm -0002 ! -path "/tmp/*" ! -path "/var/tmp/*" ! -path "/dev/*" ! -path "/proc/*" ! -path "/sys/*" ! -path "/run/*" 2>/dev/null | wc -l)

if [ "$world_writable_dirs_count" -eq 0 ]; then
    add_result "World-Writable Directories" "PASS" "LOW" "No world-writable directories found outside standard locations"
else
    add_result "World-Writable Directories" "WARN" "MEDIUM" "Found $world_writable_dirs_count world-writable directories"
fi

# Check for SUID files
suid_files=$(find / -xdev -type f -perm -4000 2>/dev/null | head -30)
suid_count=$(find / -xdev -type f -perm -4000 2>/dev/null | wc -l)

add_result "SUID Files Count" "INFO" "LOW" "Found $suid_count SUID files"

# Check for suspicious SUID files
suspicious_suid="/usr/bin/sudo /usr/bin/pkexec /usr/bin/su /bin/su /usr/bin/passwd /bin/passwd"
for file in $suspicious_suid; do
    if [ -f "$file" ]; then
        if [ -u "$file" ]; then
            add_result "SUID File: $file" "INFO" "LOW" "Expected SUID file: $file"
        fi
    fi
done

# Check for SGID files
sgid_files=$(find / -xdev -type f -perm -2000 2>/dev/null | head -30)
sgid_count=$(find / -xdev -type f -perm -2000 2>/dev/null | wc -l)

add_result "SGID Files Count" "INFO" "LOW" "Found $sgid_count SGID files"

# Check for files with both SUID and SGID
suid_sgid=$(find / -xdev -type f -perm -6000 2>/dev/null | head -20)
suid_sgid_count=$(find / -xdev -type f -perm -6000 2>/dev/null | wc -l)

if [ "$suid_sgid_count" -gt 0 ]; then
    add_result "SUID+SGID Files" "WARN" "MEDIUM" "Found $suid_sgid_count files with both SUID and SGID"
fi

# Check /tmp permissions
if [ -d "/tmp" ]; then
    tmp_perm=$(stat -c "%a" /tmp 2>/dev/null)
    if [ "$tmp_perm" = "1777" ]; then
        add_result "/tmp Permissions" "PASS" "LOW" "/tmp has correct permissions with sticky bit: $tmp_perm"
    else
        add_result "/tmp Permissions" "WARN" "MEDIUM" "/tmp permissions: $tmp_perm (should be 1777)"
    fi
fi

# Check /var/tmp permissions
if [ -d "/var/tmp" ]; then
    vartmp_perm=$(stat -c "%a" /var/tmp 2>/dev/null)
    if [ "$vartmp_perm" = "1777" ]; then
        add_result "/var/tmp Permissions" "PASS" "LOW" "/var/tmp has correct permissions with sticky bit: $vartmp_perm"
    else
        add_result "/var/tmp Permissions" "WARN" "MEDIUM" "/var/tmp permissions: $vartmp_perm (should be 1777)"
    fi
fi

# Check home directory permissions
getent passwd | awk -F: '$3 >= 1000 {print $6}' | while read home; do
    if [ -d "$home" ] && [ "$home" != "/" ]; then
        home_perm=$(stat -c "%a" "$home" 2>/dev/null)
        # Home directories should be 700 or 750
        if [ "$home_perm" = "700" ] || [ "$home_perm" = "750" ]; then
            add_result "Home Directory: $home" "PASS" "LOW" "Home directory has secure permissions: $home_perm"
        else
            add_result "Home Directory: $home" "WARN" "MEDIUM" "Home directory permissions: $home_perm (should be 700 or 750)"
        fi
    fi
done | head -10

# Check for files owned by root but writable by group/others
root_writable=$(find /etc /usr/bin /usr/sbin /bin /sbin -xdev -user root -perm -002 -type f 2>/dev/null | head -20)
if [ -z "$root_writable" ]; then
    add_result "Root-Owned Writable Files" "PASS" "LOW" "No root-owned files are world-writable in system directories"
else
    add_result "Root-Owned Writable Files" "FAIL" "HIGH" "Found root-owned world-writable files in system directories"
fi

echo "Permissions scan completed. Results saved to $RESULTS_FILE"

