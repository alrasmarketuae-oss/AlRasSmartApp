#!/usr/bin/env bash
set -euo pipefail

CFG="/opt/alrasmarket/app/RasAlSouqPresentaionLayer/appsettings.Production.json"
ENV="/opt/alrasmarket/app/deploy/monitoring/ram-alert.env"

sender_email=$(grep -m1 '"SenderEmail"' "$CFG" | sed -E 's/.*"SenderEmail"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
sender_password=$(grep -m1 '"SenderPassword"' "$CFG" | sed -E 's/.*"SenderPassword"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
sender_name=$(grep -m1 '"SenderName"' "$CFG" | sed -E 's/.*"SenderName"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
smtp_server=$(grep -m1 '"SmtpServer"' "$CFG" | sed -E 's/.*"SmtpServer"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
smtp_port=$(grep -m1 '"SmtpPort"' "$CFG" | sed -E 's/.*"SmtpPort"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')

cat > "$ENV" <<ENVFILE
WARNING_THRESHOLD_PERCENT=80
WARNING_RESET_BELOW_PERCENT=78
WARNING_COOLDOWN_SECONDS=3600

CRITICAL_THRESHOLD_PERCENT=90
CRITICAL_SUSTAIN_SECONDS=300
CRITICAL_RESET_BELOW_PERCENT=85
CRITICAL_COOLDOWN_SECONDS=3600

SMTP_SERVER=${smtp_server}
SMTP_PORT=${smtp_port}
SENDER_EMAIL=${sender_email}
SENDER_PASSWORD=${sender_password}
SENDER_NAME=${sender_name}

ALERT_RECIPIENTS=nasermostafa.ma122@gmail.com,alrasmarketuae@gmail.com,merge.foodstuff.ae@gmail.com
ENVFILE

chmod 600 "$ENV"
echo "Configured ram-alert.env for sender: ${sender_email}"
