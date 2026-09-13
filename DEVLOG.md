# DEVLOG — Semerkand Kurtköy Vakfı Takip Sistemi

Son güncelleme: 13 Eylül 2026

---

## ŞU ANKİ DURUM (7 Eylül 2026)

**Sistem altyapısı ve veriler hazır. Aktif durum:**
1. ✅ `01_vakif_semasi.sql` veritabanı şeması ve yetkileri kuruldu.
2. ✅ `02_ilk_kurulum.sql` çalıştırıldı ve ilk Müdür hesabı açıldı.
3. ✅ `server.js` yerel geliştirme sunucusu kuruldu (`http://localhost:3000` aktif).
4. ✅ Excel çek ve ödeme verileri (`03_excel_verileri.sql`) UTF-8 Türkçe desteğiyle veritabanına aktarıldı.
5. ✅ Supabase projesi uyandırıldı, Müdür şifresi SQL ile yenilendi, giriş çalışıyor.
7. ✅ **Kira Takip paneli** eklendi (`04_kira_modulu.sql` + `index.html`). SQL'in Supabase'de çalıştırılması gerekiyor.
6. ✅ **Canlı site:** https://kaanozcan4-star.github.io/vakif-takip/ (GitHub Pages, main dalı, otomatik güncellenir).
8. ✅ Çek kayıtlarındaki bozuk Türkçe karakterler (çift UTF-8) düzeltildi.
6. ✅ **GitHub:** Proje Git kontrolüne alındı, SSH ile `https://github.com/kaanozcan4-star/vakif-takip` deposuna başarıyla yüklendi.

---

## TAMAMLANAN TÜM İŞLER KRONOLOJİSİ

### 1. Altyapı Kararı
- Ücretsiz ve sıfır bakım mimarisi: Supabase + Tek Dosya HTML/JS + Netlify.
- Sunucu maliyeti ₺0, kullanıcı başı lisans ücreti yok.
- Bilgisayar kapalıyken de buluttan çalışabilir yapı.

### 2. Veritabanı Şeması ve RLS Güvenliği ✅
- `01_vakif_semasi.sql` Supabase üzerinde çalıştırıldı.
- 7 tablo oluşturuldu: `kullanicilar`, `moduller`, `modul_alanlari`, `kayitlar`, `modul_izinleri`, `talepler`, `gunluk`.
- PostgreSQL RLS (Satır Bazlı Güvenlik) ile Erkek/Kadın kolu ve görev yetkileri doğrudan veritabanında güvenceye alındı.
- 11 başlangıç modülü tanımlandı.

### 3. Arayüz ve Görsel Kimlik ✅
- `index.html` tek dosya mimarisiyle yazıldı.
- Semerkand kurumsal turkuaz rengi (**#4BBFC2**) uygulandı.
- Logo SVG/Base64 olarak doğrudan gömüldü.
- Mobil uyumlu dinamik form ve özet paneli geliştirildi.

### 4. İlk Kurulum ve Yönetici Hesabı ✅
- `02_ilk_kurulum.sql` çalıştırıldı.
- İlk kullanıcı kurulum akışı tamamlandı, ilk hesap **Erkek Müdür (Tam Yetkili)** olarak tanımlandı.

### 5. Yerel Sunucu Altyapısı ✅
- Harici paket bağımlılığı olmayan saf Node.js HTTP sunucusu `server.js` yazıldı.
- `http://localhost:3000` adresi üzerinden daimi yerel servis sağlandı.

### 6. Excel Verilerinin Aktarımı ve Karakter Düzeltmesi ✅
- Masaüstündeki `DNZ-YELKEN Mülk` klasöründe yer alan `Umit_Celik_Cek_Takip.xlsx` ve `U mit C elik Excell Takip.xlsx` dosyaları tarandı.
- 4 adet çek (Toplam 2.360.000 ₺) ve **Erol Kaan Özcan**'ın gerçekleştirdiği **150.000 ₺ nakit ödeme** verisi çıkarıldı.
- `03_excel_verileri.sql` oluşturuldu. Windows PowerShell kopyalama kaynaklı ANSI/UTF-8 karakter bozulması giderildi; UTF-8 Türkçe kodlama ile veritabanına başarıyla yüklendi.

### 7. Giriş Sorunu Analizi ve Hata Yakalama İyileştirmesi (7 Eylül 2026) ✅
- Kullanıcının `kaan.ozcan@hotmail.com` ile giriş yapamaması incelendi.
- DNS ve ağ testi yapıldı: `zfujfdzhymlrighxhebl.supabase.co` adresinin `ENOTFOUND` verdiği (7 günlük hareketsizlikten dolayı projenin Supabase tarafından **PAUSED / Uyku** moduna alındığı) tespit edildi.
- `index.html` içindeki genel hata yakalama kodu düzeltildi; ağ/sunucu kesintilerinde yanıltıcı "E-posta veya şifre hatalı" yerine gerçek sunucu uyku durumu uyarısı verilmesi sağlandı.
- Şifrenin 5 haneli (`21533`) girilmek istenmesi incelendi; Supabase'in min 6 karakter kuralı için SQL üzerinden doğrudan güncelleme çözümü hazırlandı.

---

### 8. Kira Takip Paneli (7 Eylül 2026) ✅
- `04_kira_modulu.sql`: `kira` modülü, 4 dergah kaydı, her dergah için son 12 ayın ödemesi (Erol Kaan Özcan, ayın 5'i).
- `index.html`: dergah kartları + vadeye göre dolan çubuk, 12 aylık "kim ödedi" tablosu, tüm ödeme listesi, ödeme kaydet/düzenle/sil, dergah ekle/düzenle, yetkisizler için talep akışı.
- Kira tutarları bilinmiyor, panelden girilecek.

### 9. Borç / Alacak Defteri Detaylandırıldı (8 Eylül 2026) ✅
- Özel panel: yön (borç/alacak), kişi, ne alındı (TL / altın cinsi+adet / döviz / çek / senet), o günkü kur, TL karşılığı, vade, teslim alan, belge.
- Her borcun altında geri ödemeler: kim ödedi, ne ile (nakit/havale/altın/döviz/mahsup), tutar, teslim alan, kaydeden.
- Özet: kalan borç, kalan alacak (altın olarak da), vadesi geçen; filtreler ve arama.
- 4 Ümit Çelik çeki yeni yapıya taşındı, notlardaki ödemeler 8 ödeme kaydına çevrildi; Çek 4 notundan 162.000 ₺ alacak kaydı çıkarıldı.

### 10. Anlık Kur (8 Eylül 2026) ✅
- Borç ve ödeme formlarında altın cinsi / dolar / euro seçilince anlık satış kuru çekilir, TL karşılığı otomatik hesaplanır.
- Listede ve özette açık altın/döviz kalanların bugünkü TL değeri görünür.

### 11. Kullanıcı Yönetimi (8 Eylül 2026) ✅
- Kullanıcılar ekranı (sadece erkek Başkan/Müdür): kullanıcı adı + şifre ile hesap açma, ad soyad, telefon, kol, görev, çalıştığı yer (şube/dergah), aktif/kapalı, sil.
- Yönetici şifre sıfırlar, güncel şifreleri görür (göz simgesi). Kullanıcı kendi şifresini "Şifremi değiştir" ile değiştirir, yönetici yine görür.
- Giriş ekranında "Beni hatırla". E-posta zorunluluğu kalktı.
- ⬜ `05_kullanici_yonetimi.sql` Supabase SQL Editor'da çalıştırılacak (kolonlar + fonksiyonlar, DDL olduğu için REST ile yapılamıyor).

### 12. Yedek + Uyanık Tutma + Excel (8 Eylül 2026) ✅
- GitHub Actions gece yedeği (şifreli, repoda), Supabase'i her gün uyandırır.
- Site içi Yedek ekranı: son yedek tarihi, anında JSON/CSV indirme.
- Her modülde ⬇ Excel düğmesi (kira ödemeleri, borç/alacak + ödemeler, genel modüller).
- ⬜ GitHub secrets (`SUPABASE_SERVICE_KEY`, `YEDEK_PAROLA`) kullanıcı tarafından eklenecek; sonra Actions > Run workflow.

## KALAN VE DEVAM EDEN İŞLER (13 Eylül 2026)

**Kullanıcının yapması gerekenler (Claude uzaktan yapamıyor):**
1. ⬜ **`05_kullanici_yonetimi.sql`** → Supabase > SQL Editor > New query > yapıştır > Run. Kullanıcılar ekranı, kullanıcı adıyla giriş ve şifre sıfırlama onsuz çalışmaz. (13 Eylül itibarıyla çalıştırılmadı; `kullanicilar.kullanici_adi` kolonu yok.)
2. ⬜ **Yedek secrets** → GitHub > Settings > Secrets and variables > Actions: `SUPABASE_SERVICE_KEY` (Supabase > Project Settings > API Keys > service_role) + `YEDEK_PAROLA` (kendi parolan, bir yere yaz). Sonra Actions > "Günlük yedek" > Run workflow. (13 Eylül itibarıyla `yedek/SON_YEDEK.txt` yok → hiç yedek alınmadı.)
3. ⬜ Eylül 2026 kira ödemeleri girilecek (kartlar kırmızı "gecikti" gösteriyor).
4. ⬜ Çek 1 (300.000 ₺) ve Çek 2 (960.000 ₺) ödemelerinde "Bilinmiyor (düzeltilecek)" — kim ödedi, düzeltilecek. 162.000 ₺ Ümit Çelik alacağı doğrulanacak.

**Öneriler (istenirse Claude yapar):** ana sayfa özet ekranı · Supabase'i Frankfurt'a taşıma (yedek sistemi kurulduktan sonra) · işlem günlüğü ekranı · kira hatırlatması (e-posta/Telegram) · PWA · alan adı.

**Tamamlananlar:** Supabase uyandırıldı ve şifre yenilendi · GitHub'a taşındı · GitHub Pages canlı (https://kaanozcan4-star.github.io/vakif-takip/) · Kira Takip (5 dergah, tutarlar, 12 ay geçmiş) · Borç/Alacak defteri (altın/döviz/çek, anlık kur, geri ödemeler) · Kullanıcı yönetimi kodu · Gece yedeği altyapısı · Excel dışa aktarım · Bozuk Türkçe karakterler düzeltildi.
