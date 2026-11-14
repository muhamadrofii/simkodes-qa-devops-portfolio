#!/usr/bin/env bash
set -e

# ==============================================================================
# Script Otomasi Security Scanning & Vulnerability Audit untuk SIMKODES
# Memeriksa dependensi backend (Composer) dan frontend (NPM) terhadap database CVE
# ==============================================================================

echo "========================================================"
echo "🛡️  MEMULAI SECURITY & DEPENDENCY AUDIT SIMKODES"
echo "========================================================"

REPORT_FILE="security-audit/reports/audit-summary-$(date +'%Y%m%d').md"
mkdir -p security-audit/reports

echo "# 🛡️ Laporan Audit Keamanan Dependensi - $(date +'%d %B %Y')" > "$REPORT_FILE"
echo "Generated automatically by security audit automation script." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 1. Composer Security Audit (PHP)
echo "🔍 1. Menjalankan Composer Security Audit..."
echo "### 🐘 1. Hasil Audit Composer (Backend PHP)" >> "$REPORT_FILE"
echo '```text' >> "$REPORT_FILE"

if composer audit --locked --format=plain >> "$REPORT_FILE" 2>&1; then
    echo "✅ Composer Audit Lulus: Tidak ditemukan kerentanan kritis."
else
    echo "⚠️  Composer Audit menemukan advisories keamanan (tercatat di laporan)."
fi

echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 2. NPM Security Audit (JavaScript / Vite)
echo "🔍 2. Menjalankan NPM Security Audit..."
echo "### 📦 2. Hasil Audit NPM (Frontend / Build Tools)" >> "$REPORT_FILE"
echo '```text' >> "$REPORT_FILE"

if npm audit --audit-level=high >> "$REPORT_FILE" 2>&1; then
    echo "✅ NPM Audit Lulus: 0 Kerentanan level High / Critical."
else
    echo "⚠️  NPM Audit mendeteksi kerentanan yang memerlukan perhatian."
fi

echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "========================================================"
echo "✅ Security Audit Selesai! Laporan disimpan di: $REPORT_FILE"
echo "========================================================"
