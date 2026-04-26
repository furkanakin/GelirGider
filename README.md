# Evimiz — Aile Gelir-Gider

Türkçe, AI destekli aile bütçe defteri. Flutter (Android + Web/PWA) + FastAPI + PostgreSQL.
Kişisel kullanım için tasarlandı. Eşin/ailen ile aynı haneyi paylaşır.

## Mimari

```
┌──────────────────────────────────────────────────────────────┐
│  Flutter App                                                  │
│  Android (APK)            iOS (PWA — Safari "Ana ekrana ekle")│
│  ─ Cihaz üstü STT (ücretsiz, offline) → metin                 │
│  ─ Cihaz üstü ML Kit OCR (ücretsiz, offline) → metin          │
│  ─ Settings → Sunucu → kendi backend URL'in                   │
└─────────────────────┬────────────────────────────────────────┘
                      │ HTTPS (Bearer JWT + X-Household-Id)
┌─────────────────────▼────────────────────────────────────────┐
│  FastAPI · Python 3.12 · Coolify                              │
│  ─ /api/auth   /api/household   /api/categories               │
│  ─ /api/transactions   /api/reports   /api/ai/*               │
│  ─ /api/accounts   /api/recurring   /api/notifications        │
└──────────────┬──────────────────────────────┬────────────────┘
               │                              │
       ┌───────▼─────────┐         ┌─────────▼──────────────┐
       │  PostgreSQL 17  │         │  llmgateway.io          │
       │  schema=evimiz  │         │  Qwen/GLM/Kimi/MiniMax  │
       └─────────────────┘         └─────────────────────────┘
```

## Klasörler

- `backend/` — FastAPI uygulaması, SQL şema (`sql/001_init.sql`, `sql/002_phase2.sql`), Dockerfile.
- `app/` — Flutter uygulaması (Android + Web).
- `design/` — JSX referans tasarımları.
- `docs/` — Deploy & iOS kurulum rehberi.

## Hızlı dağıtım

### 1. Coolify'a backend deploy

Coolify panelinde:

1. **New Resource → Application → Public Git Repository**.
2. Repository: `https://github.com/furkanakin/GelirGider.git`
3. Build Pack: **Dockerfile**, base directory: `backend`.
4. Port: `8000`.
5. Environment variables (Coolify "Environment Variables" sekmesinde):

| Anahtar | Değer |
|---|---|
| `DATABASE_URL` | `postgresql+asyncpg://postgres:****@<POSTGRES-INTERNAL-HOST>:5432/postgres` |
| `DATABASE_SCHEMA` | `evimiz` |
| `JWT_SECRET` | `openssl rand -hex 64` çıktısı |
| `LLM_GATEWAY_API_KEY` | llmgateway.io API key |
| `LLM_DEFAULT_MODEL` | `qwen3-coder-next` |
| `ALLOWED_ORIGINS` | `https://app.evimiz.tr,https://api.evimiz.tr` (kendi domain'in) |
| `ENVIRONMENT` | `production` |

> **Postgres bağlantısı:** Coolify'daki Postgres servisinin **container hostname**'ini kullan, `91.108.102.148:5858` public IP yerine. Public 5858 portunu firewall'da kapatmak güvenlik için iyi olur.

6. Domain: `api.evimiz.tr` (örn.) — Coolify Caddy ile otomatik HTTPS verir.
7. Health check path: `/health`.

İlk deploy sonrası DB şemasını uygula:
```bash
# Yerelden tek seferlik (veya Coolify "Execute" sekmesinden):
docker run --rm -v "$PWD/backend/sql:/sql" -e PGPASSWORD=... \
  postgres:16-alpine \
  psql -h <POSTGRES_HOST> -p <PORT> -U postgres -d postgres -f /sql/001_init.sql
docker run --rm -v "$PWD/backend/sql:/sql" -e PGPASSWORD=... \
  postgres:16-alpine \
  psql -h <POSTGRES_HOST> -p <PORT> -U postgres -d postgres -f /sql/002_phase2.sql
```

### 2. Web (PWA) deploy — eşin için iOS

```bash
cd app
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.evimiz.tr/api
```

`app/build/web/` klasörünü Coolify'da **Static Site** olarak deploy et:

1. Coolify → New Resource → Application → Public Git Repository.
2. Aynı repo, base directory: `app/build/web` *(ama Coolify `flutter build` koşturmaz)*.
3. Daha temiz: **build çıktısını manuel `app.evimiz.tr` Caddy/Nginx host'una yüklemek**. Veya CI ekleyelim — `docs/DEPLOY.md` içinde GitHub Actions örneği var.

iOS için: eşin Safari'de `https://app.evimiz.tr` aç → **Paylaş** ikonu → **Ana Ekrana Ekle**. Detay: `docs/IOS_PWA.md`.

### 3. Android APK — sen

İmzalı release APK build edilecek (keystore: `app/android/app/upload-keystore.jks`).

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.evimiz.tr/api
```

Çıktı: `app/build/app/outputs/flutter-apk/app-release.apk`. Telefona kopyala/yükle.

> **API_BASE_URL'yi runtime'da değiştirebilirsin:** Settings → Sunucu → API adresi. Yani APK'yı placeholder URL ile build edip uygulamada gerçek URL'yi girmek de mümkün.

> **Keystore yedekle:** `app/android/app/upload-keystore.jks` ve `app/android/key.properties` dosyaları **gitignored**. Bunları kaybedersen aynı app id ile bir daha imzalayamazsın. Bir bulut yedeği al.

## LLM modelleri

| Slug | Açıklama |
|---|---|
| `qwen3-coder-next` | Qwen 3 (varsayılan) |
| `glm-5.1` | Z.ai GLM 5.1 |
| `kimi-k2.6` | Moonshot Kimi |
| `minimax-m2.7` | MiniMax M2.7 |

Uygulama içinden Settings → Yapay zeka'dan değiştirilebilir.

## Geliştirici tarafı

```bash
# Backend yerel
cd backend
cp .env.example .env  # düzenle
docker build -t evimiz-api .
docker run -p 8001:8000 --env-file .env evimiz-api
# API: http://localhost:8001/docs

# Flutter web (Chrome)
cd app
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001/api

# Flutter Android (USB takılı, ADB reverse ile localhost'a forward)
adb reverse tcp:8001 tcp:8001
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:8001/api
```
