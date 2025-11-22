#!/bin/bash
set -euo pipefail

: "${MOODLE_WWW_DIR:=/var/www/html}"
: "${MOODLE_SRC_DIR:=/usr/src/moodle}"
: "${MOODLE_DATA:=/var/www/moodledata}"

: "${MOODLE_DB_HOST:=db}"
: "${MOODLE_DB_PORT:=3306}"
: "${MOODLE_DB_TYPE:=mysqli}"
: "${MOODLE_DB_NAME:=moodle}"
: "${MOODLE_DB_USER:=moodle}"
: "${MOODLE_DB_PASSWORD:=password}"

: "${MOODLE_ADMIN_USER:=admin}"
: "${MOODLE_ADMIN_PASSWORD:=adminpass}"
: "${MOODLE_ADMIN_EMAIL:=admin@example.com}"
: "${MOODLE_LANG:=en}"
: "${MOODLE_SITE_FULLNAME:=Moodle Site}"
: "${MOODLE_SITE_NAME:=moodle}"

log() { echo "[entrypoint] $*"; }

# Copy Moodle source if www empty
if [ -d "$MOODLE_SRC_DIR" ] && [ -z "$(ls -A "$MOODLE_WWW_DIR" 2>/dev/null || true)" ]; then
    log "Copying Moodle to ${MOODLE_WWW_DIR}"
    tar -C "$MOODLE_SRC_DIR" -cf - . | tar -C "$MOODLE_WWW_DIR" -xf -
    chown -R www-data:www-data "$MOODLE_WWW_DIR"
fi

# Wait for DB
log "Waiting for database..."
for i in $(seq 1 30); do
    if nc -z "$MOODLE_DB_HOST" "$MOODLE_DB_PORT"; then
        log "Database is available."
        break
    fi
    sleep 2
done

# Create moodledata
if [ ! -d "$MOODLE_DATA" ]; then
    mkdir -p "$MOODLE_DATA"
fi
chown -R www-data:www-data "$MOODLE_DATA"

# Install Moodle if no config.php
if [ ! -f "${MOODLE_WWW_DIR}/config.php" ]; then
    log "Running Moodle installer..."
    runuser -u www-data -- php "${MOODLE_WWW_DIR}/admin/cli/install.php" \
        --non-interactive \
        --agree-license \
        --lang="$MOODLE_LANG" \
        --fullname="$MOODLE_SITE_FULLNAME" \
        --shortname="$MOODLE_SITE_NAME" \
        --wwwroot="http://localhost" \
        --dataroot="$MOODLE_DATA" \
        --dbtype="$MOODLE_DB_TYPE" \
        --dbhost="$MOODLE_DB_HOST" \
        --dbname="$MOODLE_DB_NAME" \
        --dbuser="$MOODLE_DB_USER" \
        --dbpass="$MOODLE_DB_PASSWORD" \
        --adminuser="$MOODLE_ADMIN_USER" \
        --adminpass="$MOODLE_ADMIN_PASSWORD" \
        --adminemail="$MOODLE_ADMIN_EMAIL"
    
#    chown -R www-data:www-data "$MOODLE_WWW_DIR"
else
    log "config.php exists → skipping installation."
fi

exec "$@"
