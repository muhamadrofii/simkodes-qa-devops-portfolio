#!/usr/bin/env bash
set -e

# ==============================================================================
# Automated MySQL Backup Script
# Extracts credentials from .env, runs mysqldump, gzips output, and rotates files
# ==============================================================================

TARGET="${1:-production}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${2:-./backups}"

if [ "$TARGET" = "staging" ]; then
    APP_PATH="/home/u849825724/domains/sranak.com/public_html/simkodes-staging"
else
    APP_PATH="/home/u849825724/domains/sranak.com/public_html/simkodes"
fi

echo "Starting database backup for: $TARGET"

mkdir -p "$BACKUP_DIR"
cd "$APP_PATH"

# Extract database credentials from .env
DB_DATABASE=$(grep "^DB_DATABASE=" .env | cut -d '=' -f2 | tr -d '\r"')
DB_USERNAME=$(grep "^DB_USERNAME=" .env | cut -d '=' -f2 | tr -d '\r"')
DB_PASSWORD=$(grep "^DB_PASSWORD=" .env | cut -d '=' -f2 | tr -d '\r"')
DB_HOST=$(grep "^DB_HOST=" .env | cut -d '=' -f2 | tr -d '\r"')

if [ -z "$DB_DATABASE" ]; then
    echo "Error: DB_DATABASE was not found in .env"
    exit 1
fi

BACKUP_FILE="${BACKUP_DIR}/simkodes_${TARGET}_backup_${TIMESTAMP}.sql.gz"

echo "Running mysqldump for database: $DB_DATABASE..."
mysqldump --single-transaction --quick -h "${DB_HOST:-127.0.0.1}" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" | gzip > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

# Retention: Delete local backups older than 30 days
find "$BACKUP_DIR" -type f -name "simkodes_*.sql.gz" -mtime +30 -exec rm -f {} \;
echo "Cleaned backups older than 30 days."
