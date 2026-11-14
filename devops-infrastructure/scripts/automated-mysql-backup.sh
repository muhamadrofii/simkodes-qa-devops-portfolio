#!/usr/bin/env bash
set -e

# ==============================================================================
# Script Pencadangan Database MySQL SIMKODES Otomatis
# Membaca kredensial dari .env aktif dan menghasilkan arsip dump terkompresi .sql.gz
# ==============================================================================

TARGET="${1:-production}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${2:-./backups}"

if [ "$TARGET" = "staging" ]; then
    APP_PATH="/home/u849825724/domains/sranak.com/public_html/simkodes-staging"
else
    APP_PATH="/home/u849825724/domains/sranak.com/public_html/simkodes"
fi

echo "=========================================================="
echo "📦 MEMULAI DATABASE BACKUP UNTUK LINGKUNGAN: $TARGET"
echo "=========================================================="

mkdir -p "$BACKUP_DIR"
cd "$APP_PATH"

# Ekstrak kredensial database dari .env
DB_DATABASE=$(grep "^DB_DATABASE=" .env | cut -d '=' -f2 | tr -d '\r"')
DB_USERNAME=$(grep "^DB_USERNAME=" .env | cut -d '=' -f2 | tr -d '\r"')
DB_PASSWORD=$(grep "^DB_PASSWORD=" .env | cut -d '=' -f2 | tr -d '\r"')
DB_HOST=$(grep "^DB_HOST=" .env | cut -d '=' -f2 | tr -d '\r"')

if [ -z "$DB_DATABASE" ]; then
    echo "❌ Error: Kredensial DB_DATABASE tidak ditemukan di .env!"
    exit 1
fi

BACKUP_FILE="${BACKUP_DIR}/simkodes_${TARGET}_backup_${TIMESTAMP}.sql.gz"

echo "⏳ Menjalankan mysqldump untuk database: $DB_DATABASE..."
mysqldump --single-transaction --quick -h "${DB_HOST:-127.0.0.1}" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" | gzip > "$BACKUP_FILE"

echo "✅ Backup Berhasil Dibuat!"
echo "📁 Lokasi: $BACKUP_FILE"
echo "📏 Ukuran File: $(du -h "$BACKUP_FILE" | cut -f1)"

# Retensi: Hapus file backup lokal yang lebih tua dari 30 hari
find "$BACKUP_DIR" -type f -name "simkodes_*.sql.gz" -mtime +30 -exec rm -f {} \;
echo "🧹 Rotasi berkas backup lama (> 30 hari) selesai dibersihkan."
