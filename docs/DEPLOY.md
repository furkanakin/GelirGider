# Deploy

Sunucu: `91.108.102.148` (Coolify host). Postgres halihazırda 5858'de çalışıyor.

## Backend (Coolify üzerinden)

1. Coolify panelinden **New Resource → Application → Public Git Repository** seçin (veya bu repo'yu git'e pushlayıp bağlayın). Compose / Dockerfile build kullanın.
2. Build context: `backend/`, Dockerfile: `Dockerfile`.
3. Environment variables:

   | Anahtar | Değer |
   |---|---|
   | `DATABASE_URL` | `postgresql+asyncpg://postgres:****@<postgres-service>:5432/postgres` (Coolify internal hostname) |
   | `DATABASE_SCHEMA` | `evimiz` |
   | `JWT_SECRET` | `openssl rand -hex 64` ile üretilmiş güçlü bir değer |
   | `LLM_GATEWAY_API_KEY` | llmgateway.io API key |
   | `LLM_DEFAULT_MODEL` | `qwen3-coder-next` |
   | `ALLOWED_ORIGINS` | `https://app.evimiz.app,https://evimiz.app` |
   | `ENVIRONMENT` | `production` |

4. Domain: `api.evimiz.app` → bu app, port 8000 (Coolify HTTPS terminate eder).
5. Health check: `/health`.

> **Önemli:** Coolify'daki Postgres servisinin **container hostname**'ini kullan, public IP+port (5858) yerine internal network ile bağlan. Bu hem güvenli hem hızlı. Public 5858 portunu firewall ile kapatmak iyi olur.

## Web app (Flutter Web / PWA)

```bash
cd app
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.evimiz.app/api \
  --pwa-strategy=offline-first
```

`build/web/` klasörünü statik bir nginx / Caddy konteynerine veya Coolify "Static Site" tipine deploy et.

Örnek `Caddyfile`:
```caddy
app.evimiz.app {
    root * /srv/web
    file_server
    encode zstd gzip
    try_files {path} /index.html
    header /index.html Cache-Control "no-cache"
    header /flutter_service_worker.js Cache-Control "no-cache"
    header /assets/* Cache-Control "public, max-age=31536000, immutable"
}
```

## Mobil store paketleri

### Android (.apk / .aab)
```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=https://api.evimiz.app/api
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.evimiz.app/api
```

İlk build için `android/app/build.gradle.kts` içinde keystore tanımı gerekir. Detaylar için Flutter'ın resmi rehberi.

### iOS (.ipa)
**Windows'ta üretilemez — macOS gerekir.** Codemagic veya GitHub Actions üzerinde Mac runner ile:
```yaml
# .github/workflows/ios.yml (örnek iskelet)
on: { push: { tags: ['v*'] } }
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter build ipa --release --dart-define=API_BASE_URL=https://api.evimiz.app/api
```

## DNS

| Subdomain | Tip | Hedef |
|---|---|---|
| `api.evimiz.app` | A | `91.108.102.148` |
| `app.evimiz.app` | A | `91.108.102.148` |

## İlk hesap oluşturma

İlk register endpoint'i hem kullanıcıyı hem hane'yi kurar ve default kategorileri ekler:

```bash
curl -X POST https://api.evimiz.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"sen@evimiz.app","password":"Sifrem123","display_name":"Adın","household_name":"Evimiz"}'
```

Sonrasında uygulamadan davet kodu üretip diğer aile üyelerini ekleyebilirsin.
