# Evimiz'i iPhone'a yükleme (iOS PWA)

iOS'ta "Ana Ekrana Ekle" özelliğiyle Evimiz tam ekran bir uygulama gibi çalışır.
App Store'a girmesi gerekmez.

## Tek seferlik kurulum

1. **Safari** ile `https://app.evimiz.tr` adresine git (Chrome veya başka tarayıcı **olmaz** — iOS sadece Safari'den PWA yükler).
2. Adres çubuğunun altında **Paylaş** ikonuna bas (kareden yukarı çıkan ok).
3. Listeden **"Ana Ekrana Ekle"**'yi seç.
4. İsmi "Evimiz" olarak bırak, sağ üstte **Ekle**'ye dokun.
5. Ana ekranda Evimiz simgesi belirir. Bundan sonra normal uygulama gibi açılır — tarayıcı çubuğu yoktur, tam ekran çalışır.

## Çalışan özellikler

- ✅ **Yazılı kayıt** — direkt çalışır
- ✅ **Sesli kayıt** — Safari mikrofon iznini ister, kabul et. iOS 17+ gerek
- ✅ **Foto** — galeri açılır, oradan fiş seçersin (iOS PWA'da canlı kamera sınırlı çalışır, galeri her zaman çalışır)
- ✅ **Tüm raporlar / aile / kategoriler** — Android ile aynı
- ✅ **Çevrimdışı:** son verilerin önbellekte kalır, internet gelince sync eder

## Notlar

- **HTTPS şart:** mikrofon ve kamera iOS'ta sadece HTTPS sitelerde çalışır. Backend'in `https://` ile servis edilmeli (Coolify Caddy ile otomatik).
- **Login:** ilk açılışta hesap kur veya giriş yap. Eşinin gönderdiği davet kodu varsa Settings → Aile'den katıl.
- **Güncelleme:** sayfayı yenilediğinde son sürümü çeker. Tarayıcı önbelleğini bazen temizlemek gerekebilir.

## Mikrofon izni vermediysen

Ayarlar uygulaması → Safari → Mikrofon → app.evimiz.tr → İzin Ver.
