#!/usr/bin/env bash
set -euo pipefail

DASH_DIR=/opt/alrasmarket/dash
APP_DIR=/opt/alrasmarket/app
CONF="$APP_DIR/deploy/nginx/alras.conf"
COMPOSE="$APP_DIR/docker-compose.yml"
TAR=/tmp/alras-dash-dist.tar.gz

chmod -R u+w "$DASH_DIR" 2>/dev/null || true
rm -rf "${DASH_DIR:?}/"*
tar -xzf "$TAR" -C "$DASH_DIR"
chmod -R u+rwX "$DASH_DIR"
rm -f "$TAR"

if ! grep -Fq 'server_name dash.alrasmarketapp.com' "$CONF"; then
  cat >> "$CONF" <<'EOF'

server {
    listen 443 ssl;
    http2 on;
    server_name dash.alrasmarketapp.com;

    ssl_certificate     /etc/nginx/ssl/origin.crt;
    ssl_certificate_key /etc/nginx/ssl/origin.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    root /usr/share/nginx/dash;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2?)$ {
        expires 7d;
        add_header Cache-Control "public";
        try_files $uri =404;
    }
}
EOF
  echo "nginx conf appended"
else
  echo "nginx conf already has dash"
fi

if ! grep -Fq '/opt/alrasmarket/dash:/usr/share/nginx/dash' "$COMPOSE"; then
  python3 - <<'PY'
from pathlib import Path
p = Path("/opt/alrasmarket/app/docker-compose.yml")
text = p.read_text()
needle = "      - ./deploy/nginx/alras.conf:/etc/nginx/conf.d/default.conf:ro"
mount = "      - /opt/alrasmarket/dash:/usr/share/nginx/dash:ro"
if mount in text:
    print("compose already mounts dash")
elif needle in text:
    p.write_text(text.replace(needle, needle + "\n" + mount, 1))
    print("compose patched")
else:
    raise SystemExit("compose needle not found")
PY
else
  echo "compose already mounts dash"
fi

cd "$APP_DIR"
docker compose up -d nginx --force-recreate
sleep 3
docker exec alras-nginx nginx -t
docker exec alras-nginx ls -la /usr/share/nginx/dash/icons/merge-tab-icon.png
echo "--- icon ---"
curl -sk -H "Host: dash.alrasmarketapp.com" https://127.0.0.1/icons/merge-tab-icon.png -o /tmp/micon.png -w "code=%{http_code} size=%{size_download}\n"
echo "--- html snippet ---"
curl -sk -H "Host: dash.alrasmarketapp.com" https://127.0.0.1/ | tr -d '\r' | head -n 12
