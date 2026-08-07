#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-/opt/alrasmarket/app}"
MONITOR_DIR="$APP_DIR/deploy/monitoring"
ENV_FILE="$MONITOR_DIR/ram-alert.env"
CRON_TAG="# alras-ram-alert"

if [[ ! -f "$MONITOR_DIR/ram-alert.py" ]]; then
  echo "Missing $MONITOR_DIR/ram-alert.py"
  exit 1
fi

chmod +x "$MONITOR_DIR/ram-alert.py"

if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$MONITOR_DIR/ram-alert.env.example" ]]; then
    cp "$MONITOR_DIR/ram-alert.env.example" "$ENV_FILE"
    echo "Created $ENV_FILE from example. Fill SENDER_PASSWORD before alerts can send."
  else
    echo "Missing $ENV_FILE"
    exit 1
  fi
fi

CRON_LINE="*/5 * * * * /usr/bin/python3 $MONITOR_DIR/ram-alert.py >> $APP_DIR/deploy/monitoring/ram-alert.log 2>&1 $CRON_TAG"
TMP_CRON="$(mktemp)"

crontab -l 2>/dev/null | grep -Fv "$CRON_TAG" > "$TMP_CRON" || true
echo "$CRON_LINE" >> "$TMP_CRON"
crontab "$TMP_CRON"
rm -f "$TMP_CRON"

touch "$APP_DIR/deploy/monitoring/ram-alert.log"
chmod 644 "$APP_DIR/deploy/monitoring/ram-alert.log"

echo "RAM alert cron installed (every 5 minutes)."
echo "Log: $APP_DIR/deploy/monitoring/ram-alert.log"
crontab -l | grep "$CRON_TAG" || true
