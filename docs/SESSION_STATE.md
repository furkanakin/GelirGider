# Oturum durumu — son güncelleme 2026-04-27

> **Yeni oturuma başladığında:** "docs/SESSION_STATE.md'yi oku, kaldığım yerden devam edelim" de.
> Memory sistemi (`~/.claude/projects/E--GelirGider/memory/`) profil, feedback, deploy detaylarını
> ayrıca tutar — otomatik yüklenir.

## Şu anda neredeyiz

**CANLI VE ÇALIŞIYOR.** Backend, web ve APK üretimde.

| Servis | URL / Yol | Notlar |
|---|---|---|
| Backend API | https://ggapi.kayai.space | FastAPI, Coolify deploy, port 8000 |
| Backend docs | https://ggapi.kayai.space/docs | Swagger UI |
| Web / PWA | https://ggapp.kayai.space | Flutter web nginx, service worker kapalı |
| APK | `app/build/app/outputs/flutter-apk/app-release.apk` | 56.6 MB, imzalı, son build 2026-04-27 12:00 |

**DB:** Postgres 17 (Coolify yönetimli), schema `evimiz`, 13 tablo, 001_init + 002_phase2 uygulanmış.
**LLM:** llmgateway.io (OpenAI uyumlu) — text/JSON için varsayılan `qwen3-coder-next`,
vision için `qwen2.5-vl-72b-instruct`, STT için `whisper-1`. Hepsinin fallback zinciri var.

**Kullanıcılar:**
- `furkanakin1903@gmail.com` — Furkan'ın hesabı, kendi "Evimiz" hanesinin sahibi (owner)
- `semadgn1103@gmail.com` — silindi (admin endpoint ile, eşi yeniden kayıt olacak)

## Kayıt akışı (yeni)

Backend `/api/auth/register` artık iki yoldan biriyle:
- `household_name` set → yeni hane oluşturur, kullanıcı owner olur
- `invite_code` set → davet edenin hanesine member olarak katılır, yeni hane oluşturmaz
- İkisi birden gönderilirse 400. Hiçbiri gönderilmezse user yaratılır ama hane'siz kalır
  (UI bu duruma izin vermiyor — formda ya "Yeni hane" ya "Davet kodu" sekmesi seçili).

App ve web giriş ekranı bu iki sekmeyi gösteriyor (terracotta segmented toggle).

## Coolify API tokenı ile yönettim

- **Panel:** https://panel.kayai.space
- **Sunucu IP:** 91.108.102.148 (Furkan'ın kendi VPS'i)
- **API token:** `1|MnQ1oDnJLaGFYidQgwFTotShHHBsrxIdqu04WUDZffc00a1b`
  → ⚠️ **Kullanıcı bunu revoke etmeli** (Profile → Keys & Tokens → sil). İşim bitince yapacağı söylendi.

**Application UUID'ler** (API çağrıları için):
- Backend: `g6bsn4npyrbsz6tchr7jps56`
- Web: `nebphe6nz71nvk491bkc4g3z`
- Postgres DB: `z7ysvcaoeh8kwwneblldmiq6`

**Internal DB hostname:** `z7ysvcaoeh8kwwneblldmiq6` (Coolify Postgres container)
**DB password:** `tLrsNRut37GTKxeIdvReaPQ5AXMQBnOo5zrUANedXQC0H4Fa1OaYABH8RwvUkkTY`
(eski, sızdı, kullanıcı şimdilik "deneysel zaten" deyip rotate etmedi).

**Deploy tetikleme:**
```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  "https://panel.kayai.space/api/v1/deploy?uuid=$APP_UUID&force=false"
```

Status izleme: `GET /api/v1/deployments/{deployment_uuid}` → `status` alanı.

## Yapılan büyük değişiklikler (kronolojik)

1. ✅ DNS: `*.kayai.space → 91.108.102.148` wildcard zaten kurulu, kayıt eklemeye gerek olmadı
2. ✅ Backend Coolify deploy (Dockerfile, /backend base dir, port 8000)
3. ✅ DB schema: `001_init.sql` + `002_phase2.sql` backend container'ından psql ile uygulandı
4. ✅ Web Coolify deploy (multi-stage Flutter SDK + nginx, Dockerfile.web)
5. ✅ Bug: Web nginx Dockerfile HEALTHCHECK BusyBox `wget --spider` Coolify network'ünde Connection refused — direktif kaldırıldı
6. ✅ Bug: Backend ports_exposes 3000→8000 düzeltildi (Coolify default 3000, backend 8000'de listen, 502 dönüyordu); Traefik labels API ile 8000'e zorlandı
7. ✅ Register flow: hane otomatik oluşturma kaldırıldı, invite_code desteği eklendi (backend + Flutter UI)
8. ✅ Voice akışı: `speech_to_text` çıkarıldı (Google Türkçe paket prompt'u yok), `record` paketi ile bayt kaydı + backend `/api/ai/voice/transcribe` (Whisper-1)
9. ✅ Photo akışı: `google_mlkit_text_recognition` çıkarıldı, `/api/ai/photo/extract` doğrudan Qwen vision'a gönderiyor
10. ✅ Settings model dropdown 17 modele genişletildi (Hızlı/Orta/Kaliteli grupları)
11. ✅ Transaction silme bug'ı: Dismissible'ın onDismissed yarış koşulu, API çağrısı confirmDismiss'e taşındı, hep `false` döner; provider invalidate ile satır rebuild'de düşer
12. ✅ Web PWA service worker kapatıldı (`--pwa-strategy=none`) — sürekli güncel sürüm
13. ✅ iOS Safari "Uygulamayı yükle" banner'ı eklendi (`app/web/index.html` JS+CSS)
14. ✅ Voice crash düzeltildi: `record.start(path: '')` mobilde fail ediyordu, `path_provider` ile `getTemporaryDirectory()`
15. ✅ Admin DELETE endpoint eklendi: `DELETE /api/admin/users/by-email/{email}`, JWT_SECRET bearer guard
16. ✅ `semadgn1103@gmail.com` kullanıcısı admin endpoint ile silindi

## Bekleyen / sonraya bırakılan

- **Eşi yeniden kayıt olacak:** `semadgn1103@gmail.com` ile. Kayıt formunda "Davet kodu" sekmesinde Furkan'ın gönderdiği kodu yapıştırarak Furkan'ın hanesine direkt katılır. (Bu eşin yapacağı bir aksiyon — Furkan ona kodu iletecek.)
- **Coolify API tokenı:** Furkan revoke etmeli (Profile → Keys & Tokens → `claude-deploy` sil)
- **DB password rotate:** Eski parola sızdı; "deneysel zaten" denildiği için ertelendi, prod'a açılırken rotate edilmeli
- **Postgres public 5858 portu:** Zaten kapalı (`is_public: False` doğrulandı)
- **iOS in-app camera:** Web'de `camera` paketi yok, iOS PWA'da Photo screen galeriye düşer
- **Audio dosyası backend storage:** `/api/ai/voice/transcribe` ses dosyasını işler ama saklamıyor; istersen `/api/attachments` ile genişletilebilir

## Kritik dosyalar / endpointler

| Yol | Amaç |
|---|---|
| `backend/app/routers/auth.py` | register: invite_code OR household_name |
| `backend/app/routers/ai.py` | classify-text, voice/transcribe (multipart), photo/extract (multipart), legacy text endpoints |
| `backend/app/routers/admin.py` | DELETE /admin/users/by-email/{email} (JWT_SECRET bearer) |
| `backend/app/llm.py` | LLMClient: chat_json, chat_json_with_image, transcribe_audio (her biri fallback'lı) |
| `backend/app/config.py` | LLM model listeleri (default + fallback'lar) |
| `app/lib/features/auth/login_screen.dart` | İki sekmeli register: Yeni hane / Davet kodu |
| `app/lib/features/voice/voice_screen.dart` | record paketi + path_provider + bytes_loader (web/io split) |
| `app/lib/features/voice/bytes_loader{,_io,_web}.dart` | Conditional import: dosya bayt okuma platformu |
| `app/lib/features/photo/photo_screen.dart` | image bytes → /ai/photo/extract (OCR yok) |
| `app/lib/features/list/list_screen.dart` | Dismissible: API confirmDismiss'te, hep false döner |
| `app/lib/services/api_client.dart` | transcribeAudio + extractPhoto multipart, register inviteCode argümanı |
| `app/lib/core/config.dart` | 17 LLM model listesi + grup eşlemesi |
| `app/web/index.html` | iOS PWA install banner JS+CSS |
| `app/Dockerfile.web` | --pwa-strategy=none (SW kapalı) |
| `app/pubspec.yaml` | record + path_provider, dependency_overrides record_linux |

## Admin user-delete kullanımı

```bash
curl -X DELETE \
  -H "Authorization: Bearer <JWT_SECRET değeri>" \
  https://ggapi.kayai.space/api/admin/users/by-email/<email>
```

JWT_SECRET şu an: `eefe162a25792a3f6e1f5d6ee3a37a4eb439d1ad1b5051486a30388c6d545cb40e82ee5e459a705b1ea72efdf44309812e3166bb816f753f6be5cf75d6e91218`
(Coolify backend env'inde, rotate edilirse buradaki referansı da güncelle.)

Cascade davranışı: kullanıcının yarattığı hane(ler)i siler, içindekileri (kategori, hesap, transaction, ai_jobs, notifications, quick_entries, recurring, attachments, invites) FK CASCADE temizler. Davet ettiği invite'lar silinir, kabul ettiği invite'larda accepted_by null'a çekilir.

## Deploy yeniden tetikleme

Backend:
```bash
curl -X POST -H "Authorization: Bearer 1|MnQ1oDnJLaGFYidQgwFTotShHHBsrxIdqu04WUDZffc00a1b" \
  "https://panel.kayai.space/api/v1/deploy?uuid=g6bsn4npyrbsz6tchr7jps56&force=false"
```

Web:
```bash
curl -X POST -H "Authorization: Bearer 1|MnQ1oDnJLaGFYidQgwFTotShHHBsrxIdqu04WUDZffc00a1b" \
  "https://panel.kayai.space/api/v1/deploy?uuid=nebphe6nz71nvk491bkc4g3z&force=false"
```

APK rebuild (Windows PowerShell):
```powershell
cd E:\GelirGider\app
& "C:\Users\Furkan\flutter-git\bin\flutter.bat" pub get
& "C:\Users\Furkan\flutter-git\bin\flutter.bat" build apk --release `
  --dart-define=API_BASE_URL=https://ggapi.kayai.space/api
```

## Bilinen hassasiyetler

- **Push hangs**: Git Credential Manager Windows'ta zaman zaman GUI prompt'unda takılıyor. Çözüm: kullanıcıdan terminal'de manuel `git push origin main` istemek.
- **Web service worker**: kapalı tutuldu. Tekrar açılırsa cache invalidate sorunu döner.
- **`record` paketi**: `record_linux` 0.7.2 transitive dep'i `record_platform_interface` 1.5.0 ile uyumsuz; `pubspec.yaml`'da `dependency_overrides: record_linux: ^1.3.0` zorunlu.
- **Flutter `--pwa-strategy=none` deprecation uyarısı veriyor** ama hâlâ çalışıyor (gelecek Flutter sürümünde kalkacak — sürüm yükselince başka çare gerek).
- **APK keystore:** `app/android/app/upload-keystore.jks` (gitignore'lu) — kullanıcı yedeklemeli, kaybolursa app id ile bir daha imzalanamaz.
