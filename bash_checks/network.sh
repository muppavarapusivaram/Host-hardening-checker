#!/bin/bash
# Network and Firewall Checks

OUTPUT_DIR="/tmp/hardening-scan"
mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/network.json"

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

# Check UFW firewall status
if command -v ufw &>/dev/null; then
    ufw_status=$(ufw status 2>/dev/null | head -n 1)
    if echo "$ufw_status" | grep -q "Status: active"; then
        add_result "UFW Firewall" "PASS" "LOW" "UFW firewall is active"
    else
        add_result "UFW Firewall" "FAIL" "HIGH" "UFW firewall is not active"
    fi
else
    add_result "UFW Firewall" "WARN" "MEDIUM" "UFW is not installed"
fi

# Check iptables rules
if command -v iptables &>/dev/null; then
    iptables_rules=$(iptables -L -n 2>/dev/null | wc -l)
    if [ "$iptables_rules" -gt 8 ]; then
        add_result "IPTables Rules" "INFO" "LOW" "IPTables has $iptables_rules rules configured"
    else
        add_result "IPTables Rules" "WARN" "MEDIUM" "IPTables has minimal rules ($iptables_rules)"
    fi
fi

# Check nftables
if command -v nft &>/dev/null; then
    nft_rules=$(nft list ruleset 2>/dev/null | wc -l)
    if [ "$nft_rules" -gt 5 ]; then
        add_result "NFTables Rules" "INFO" "LOW" "NFTables has rules configured"
    else
        add_result "NFTables Rules" "WARN" "MEDIUM" "NFTables has minimal or no rules"
    fi
fi

# Check firewalld (if present)
if command -v firewall-cmd &>/dev/null; then
    if firewall-cmd --state &>/dev/null 2>&1; then
        firewall_state=$(firewall-cmd --state 2>/dev/null)
        if [ "$firewall_state" = "running" ]; then
            add_result "Firewalld" "PASS" "LOW" "Firewalld is running"
        else
            add_result "Firewalld" "FAIL" "HIGH" "Firewalld is not running"
        fi
    fi
fi

# Check IP forwarding
ip_forward=$(sysctl net.ipv4.ip_forward 2>/dev/null | awk '{print $3}')
if [ "$ip_forward" = "0" ]; then
    add_result "IP Forwarding" "PASS" "LOW" "IP forwarding is disabled"
else
    add_result "IP Forwarding" "FAIL" "MEDIUM" "IP forwarding is enabled"
fi

# Check ICMP redirects
icmp_redirect=$(sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null | awk '{print $3}')
if [ "$icmp_redirect" = "0" ]; then
    add_result "ICMP Redirects" "PASS" "LOW" "ICMP redirects are disabled"
else
    add_result "ICMP Redirects" "FAIL" "MEDIUM" "ICMP redirects are enabled"
fi

# Check source routing
source_route=$(sysctl net.ipv4.conf.all.accept_source_route 2>/dev/null | awk '{print $3}')
if [ "$source_route" = "0" ]; then
    add_result "Source Routing" "PASS" "LOW" "Source routing is disabled"
else
    add_result "Source Routing" "FAIL" "MEDIUM" "Source routing is enabled"
fi

# Check SYN cookies
syn_cookies=$(sysctl net.ipv4.tcp_syncookies 2>/dev/null | awk '{print $3}')
if [ "$syn_cookies" = "1" ]; then
    add_result "SYN Cookies" "PASS" "LOW" "SYN cookies are enabled"
else
    add_result "SYN Cookies" "FAIL" "MEDIUM" "SYN cookies are disabled"
fi

# Check for open network connections
established_conn=$(ss -tn 2>/dev/null | grep ESTAB | wc -l)
add_result "Established Connections" "INFO" "LOW" "Found $established_conn established TCP connections"

echo "Network scan completed. Results saved to $RESULTS_FILE"

