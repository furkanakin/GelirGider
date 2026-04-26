# Oturum durumu — son güncelleme 2026-04-26

> **Yeni oturuma başladığında:** "docs/SESSION_STATE.md'yi oku, kaldığım yerden devam edelim" de.
> Claude memory sistemi ek olarak `~/.claude/projects/E--GelirGider/memory/` altında profil/feedback/referans tutar (otomatik yüklenir).

## Şu anda neredeyiz

**Kod tarafı: BİTTİ.** Backend + Flutter app + Web/PWA hepsi yazıldı, test edildi, GitHub'da: https://github.com/furkanakin/GelirGider (public).

**Bekleyen tek iş: Coolify'a production deploy.** Henüz canlıda hiçbir servis yok, sadece dev container `evimiz-api-test` localhost:8001'de.

## Yapılan son işler (kronolojik)

1. ✅ Backend: 24 endpoint, AI entegrasyonu (llmgateway.io), DB schema 2 dosya
2. ✅ Flutter app: 11 ekran + ek ekranlar (settings/accounts/recurring/notifications/search/yearly/onboarding)
3. ✅ Hata düzeltmeleri:
   - Çıkış sorunu (eager refresh kaldırıldı)
   - Edit panel navbar altında kalmıyor (`useSafeArea` + bottom inset)
   - İşlemleri sola kaydırınca silinme (`Dismissible` + onay)
   - Foto akışı: in-app live camera (`camera` paketi, image_picker yerine)
4. ✅ Dark mode: kullanıcı kaldırılmasını istedi, sadece açık tema kullanılıyor
5. ✅ Runtime API URL override: Settings → Sunucu → API adresi (APK build etmeden domain değiştirilebilir)
6. ✅ Android imzalı APK (universal, ~86 MB), keystore `app/android/app/upload-keystore.jks` (gitignored, **yedeklenmeli**)
7. ✅ Multi-stage `app/Dockerfile.web` (Coolify Flutter build + nginx)
8. ✅ Git init, commit, GitHub push (public repo)

## Bekleyen adımlar — sırasıyla

### 1. DNS
- Domain seç (örn. `evimiz.tr`)
- A kayıtları:
  - `api.<domain>` → `91.108.102.148`
  - `app.<domain>` → `91.108.102.148`

### 2. Coolify backend deploy
- New App → Public Repo → `https://github.com/furkanakin/GelirGider.git`
- Base dir: `/backend`, Dockerfile: `Dockerfile`, port `8000`
- Env vars (README.md'de tablo var):
  - `DATABASE_URL` (Coolify Postgres internal hostname)
  - `JWT_SECRET` (`openssl rand -hex 64`)
  - `LLM_GATEWAY_API_KEY` (mevcut)
  - `ALLOWED_ORIGINS=https://app.<domain>`
- Domain: `https://api.<domain>`, health: `/health`
- ⚠️ DB password yenile (chatte sızdı), Postgres `5858` portunu firewall'da kapat

### 3. DB schema apply
```bash
psql -h <coolify_postgres_host> -p 5432 -U postgres -d postgres \
  -f backend/sql/001_init.sql -f backend/sql/002_phase2.sql
```

### 4. Coolify web/PWA deploy
- New App → aynı repo → base dir `/`, Dockerfile location: `app/Dockerfile.web`, port `80`
- Build arg: `API_BASE_URL=https://api.<domain>/api`
- Domain: `https://app.<domain>`

### 5. Test ve dağıtım
- **Furkan (Android):** APK Settings → Sunucu → API adresi → `https://api.<domain>/api`, yeniden giriş
- **Eşi (iOS):** Safari'de `https://app.<domain>` → Paylaş → Ana Ekrana Ekle (`docs/IOS_PWA.md`)
- Aile davet: Furkan Settings → Aile → Davet et → kod → eşine WhatsApp

## Bilinen pürüzler / sonraya bırakılanlar

- **Dark mode**: kaldırıldı ama kod `theme/theme_controller.dart` ve `_DarkPalette` hâlâ duruyor; kullanıcı isterse hızla yeniden açılabilir.
- **iOS in-app camera**: web'de `camera` paketi yok, Photo screen'de iOS PWA'da galeri'ye düşer (mobil web kamera erişimi sınırlı). Mobil Android'de live camera çalışır.
- **Audio dosyası backend'e gitmiyor:** Voice akışı sadece transcript metni gönderir (`/api/ai/transcribe-voice`), ses dosyası şu an upload edilmiyor — gerekirse `/api/attachments` ile genişletilebilir.
- **Foto vision LLM:** şu an OCR'dan çıkan metin LLM'e gidiyor (text-only). Qwen-VL gibi vision moda geçmek istenirse `backend/app/llm.py` ve photo akışı revize edilir.

## Kritik dosyalar

| Dosya | Amaç |
|---|---|
| `backend/Dockerfile` | Coolify backend |
| `backend/.env.example` | Env şablonu (gerçek `.env` gitignored) |
| `backend/sql/001_init.sql`, `002_phase2.sql` | DB schema |
| `app/Dockerfile.web` | Coolify Flutter build + nginx (PWA) |
| `app/android/app/upload-keystore.jks` | **YEDEKLE!** Kaybolursa app id çakışır |
| `app/android/key.properties` | Keystore şifreleri (gitignored) |
| `app/build/app/outputs/flutter-apk/app-release.apk` | Son imzalı APK |
| `README.md` | Genel bakış + deploy özeti |
| `docs/DEPLOY.md` | Detaylı Coolify deploy |
| `docs/IOS_PWA.md` | Eşin için "Ana ekrana ekle" rehberi |
