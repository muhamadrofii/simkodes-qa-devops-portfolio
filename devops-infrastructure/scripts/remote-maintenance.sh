#!/usr/bin/env bash
set -e

# ==============================================================================
# Script Kontrol Mode Pemeliharaan (Maintenance Mode) Remote SIMKODES
# Mengaktifkan/menonaktifkan maintenance dengan bypass secret token & 503 retry header
# ==============================================================================

ACTION="${1:-status}"
TARGET="${2:-staging}"
SECRET="${3:-simkodes-secret-bypass}"
RETRY_AFTER="${4:-3600}"

if [ "$TARGET" = "staging" ]; then
    APP_PATH="/home/u849825724/domains/sranak.com/public_html/simkodes-staging"
    DOMAIN="simkodes-staging.sranak.com"
else
    APP_PATH="/home/u849825724/domains/sranak.com/public_html/simkodes"
    DOMAIN="simkodes.sranak.com"
fi

case "$ACTION" in
    down)
        echo "🚨 Mengaktifkan Maintenance Mode untuk $TARGET..."
        cd "$APP_PATH"
        php artisan down --secret="$SECRET" --retry="$RETRY_AFTER" --status=503 --render="errors::503" || php artisan down --secret="$SECRET"
        echo "✅ Mode Pemeliharaan AKTIF."
        echo "🔑 URL Akses Khusus Tim: https://$DOMAIN/?secret=$SECRET"
        ;;
    up)
        echo "🟢 Menonaktifkan Maintenance Mode untuk $TARGET..."
        cd "$APP_PATH"
        php artisan up
        echo "✅ Sistem SIMKODES $TARGET kembali ONLINE."
        ;;
    status)
        echo "ℹ️  Memeriksa status aplikasi di $APP_PATH..."
        cd "$APP_PATH"
        if [ -f storage/framework/down ]; then
            echo "🔴 Status: Sistem sedang dalam mode MAINTENANCE."
        else
            echo "🟢 Status: Sistem ONLINE normal."
        fi
        ;;
    *)
        echo "Penggunaan: $0 {down|up|status} [staging|production] [secret_token] [retry_seconds]"
        exit 1
        ;;
esac
