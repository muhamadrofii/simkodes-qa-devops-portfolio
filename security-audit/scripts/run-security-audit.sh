#!/usr/bin/env bash
set -e

# ==============================================================================
# Dependency Vulnerability Audit Script
# Runs Composer and NPM audits against known CVE advisory databases
# ==============================================================================

echo "Starting dependency security scan..."

REPORT_FILE="security-audit/reports/audit-summary-$(date +'%Y%m%d').md"
mkdir -p security-audit/reports

echo "# Dependency Security Audit Report - $(date +'%Y-%m-%d')" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 1. Composer Security Audit (PHP)
echo "Running Composer security audit..."
echo "## Composer Audit (PHP Backend)" >> "$REPORT_FILE"
echo '```text' >> "$REPORT_FILE"

if composer audit --locked --format=plain >> "$REPORT_FILE" 2>&1; then
    echo "Composer audit: No critical advisories detected."
else
    echo "Composer audit: Advisories found (recorded in report)."
fi

echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 2. NPM Security Audit (JavaScript / Vite)
echo "Running NPM security audit..."
echo "## NPM Audit (Frontend / Build Tools)" >> "$REPORT_FILE"
echo '```text' >> "$REPORT_FILE"

if npm audit --audit-level=high >> "$REPORT_FILE" 2>&1; then
    echo "NPM audit: No high or critical vulnerabilities detected."
else
    echo "NPM audit: Vulnerabilities detected (recorded in report)."
fi

echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Audit completed. Report saved to: $REPORT_FILE"
