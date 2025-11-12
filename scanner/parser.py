#!/usr/bin/env python3
"""
Parser module for reading and processing hardening scan results.
"""

import json
import os
import re
import yaml
from typing import List, Dict, Optional


class ScanParser:
    """Parses JSON scan results and applies YAML rules."""
    
    def __init__(self, rules_file: str = None):
        """
        Initialize the parser with rules file.
        
        Args:
            rules_file: Path to YAML rules file
        """
        if rules_file is None:
            # Default to rules/rules.yaml relative to project root
            script_dir = os.path.dirname(os.path.abspath(__file__))
            project_root = os.path.dirname(script_dir)
            rules_file = os.path.join(project_root, "rules", "rules.yaml")
        
        self.rules_file = rules_file
        self.rules = self._load_rules()
        self.scan_dir = "/tmp/hardening-scan"
    
    def _load_rules(self) -> Dict:
        """Load rules from YAML file."""
        try:
            with open(self.rules_file, 'r') as f:
                rules_data = yaml.safe_load(f)
                return rules_data.get('rules', [])
        except FileNotFoundError:
            print(f"Warning: Rules file not found: {self.rules_file}")
            return []
        except yaml.YAMLError as e:
            print(f"Error parsing YAML rules: {e}")
            return []
    
    def _find_rule(self, check_name: str) -> Optional[Dict]:
        """Find matching rule for a check name."""
        # Try exact match first
        for rule in self.rules:
            if rule.get('check_name') == check_name:
                return rule
        
        # Try regex match
        for rule in self.rules:
            pattern = rule.get('check_name', '')
            if pattern.startswith('.*') or '*' in pattern:
                # Convert to regex
                regex_pattern = pattern.replace('*', '.*')
                if re.match(regex_pattern, check_name):
                    return rule
        
        # Return default rule if exists
        for rule in self.rules:
            if rule.get('check_name') == '.*':
                return rule
        
        return None
    
    def _determine_severity(self, check_name: str, status: str, result: str) -> str:
        """
        Determine severity level for a check result.
        
        Args:
            check_name: Name of the check
            status: Status from scan (HIGH, MEDIUM, LOW)
            result: Result from scan (PASS, FAIL, WARN, INFO)
        
        Returns:
            Severity level (HIGH, MEDIUM, LOW)
        """
        # First check if rule exists and has severity
        rule = self._find_rule(check_name)
        if rule and 'severity' in rule:
            return rule['severity']
        
        # Fallback to status from scan
        if status in ['HIGH', 'MEDIUM', 'LOW']:
            return status
        
        # Determine based on result
        if result == "FAIL":
            return "HIGH"
        elif result == "WARN":
            return "MEDIUM"
        elif result == "PASS":
            return "LOW"
        else:
            return "LOW"
    
    def _get_remediation(self, check_name: str) -> str:
        """Get remediation text for a check."""
        rule = self._find_rule(check_name)
        if rule and 'remediation' in rule:
            return rule['remediation']
        return "Review and address the issue based on security best practices."
    
    def load_scan_results(self) -> List[Dict]:
        """
        Load all JSON scan results from scan directory.
        
        Returns:
            List of parsed check results
        """
        if not os.path.exists(self.scan_dir):
            return []
        
        all_results = []
        json_files = [
            'services.json',
            'network.json',
            'ssh.json',
            'users.json',
            'permissions.json',
            'kernel.json',
            'security.json'
        ]
        
        for json_file in json_files:
            file_path = os.path.join(self.scan_dir, json_file)
            if os.path.exists(file_path):
                try:
                    with open(file_path, 'r') as f:
                        content = f.read().strip()
                        if not content or content == '[]':
                            continue
                        data = json.loads(content)
                        if isinstance(data, list):
                            all_results.extend(data)
                        elif isinstance(data, dict):
                            all_results.append(data)
                except json.JSONDecodeError as e:
                    print(f"Error parsing {json_file}: {e}")
                    continue
                except Exception as e:
                    print(f"Error reading {json_file}: {e}")
                    continue
        
        return all_results
    
    def parse_results(self) -> List[Dict]:
        """
        Parse scan results and enrich with rules.
        
        Returns:
            List of parsed results with severity and remediation
        """
        raw_results = self.load_scan_results()
        parsed_results = []
        
        for result in raw_results:
            check_name = result.get('check_name', 'Unknown Check')
            result_status = result.get('result', 'UNKNOWN')
            status = result.get('status', 'LOW')
            details = result.get('details', '')
            
            # Determine severity
            severity = self._determine_severity(check_name, status, result_status)
            
            # Get remediation
            remediation = self._get_remediation(check_name)
            
            parsed_result = {
                'check_name': check_name,
                'result': result_status,
                'severity': severity,
                'remediation': remediation,
                'details': details
            }
            
            parsed_results.append(parsed_result)
        
        return parsed_results
    
    def get_summary(self) -> Dict:
        """
        Get summary statistics of scan results.
        
        Returns:
            Dictionary with summary statistics
        """
        results = self.parse_results()
        
        total = len(results)
        high = sum(1 for r in results if r['severity'] == 'HIGH' and r['result'] in ['FAIL', 'WARN'])
        medium = sum(1 for r in results if r['severity'] == 'MEDIUM' and r['result'] in ['FAIL', 'WARN'])
        low = sum(1 for r in results if r['severity'] == 'LOW' or r['result'] == 'PASS')
        passed = sum(1 for r in results if r['result'] == 'PASS')
        failed = sum(1 for r in results if r['result'] == 'FAIL')
        warnings = sum(1 for r in results if r['result'] == 'WARN')
        
        return {
            'total': total,
            'high': high,
            'medium': medium,
            'low': low,
            'passed': passed,
            'failed': failed,
            'warnings': warnings
        }

