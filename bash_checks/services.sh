#!/bin/bash
# Services and Systemd Checks

OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/services.json"

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

# Check for unnecessary services
check_service() {
    local service="$1"
    if systemctl is-enabled "$service" &>/dev/null; then
        if systemctl is-enabled "$service" | grep -q "enabled"; then
            add_result "Service: $service" "FAIL" "HIGH" "Service $service is enabled and running"
        else
            add_result "Service: $service" "PASS" "LOW" "Service $service is disabled"
        fi
    else
        add_result "Service: $service" "PASS" "LOW" "Service $service is not installed"
    fi
}

# Check common unnecessary services
check_service "telnet"
check_service "rsh"
check_service "rlogin"
check_service "rexec"
check_service "xinetd"
check_service "tftp"
check_service "vsftpd"

# Check for listening services
listening_services=$(ss -tuln 2>/dev/null | grep LISTEN | wc -l)
add_result "Listening Services Count" "INFO" "MEDIUM" "Found $listening_services listening services"

# Check for open ports (non-standard ports)
ss -tuln 2>/dev/null | grep LISTEN | while read line; do
    port=$(echo "$line" | awk '{print $5}' | cut -d: -f2)
    if [ "$port" -lt 1024 ] && [ "$port" -ne 22 ] && [ "$port" -ne 80 ] && [ "$port" -ne 443 ]; then
        add_result "Open Port: $port" "WARN" "MEDIUM" "Non-standard port $port is open"
    fi
done

# Check systemd service status
if systemctl is-system-running &>/dev/null; then
    system_status=$(systemctl is-system-running)
    add_result "Systemd Status" "INFO" "LOW" "System is $system_status"
fi

# Check for failed services
failed_services=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if [ "$failed_services" -gt 0 ]; then
    add_result "Failed Services" "WARN" "MEDIUM" "Found $failed_services failed systemd services"
else
    add_result "Failed Services" "PASS" "LOW" "No failed services found"
fi

echo "Services scan completed. Results saved to $RESULTS_FILE"

