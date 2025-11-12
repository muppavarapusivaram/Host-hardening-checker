#!/usr/bin/env python3
"""
Report generator module for creating HTML reports.
"""

import os
from datetime import datetime
from typing import List, Dict
from .parser import ScanParser


class ReportGenerator:
    """Generates HTML reports from scan results."""
    
    def __init__(self, output_dir: str = None):
        """
        Initialize report generator.
        
        Args:
            output_dir: Directory to save reports
        """
        if output_dir is None:
            # Default to reports/ relative to project root
            script_dir = os.path.dirname(os.path.abspath(__file__))
            project_root = os.path.dirname(script_dir)
            output_dir = os.path.join(project_root, "reports")
        
        self.output_dir = output_dir
        os.makedirs(self.output_dir, exist_ok=True)
    
    def _get_severity_color(self, severity: str) -> str:
        """Get color code for severity level."""
        colors = {
            'HIGH': '#dc3545',  # Red
            'MEDIUM': '#ffc107',  # Yellow
            'LOW': '#28a745'  # Green
        }
        return colors.get(severity, '#6c757d')  # Gray default
    
    def _get_result_badge(self, result: str) -> str:
        """Get badge HTML for result."""
        badges = {
            'PASS': '<span class="badge badge-success">PASS</span>',
            'FAIL': '<span class="badge badge-danger">FAIL</span>',
            'WARN': '<span class="badge badge-warning">WARN</span>',
            'INFO': '<span class="badge badge-info">INFO</span>'
        }
        return badges.get(result, f'<span class="badge badge-secondary">{result}</span>')
    
    def generate_html(self, results: List[Dict], summary: Dict) -> str:
        """
        Generate HTML report from results.
        
        Args:
            results: List of parsed scan results
            summary: Summary statistics dictionary
        
        Returns:
            HTML content as string
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Host Hardening Check Report</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            color: #333;
            line-height: 1.6;
            padding: 20px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #2c3e50;
            margin-bottom: 10px;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }}
        .timestamp {{
            color: #7f8c8d;
            margin-bottom: 30px;
            font-size: 0.9em;
        }}
        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        .summary-card {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }}
        .summary-card.high {{
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }}
        .summary-card.medium {{
            background: linear-gradient(135deg, #f6d365 0%, #fda085 100%);
        }}
        .summary-card.low {{
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }}
        .summary-card.passed {{
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
        }}
        .summary-card h3 {{
            font-size: 2em;
            margin-bottom: 5px;
        }}
        .summary-card p {{
            font-size: 0.9em;
            opacity: 0.9;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background-color: white;
        }}
        th {{
            background-color: #34495e;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }}
        td {{
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }}
        tr:hover {{
            background-color: #f8f9fa;
        }}
        .severity-high {{
            background-color: #ffe6e6;
            border-left: 4px solid #dc3545;
        }}
        .severity-medium {{
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
        }}
        .severity-low {{
            background-color: #d4edda;
            border-left: 4px solid #28a745;
        }}
        .badge {{
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
        }}
        .badge-success {{
            background-color: #28a745;
            color: white;
        }}
        .badge-danger {{
            background-color: #dc3545;
            color: white;
        }}
        .badge-warning {{
            background-color: #ffc107;
            color: #333;
        }}
        .badge-info {{
            background-color: #17a2b8;
            color: white;
        }}
        .badge-secondary {{
            background-color: #6c757d;
            color: white;
        }}
        .remediation {{
            font-size: 0.9em;
            color: #555;
            font-style: italic;
        }}
        .details {{
            font-size: 0.85em;
            color: #777;
            margin-top: 5px;
        }}
        .filter-buttons {{
            margin-bottom: 20px;
        }}
        .filter-btn {{
            padding: 8px 16px;
            margin-right: 10px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            background-color: #3498db;
            color: white;
            font-weight: bold;
        }}
        .filter-btn:hover {{
            background-color: #2980b9;
        }}
        .filter-btn.active {{
            background-color: #2c3e50;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Host Hardening Check Report</h1>
        <p class="timestamp">Generated on: {timestamp}</p>
        
        <div class="summary">
            <div class="summary-card high">
                <h3>{summary.get('high', 0)}</h3>
                <p>High Severity Issues</p>
            </div>
            <div class="summary-card medium">
                <h3>{summary.get('medium', 0)}</h3>
                <p>Medium Severity Issues</p>
            </div>
            <div class="summary-card low">
                <h3>{summary.get('low', 0)}</h3>
                <p>Low Severity / Passed</p>
            </div>
            <div class="summary-card passed">
                <h3>{summary.get('passed', 0)}</h3>
                <p>Passed Checks</p>
            </div>
            <div class="summary-card">
                <h3>{summary.get('total', 0)}</h3>
                <p>Total Checks</p>
            </div>
        </div>
        
        <h2>Detailed Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Check Name</th>
                    <th>Result</th>
                    <th>Severity</th>
                    <th>Remediation</th>
                </tr>
            </thead>
            <tbody>
"""
        
        # Sort results by severity (HIGH first)
        severity_order = {'HIGH': 0, 'MEDIUM': 1, 'LOW': 2}
        sorted_results = sorted(results, key=lambda x: (
            severity_order.get(x['severity'], 3),
            x['check_name']
        ))
        
        for result in sorted_results:
            severity = result['severity']
            result_status = result['result']
            severity_class = f"severity-{severity.lower()}"
            
            html += f"""
                <tr class="{severity_class}">
                    <td>
                        <strong>{result['check_name']}</strong>
                        {f'<div class="details">{result.get("details", "")}</div>' if result.get('details') else ''}
                    </td>
                    <td>{self._get_result_badge(result_status)}</td>
                    <td>
                        <span style="color: {self._get_severity_color(severity)}; font-weight: bold;">
                            {severity}
                        </span>
                    </td>
                    <td class="remediation">{result['remediation']}</td>
                </tr>
"""
        
        html += """
            </tbody>
        </table>
    </div>
</body>
</html>
"""
        
        return html
    
    def save_report(self, results: List[Dict], summary: Dict) -> str:
        """
        Generate and save HTML report to file.
        
        Args:
            results: List of parsed scan results
            summary: Summary statistics dictionary
        
        Returns:
            Path to saved report file
        """
        html_content = self.generate_html(results, summary)
        
        # Generate filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"hardening_report_{timestamp}.html"
        filepath = os.path.join(self.output_dir, filename)
        
        with open(filepath, 'w') as f:
            f.write(html_content)
        
        return filepath

