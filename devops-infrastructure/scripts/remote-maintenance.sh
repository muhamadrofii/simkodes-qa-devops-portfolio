#!/usr/bin/env bash
set -e

# ==============================================================================
# Remote Maintenance Mode Controller for SIMKODES
# Toggles artisan down / up with secret bypass token and Retry-After header
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
        echo "Enabling maintenance mode on $TARGET..."
        cd "$APP_PATH"
        php artisan down --secret="$SECRET" --retry="$RETRY_AFTER" --status=503 --render="errors::503" || php artisan down --secret="$SECRET"
        echo "Maintenance mode enabled."
        echo "Bypass URL: https://$DOMAIN/?secret=$SECRET"
        ;;
    up)
        echo "Disabling maintenance mode on $TARGET..."
        cd "$APP_PATH"
        php artisan up
        echo "Application is now online."
        ;;
    status)
        echo "Checking application status in $APP_PATH..."
        cd "$APP_PATH"
        if [ -f storage/framework/down ]; then
            echo "Status: MAINTENANCE"
        else
            echo "Status: ONLINE"
        fi
        ;;
    *)
        echo "Usage: $0 {down|up|status} [staging|production] [secret_token] [retry_seconds]"
        exit 1
        ;;
esac
