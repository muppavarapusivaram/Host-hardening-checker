#!/usr/bin/env python3
"""
PyQt GUI module for Host Hardening Checker.
"""

import sys
import os
import subprocess
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QTableWidget, QTableWidgetItem, QHeaderView,
    QMessageBox, QLabel, QProgressBar, QFileDialog
)
from PyQt5.QtCore import Qt, QThread, pyqtSignal
from PyQt5.QtGui import QColor, QFont

from .parser import ScanParser
from .report import ReportGenerator


class ScanThread(QThread):
    """Thread for running bash scan scripts."""
    
    finished = pyqtSignal(bool, str)
    progress = pyqtSignal(str)
    
    def __init__(self, script_dir):
        super().__init__()
        self.script_dir = script_dir
    
    def run(self):
        """Run the scan script."""
        try:
            script_path = os.path.join(self.script_dir, "bash_checks", "run_all.sh")
            if not os.path.exists(script_path):
                self.finished.emit(False, f"Scan script not found: {script_path}")
                return
            
            self.progress.emit("Starting scan...")
            
            process = subprocess.Popen(
                ["bash", script_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Read output in real-time
            output_lines = []
            for line in iter(process.stdout.readline, ''):
                if line:
                    line = line.strip()
                    output_lines.append(line)
                    self.progress.emit(line)
            
            process.wait()
            
            if process.returncode == 0:
                self.finished.emit(True, "Scan completed successfully")
            else:
                error_msg = "\n".join(output_lines[-10:])  # Last 10 lines
                self.finished.emit(False, f"Scan failed with return code {process.returncode}\n{error_msg}")
        
        except FileNotFoundError:
            self.finished.emit(False, "bash command not found. Please ensure bash is installed.")
        except Exception as e:
            self.finished.emit(False, f"Error running scan: {str(e)}")


class HardeningCheckerGUI(QMainWindow):
    """Main GUI window for Host Hardening Checker."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Host Hardening Checker")
        self.setGeometry(100, 100, 1200, 800)
        
        # Initialize components
        script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.script_dir = script_dir
        self.parser = ScanParser()
        self.report_generator = ReportGenerator()
        self.scan_thread = None
        
        # Setup UI
        self.init_ui()
        
        # Load initial results if available
        self.refresh_results()
    
    def init_ui(self):
        """Initialize the user interface."""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        layout = QVBoxLayout()
        central_widget.setLayout(layout)
        
        # Title
        title = QLabel("Host Hardening Checker")
        title.setFont(QFont("Arial", 16, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        # Button layout
        button_layout = QHBoxLayout()
        
        self.run_scan_btn = QPushButton("Run Full Scan")
        self.run_scan_btn.setStyleSheet("""
            QPushButton {
                background-color: #3498db;
                color: white;
                padding: 10px;
                border-radius: 5px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #2980b9;
            }
            QPushButton:disabled {
                background-color: #95a5a6;
            }
        """)
        self.run_scan_btn.clicked.connect(self.run_scan)
        button_layout.addWidget(self.run_scan_btn)
        
        self.refresh_btn = QPushButton("Refresh Results")
        self.refresh_btn.setStyleSheet("""
            QPushButton {
                background-color: #2ecc71;
                color: white;
                padding: 10px;
                border-radius: 5px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #27ae60;
            }
        """)
        self.refresh_btn.clicked.connect(self.refresh_results)
        button_layout.addWidget(self.refresh_btn)
        
        self.export_btn = QPushButton("Export Report to HTML")
        self.export_btn.setStyleSheet("""
            QPushButton {
                background-color: #e74c3c;
                color: white;
                padding: 10px;
                border-radius: 5px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #c0392b;
            }
        """)
        self.export_btn.clicked.connect(self.export_report)
        button_layout.addWidget(self.export_btn)
        
        button_layout.addStretch()
        layout.addLayout(button_layout)
        
        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        layout.addWidget(self.progress_bar)
        
        # Status label
        self.status_label = QLabel("Ready")
        self.status_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.status_label)
        
        # Results table
        self.table = QTableWidget()
        self.table.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(["Check Name", "Result", "Severity", "Remediation"])
        
        # Set column widths
        header = self.table.horizontalHeader()
        header.setSectionResizeMode(0, QHeaderView.Stretch)
        header.setSectionResizeMode(1, QHeaderView.ResizeToContents)
        header.setSectionResizeMode(2, QHeaderView.ResizeToContents)
        header.setSectionResizeMode(3, QHeaderView.Stretch)
        
        # Style the table
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QTableWidget.SelectRows)
        self.table.setEditTriggers(QTableWidget.NoEditTriggers)
        
        layout.addWidget(self.table)
        
        # Summary label
        self.summary_label = QLabel("")
        self.summary_label.setAlignment(Qt.AlignCenter)
        self.summary_label.setStyleSheet("font-weight: bold; padding: 10px;")
        layout.addWidget(self.summary_label)
    
    def run_scan(self):
        """Run the bash scan scripts."""
        if self.scan_thread and self.scan_thread.isRunning():
            QMessageBox.warning(self, "Scan Running", "A scan is already in progress.")
            return
        
        # Disable button during scan
        self.run_scan_btn.setEnabled(False)
        self.progress_bar.setVisible(True)
        self.progress_bar.setRange(0, 0)  # Indeterminate
        self.status_label.setText("Running scan...")
        
        # Start scan thread
        self.scan_thread = ScanThread(self.script_dir)
        self.scan_thread.finished.connect(self.on_scan_finished)
        self.scan_thread.progress.connect(self.on_scan_progress)
        self.scan_thread.start()
    
    def on_scan_progress(self, message):
        """Update progress message."""
        self.status_label.setText(message)
    
    def on_scan_finished(self, success, message):
        """Handle scan completion."""
        self.run_scan_btn.setEnabled(True)
        self.progress_bar.setVisible(False)
        
        if success:
            self.status_label.setText("Scan completed successfully")
            self.refresh_results()
            QMessageBox.information(self, "Scan Complete", "Scan completed successfully!")
        else:
            self.status_label.setText(f"Scan failed: {message}")
            QMessageBox.critical(self, "Scan Failed", message)
    
    def refresh_results(self):
        """Refresh the results table."""
        try:
            results = self.parser.parse_results()
            summary = self.parser.get_summary()
            
            # Update table
            self.table.setRowCount(len(results))
            
            for row, result in enumerate(results):
                # Check Name
                check_item = QTableWidgetItem(result['check_name'])
                if result.get('details'):
                    check_item.setToolTip(result['details'])
                self.table.setItem(row, 0, check_item)
                
                # Result
                result_item = QTableWidgetItem(result['result'])
                result_item.setTextAlignment(Qt.AlignCenter)
                if result['result'] == 'PASS':
                    result_item.setForeground(QColor(40, 167, 69))
                elif result['result'] == 'FAIL':
                    result_item.setForeground(QColor(220, 53, 69))
                elif result['result'] == 'WARN':
                    result_item.setForeground(QColor(255, 193, 7))
                self.table.setItem(row, 1, result_item)
                
                # Severity
                severity_item = QTableWidgetItem(result['severity'])
                severity_item.setTextAlignment(Qt.AlignCenter)
                if result['severity'] == 'HIGH':
                    severity_item.setForeground(QColor(220, 53, 69))
                    severity_item.setBackground(QColor(255, 230, 230))
                elif result['severity'] == 'MEDIUM':
                    severity_item.setForeground(QColor(255, 193, 7))
                    severity_item.setBackground(QColor(255, 248, 220))
                else:
                    severity_item.setForeground(QColor(40, 167, 69))
                    severity_item.setBackground(QColor(230, 255, 230))
                self.table.setItem(row, 2, severity_item)
                
                # Remediation
                remediation_item = QTableWidgetItem(result['remediation'])
                remediation_item.setToolTip(result['remediation'])
                self.table.setItem(row, 3, remediation_item)
            
            # Update summary
            summary_text = (
                f"Total: {summary['total']} | "
                f"High: {summary['high']} | "
                f"Medium: {summary['medium']} | "
                f"Low: {summary['low']} | "
                f"Passed: {summary['passed']} | "
                f"Failed: {summary['failed']} | "
                f"Warnings: {summary['warnings']}"
            )
            self.summary_label.setText(summary_text)
            
            self.status_label.setText(f"Loaded {len(results)} results")
        
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Error loading results: {str(e)}")
            self.status_label.setText("Error loading results")
    
    def export_report(self):
        """Export results to HTML report."""
        try:
            results = self.parser.parse_results()
            summary = self.parser.get_summary()
            
            if not results:
                QMessageBox.warning(self, "No Data", "No scan results available. Please run a scan first.")
                return
            
            # Generate and save report
            report_path = self.report_generator.save_report(results, summary)
            
            QMessageBox.information(
                self,
                "Report Exported",
                f"Report exported successfully to:\n{report_path}"
            )
        
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Error exporting report: {str(e)}")


def main():
    """Main function to run the GUI."""
    app = QApplication(sys.argv)
    window = HardeningCheckerGUI()
    window.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()

