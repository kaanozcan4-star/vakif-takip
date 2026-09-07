# DEVLOG — Semerkand Kurtköy Vakfı Takip Sistemi

Son güncelleme: 8 Eylül 2026

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

## KALAN VE DEVAM EDEN İŞLER

1. ✅ Supabase projesi uyandırıldı (Resume project).
2. ✅ Şifre SQL Editor üzerinden yenilendi.
5. ✅ Kira modülü veritabanına kuruldu (7 Eylül 2026, REST üzerinden; `04_kira_modulu.sql` artık sadece yedek/yeniden kurulum için). ⬜ Kira tutarları panelden girilecek.
3. ✅ **Projeyi GitHub'a Taşımak:** `main` dalı `https://github.com/kaanozcan4-star/vakif-takip` adresine yüklendi.
4. ✅ **Canlı yayın (GitHub Pages):** https://kaanozcan4-star.github.io/vakif-takip/ — `main` dalına her push 1 dk içinde yayına girer. Netlify'a gerek kalmadı.
