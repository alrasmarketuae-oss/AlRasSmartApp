# Contabo VPS — نشر باك اند الراس

موصى به: **Cloud VPS 20+** (أو على الأقل 8GB RAM) بسبب خدمة CLIP.

## 1) أول دخول على السيرفر

```bash
ssh root@YOUR_VPS_IP
apt update && apt upgrade -y
apt install -y curl git ufw
```

## 2) تثبيت Docker

```bash
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
docker --version
docker compose version
```

## 3) فتح المنافذ

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
ufw status
```

## 4) رفع المشروع

من جهازك (PowerShell) — استبدل الـ IP:

```powershell
scp -r "d:\nasser mostafa\Ras Al souq\AlRasMarketBackend" root@YOUR_VPS_IP:/opt/alras-backend
```

أو على السيرفر بـ git لو الريبو على GitHub.

## 5) إعداد البيئة

```bash
cd /opt/alras-backend
cp deploy/.env.example .env
nano .env   # حط Connection string الحقيقي
```

تأكد إن `appsettings.Production.json` فيه باقي الإعدادات (JWT, Stripe, R2, Firebase...).  
الـ `.env` بياخد الأولوية على Connection String.

## 6) تشغيل الستاك

```bash
cd /opt/alras-backend
mkdir -p deploy/certbot/conf deploy/certbot/www
docker compose up -d --build
docker compose ps
docker compose logs -f api
```

أول مرة CLIP هينزّل الموديل (~600MB) — استنى لحد:

```bash
docker compose logs -f clip
# لازم تشوف health جاهز
curl http://127.0.0.1:8088/health   # من جوه لو عملت port publish؛ أو:
docker compose exec clip curl -s http://127.0.0.1:8088/health
```

## 7) DNS

في Cloudflare / لوحة الدومين:

| Type | Name | Value        |
|------|------|--------------|
| A    | api  | YOUR_VPS_IP  |

Proxied = DNS only (رمادي) أثناء إصدار الشهادة، أو استخدم Cloudflare SSL Full لاحقاً.

جرب:

```bash
curl -I http://api.alrasmarketapp.com/swagger/index.html
```

## 8) شهادة SSL (Let's Encrypt)

```bash
docker run --rm -it \
  -v /opt/alras-backend/deploy/certbot/conf:/etc/letsencrypt \
  -v /opt/alras-backend/deploy/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot \
  -w /var/www/certbot \
  -d api.alrasmarketapp.com \
  --email YOUR_EMAIL@example.com \
  --agree-tos --no-eff-email
```

بعد ما الشهادة تتعمل:
1. عدّل `deploy/nginx/alras.conf` — فعّل بلوك الـ 443 (شيل التعليقات)
2. `docker compose restart nginx`

## 9) بعد النقل — Reindex CLIP

من Swagger أو:

```bash
curl -X POST https://api.alrasmarketapp.com/api/admin/products/reindex-image-vectors \
  -H "Authorization: Bearer YOUR_ADMIN_JWT"
```

## أوامر مفيدة

```bash
docker compose ps
docker compose logs -f api
docker compose restart api
docker compose down
docker compose up -d --build   # بعد أي تحديث كود
```

## تحديث لاحق للكود (من جهازك — Windows)

أسهل طريقة — سكربت جاهز:

```powershell
cd "d:\nasser mostafa\Ras Al souq\AlRasMarketBackend"

# تحديث الـ API فقط (الأغلب)
.\deploy\deploy-to-vps.ps1

# لو عدّلت CLIP service
.\deploy\deploy-to-vps.ps1 -Services "api,clip"

# إعادة بناء كل الخدمات
.\deploy\deploy-to-vps.ps1 -Services ""
```

السكربت بيعمل: ضغط → رفع → `docker compose up -d --build` على السيرفر.

### يدوياً (بدون سكربت)

```powershell
# من مجلد AlRasMarketBackend
scp -i $env:USERPROFILE\.ssh\id_ed25519 -r `
  BusinessLayer,DataLayer,RasAlSouqPresentaionLayer,clip-service,docker-compose.yml `
  alrasmarket@169.58.68.26:/opt/alrasmarket/app/
```

على السيرفر:

```bash
ssh alrasmarket@169.58.68.26
cd /opt/alrasmarket/app
docker compose up -d --build api      # API فقط
# أو:
docker compose up -d --build          # الكل
docker compose logs -f api
```

### ملاحظات
- تغييرات C# في الـ API → `-Services api`
- تغييرات `clip-service/` → `-Services "api,clip"`
- تغييرات `deploy/nginx/` → `-Services nginx` (أو انسخ الملف و `docker compose restart nginx`)
- Redis/Qdrant نادراً يحتاجوا rebuild (images جاهزة)
- كاش الإشعارات / إعلاناتي / geo mirror + `/metrics` → `-Services api`
- أول مرة لمراقبة Grafana/Prometheus:
  ```powershell
  .\deploy\deploy-to-vps.ps1 -Services "api,prometheus,grafana,redis-exporter"
  ```
  (أو full compose بدون `-Services`)

## مراقبة (Prometheus + Grafana)

المنافذ مربوطة على `127.0.0.1` فقط على الـ VPS (مش عامة). الوصول عبر SSH tunnel:

```powershell
ssh -i $env:USERPROFILE\.ssh\id_ed25519 -L 3000:127.0.0.1:3000 -L 9090:127.0.0.1:9090 alrasmarket@169.58.68.26
```

ثم:
- Grafana: `http://127.0.0.1:3000` — user `admin` / كلمة المرور من `GRAFANA_ADMIN_PASSWORD` في `.env`
- Prometheus: `http://127.0.0.1:9090`
- API metrics (من داخل الشبكة): `http://api:8080/metrics` — nginx لا ينشرها للعامة

Dashboard جاهز: **AlRas API + Redis** (طلبات HTTP، 5xx، مدة الاستجابة، Redis up).

### فحص سريع للكاش / المراقبة على السيرفر

```bash
cd /opt/alrasmarket/app
docker compose ps prometheus grafana redis-exporter api redis
docker compose exec api wget -qO- http://127.0.0.1:8080/metrics | head
docker compose exec redis redis-cli KEYS 'alras:geo:*'
docker compose exec redis redis-cli KEYS 'alras:notifications:*' | head
```

## تحديث لاحق للكود (قديم — scp خام)

- قاعدة البيانات حالياً على Site4Now — الـ VPS بيتصل بيها من الإنترنت (افتح firewall عند SQL لو لزم).
- Redis + Qdrant + CLIP على نفس الـ VPS (شبكة Docker داخلية فقط).
- لو الـ RAM قليلة وCLIP بطيء: زوّد الخطة أو عطّل CLIP مؤقتاً بـ `ImageEmbedding__Enabled=false`.
- إيقاف الفهرسة التلقائية أثناء إضافة الإعلانات (تجربة الداشبورد): `ImageEmbedding__AutoIndexOnCatalogChanges=false` في `docker-compose.yml` ثم `docker compose up -d api`. لإعادة التشغيل: `"true"`.
