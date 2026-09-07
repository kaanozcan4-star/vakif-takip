# CLAUDE.md — Semerkand Kurtköy Vakfı Takip Sistemi

> Bu dosya projenin hafızasıdır. Yeni bir sohbet açtığında bunu yapıştır,
> nerede kaldığımız anlaşılsın.

---

## Proje Nedir

Semerkand Kurtköy Vakfı için online takip sistemi. Vakfın borçları, alacakları,
simit siparişleri, kurban ödemeleri, kermes gelirleri gibi tüm kayıtları tek
yerden tutulacak. ~50 kullanıcı, her biri farklı yetkide.

**Ana kısıt:** Maliyet sıfıra yakın olmalı. Kurucu (Erol Kaan) evini satıp
şirket kuruyor, para harcayacak durumda değil. Ayrıca teknik bilgisi sınırlı
ve vakti yok — "kur ve unut" olmalı, sürekli bakım isteyen bir yapı olmamalı.

---

## Teknik Yapı

| Katman | Ne kullanılıyor | Maliyet |
|---|---|---|
| Veritabanı + giriş sistemi | Supabase (ücretsiz katman) | ₺0 |
| Arayüz | Tek dosya HTML + JavaScript | ₺0 |
| Yayın | GitHub Pages — https://kaanozcan4-star.github.io/vakif-takip/ (main dalı, push ile otomatik) | ₺0 |
| Alan adı | Henüz alınmadı (opsiyonel) | ~₺500/yıl |

**Neden Next.js değil:** Başta Next.js planlandı ama GitHub hesabı, Node kurulumu
ve build ayarı gerektiriyor. Kullanıcının vakti ve teknik bilgisi buna uygun değil.
Tek HTML dosyası aynı işi yapıyor, sürükle-bırak yayınlanıyor. Veritabanı aynı
kaldığı için ileride Next.js'e geçmek mümkün.

**Supabase proje bilgileri:**
- Proje: `kaanozcan4-star's Project` (organizasyon: Semerkand kurtköy)
- Bölge: `ap-northeast-1` (Tokyo) — İstanbul'a uzak, ~250ms gecikme.
  Frankfurt daha iyi olurdu, sonradan fark edildi. Veri girilmeden önce
  taşınabilir, sonrasında zahmetli.
- Bağlantı bilgileri `index.html` dosyasının içinde gömülü.

---

## Rol ve Yetki Modeli

İki eksen var: **Kol** (erkek / kadın) ve **Görev**.

| Rol | Erişimi |
|---|---|
| Başkan (Erkek) | Her şey — erkek + kadın tüm modüller, tam yetki |
| Müdür (Erkek) | Her şey — erkek + kadın tüm modüller, tam yetki (**Erol Kaan burada**) |
| Başkan / Müdür (Kadın) | Kadın kolunun tamamı. Erkek kolunu göremez |
| Ticaret / Sosyal / Dergi | Varsayılan: sadece kendi sorumlu olduğu modül. Başkan veya Müdür ek modül açabilir |
| Vekil | **Sadece okur.** Yazma tiki konsa bile veritabanı yazmaya izin vermez |

**Kadın kolu ayrımı:** Kadın kolunun kendi borç/alacak defteri var. Kadın
kullanıcı giriş yaptığında sorgular otomatik "kadın" etiketiyle filtrelenir,
erkek kayıtları hiç gelmez. Erkek Başkan ve Müdür ikisini de görür.

**Yetki nerede uygulanıyor:** Veritabanının kendi içinde (PostgreSQL RLS).
Yani biri arayüzü atlatıp doğrudan veriye ulaşmaya çalışsa bile yetkisi
olmayan satır ona hiç gelmez. Arayüze güvenilmiyor.

---

## Veritabanı Tabloları

| Tablo | İçeriği |
|---|---|
| `kullanicilar` | Kişiler, kol + görev bilgisi |
| `moduller` | Modül tanımları. Yeni modül = yeni satır, kod değişmiyor |
| `modul_alanlari` | Her modülün form alanları (Tarih, Tutar, Açıklama…) |
| `kayitlar` | Tüm modüllerin verisi. Alanlar JSONB olarak tutuluyor |
| `modul_izinleri` | Kim hangi modülü görür / yazar / siler |
| `talepler` | Yetkisi olmayan kişi talep açar, yetkili onaylar |
| `gunluk` | Kim ne zaman ne değiştirdi — otomatik kaydediliyor |

**Modüler yapının mantığı:** Modül eklemek için kod yazmak gerekmiyor.
Yönetim panelinden modül adı, hangi kol, sorumlu görev ve alanlar tanımlanıyor;
sistem gerisini hallediyor.

---

## Başlangıç Modülleri

Ortak: Borçlar/Alacaklar, Kurban Ödemeleri, Kermes Gelirleri, Dergi Abonelik,
Bağışlar, Üyeler
Erkek kolu: Simit Siparişleri, Simit Ödemeleri
Kadın kolu: Borçlar/Alacaklar, Kermes Gelirleri, Sosyal Faaliyetler

---

## Kira Takip Paneli (7 Eylül 2026)

`kira` kodlu modül `index.html` içinde özel panelle açılır (`kiraAc`). Veri yine
`kayitlar` tablosunda: `veri.tip='yer'` dergah, `veri.tip='odeme'` ödeme.
Dergahlar: Erkek Merkez (Kurtköy Merkez), Kadın Merkez, Aydos Kadın, Çınardere Kadın, Velibaba Kadın.
Vade her ayın 5'i; kartlardaki çubuk vadeye yaklaştıkça dolar (turkuaz → sarı %75 →
kırmızı gecikince → yeşil ödenince). Ödeme kaydında "kim ödedi" ve "kim kaydetti" ayrı tutulur.
Kira tutarları girildi (toplam 143.800 ₺/ay); kartta "Düzenle" ile değişir.
Yeni özel panel eklemek için: `modulSec()` içine kod eşlemesi + kendi `xAc()` fonksiyonu.

## Borç / Alacak Defteri (8 Eylül 2026)

`borclar` ve `k_borclar` modülleri özel panelle açılır (`borcAc`). `modul_alanlari` kullanılmaz.
`veri.tip='borc'`: yon (borc|alacak), karsi_taraf, tarih, kalem (tl|altin|usd|eur|cek|senet|esya),
altin_cinsi (Çeyrek, Yarım, Tam, Ata, Cumhuriyet, Reşat, Gremse, Gram 24/22, Bilezik), miktar, kur,
tutar_tl, vade_tarihi, alan_kisi, belge, aciklama, not_metni.
`veri.tip='odeme'`: borc_id, tarih, odeyen (kim ödedi), yontem (nakit|havale|altin|doviz|mahsup|diger),
altin_cinsi, miktar, kur, tutar_tl, teslim_alan, aciklama.
Durum hesaplanır (ödemelerden): Açık / Kısmi Ödendi / Kapandı / Vadesi geçti. Altın borçlarda kalan adet de gösterilir.
Eski Excel'den gelen 4 Ümit Çelik çeki yeni yapıya taşındı; notlardaki ödemeler ayrı ödeme kaydı oldu.
Kaynağı bilinmeyen ödemelerde odeyen = "Bilinmiyor (düzeltilecek)".
**Anlık kur:** `kurCek()` → https://finans.truncgil.com/v4/today.json (ücretsiz, anahtarsız, CORS açık; 10 dk önbellek), yedek open.er-api.com (sadece USD/EUR). Satış fiyatı kullanılır. Form açılınca kur alanı boşsa otomatik dolar, "Kullan" ile güncellenir; listede açık altın/döviz kalanların bugünkü değeri gösterilir.

## Görsel Kimlik

- Marka rengi: **#4BBFC2** (Semerkand logosundan piksel olarak ölçüldü)
- Koyu ton (kenar çubuğu): #0B4F55
- Buton tonu: #0F6E77
- Logo `index.html` içine base64 olarak gömülü — ayrı resim dosyası yok

---

## Dosyalar

| Dosya | Görevi |
|---|---|
| `index.html` | **Sitenin tamamı.** Yayınlanan tek dosya |
| `server.js` | Yerel geliştirme sunucusu (node server.js ile çalışır) |
| `01_vakif_semasi.sql` | Veritabanı kurulumu (bir kez çalıştırılır) |
| `02_ilk_kurulum.sql` | İlk kullanıcının kendini Müdür yapması (bir kez) |
| `03_excel_verileri.sql` | Excel verilerini veritabanına aktarma sorgusu (bir kez) |
| `04_kira_modulu.sql` | Kira Takip modülü: 4 dergah + son 12 ayın ödemeleri (bir kez) |
| `CLAUDE.md` | Bu dosya |
| `DEVLOG.md` | Ne yapıldı, ne kaldı |

---

## Çalışma Tercihleri

- Türkçe, doğrudan ve net dil. Övgü ve yağcılık yok.
- Olmayacak şeye "olmaz" denir, gerekçesi söylenir, alternatifi sunulur.
- Ürün/fiyat araştırmasında tahmin yok — resmi kaynak, güncel fiyat, güncel kur.
- Kullanıcı teknik değil. Adımlar tek tek, tıklama seviyesinde anlatılmalı.
- Kısa cevaplar tercih ediliyor.

---

## Bilinmesi Gereken Riskler

1. **Sunucu Tokyo'da.** Her tıklamada gecikme var. Veri girilmeden taşınmalı.
2. **Supabase ücretsiz projesi 7 gün kullanılmazsa uykuya geçer.** 50 aktif
   kullanıcı varsa sorun olmaz.
3. **Secret key asla `index.html`'e girmemeli.** Tüm güvenlik kurallarını
   devre dışı bırakır, dosya internette herkese açık.
4. **Yedek yok.** Supabase otomatik yedekliyor ama ücretsiz katmanda geri
   dönüş sınırlı. Kritik veri girildikten sonra düzenli dışa aktarım düşünülmeli.
