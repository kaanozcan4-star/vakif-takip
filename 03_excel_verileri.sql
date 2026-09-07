-- =====================================================================
-- SEMERKAND KURTKÖY VAKFI — Bölüm 3 (DÜZELTİLMİŞ)
-- Karakter bozukluklarını düzeltir ve verileri temizleyip yeniden ekler.
-- Supabase > SQL Editor'a yapıştır, Run.
-- =====================================================================

DO $$
DECLARE
  v_modul_id uuid;
  v_kullanici_id uuid;
BEGIN
  -- Önceki bozuk kayıtları temizle
  DELETE FROM kayitlar;

  -- Kullanıcı adındaki Türkçe karakter bozukluğunu düzelt (YÃ¶netici -> Yönetici)
  UPDATE kullanicilar SET ad_soyad = 'Yönetici' WHERE ad_soyad LIKE 'Y%';

  -- Borçlar modülünün ID'sini al
  SELECT id INTO v_modul_id FROM moduller WHERE kod = 'borclar' LIMIT 1;
  
  -- Sistemdeki ilk aktif kullanıcıyı (Müdür) al
  SELECT id INTO v_kullanici_id FROM kullanicilar WHERE aktif LIMIT 1;
  
  -- Çek 1 (550.000 ₺)
  INSERT INTO kayitlar (modul_id, kol, baslik, veri, olusturan, guncelleyen)
  VALUES (
    v_modul_id,
    'erkek',
    'Ümit Çelik - Çek 1 (550.000 ₺)',
    jsonb_build_object(
      'tarih', '2026-04-10',
      'aciklama', 'Ümit Çelik - Çek 1 (Çayırova)',
      'para_birimi', 'TL',
      'toplam_birim', 550000,
      'kur', 1,
      'borc', 550000,
      'odenen', 550000,
      'vade_tarihi', '2026-06-27',
      'odendi_tarih', '2026-06-27',
      'durum', 'Kapandı',
      'not_metni', 'Kuveyt Türk Çek. 10.04.2026''da Erol Kaan Özcan tarafından 150.000 ₺ Nakit ödendi. 19.05.2026''da Hayreddin Yekeler tarafından 100.000 ₺ havale yapıldı.'
    ),
    v_kullanici_id,
    v_kullanici_id
  );

  -- Çek 2 (960.000 ₺)
  INSERT INTO kayitlar (modul_id, kol, baslik, veri, olusturan, guncelleyen)
  VALUES (
    v_modul_id,
    'erkek',
    'Ümit Çelik - Çek 2 (960.000 ₺)',
    jsonb_build_object(
      'tarih', '2026-03-28',
      'aciklama', 'Ümit Çelik - Çek 2',
      'para_birimi', 'TL',
      'toplam_birim', 960000,
      'kur', 1,
      'borc', 960000,
      'odenen', 960000,
      'vade_tarihi', '2026-03-28',
      'odendi_tarih', '2026-03-28',
      'durum', 'Kapandı',
      'not_metni', 'Tamamı ödendi.'
    ),
    v_kullanici_id,
    v_kullanici_id
  );

  -- Çek 3 (500.000 ₺)
  INSERT INTO kayitlar (modul_id, kol, baslik, veri, olusturan, guncelleyen)
  VALUES (
    v_modul_id,
    'erkek',
    'Ümit Çelik - Çek 3 (500.000 ₺)',
    jsonb_build_object(
      'tarih', '2025-06-10',
      'aciklama', 'Ümit Çelik - Çek 3',
      'para_birimi', 'TL',
      'toplam_birim', 500000,
      'kur', 1,
      'borc', 500000,
      'odenen', 500000,
      'vade_tarihi', '2025-07-26',
      'odendi_tarih', '2025-07-26',
      'durum', 'Kapandı',
      'not_metni', '10.06.2025 Kurban Hizmeti karından 207.000 ₺ ödendi. 27.07.2025 Kermes POS''undan 256.000 ₺ mahsup edildi. Enver Bıçakçı tarafından 37.000 ₺ ödeme yapıldı.'
    ),
    v_kullanici_id,
    v_kullanici_id
  );

  -- Çek 4 (350.000 ₺)
  INSERT INTO kayitlar (modul_id, kol, baslik, veri, olusturan, guncelleyen)
  VALUES (
    v_modul_id,
    'erkek',
    'Ümit Çelik - Çek 4 (350.000 ₺)',
    jsonb_build_object(
      'tarih', '2025-10-18',
      'aciklama', 'Ümit Çelik - Çek 4',
      'para_birimi', 'TL',
      'toplam_birim', 350000,
      'kur', 1,
      'borc', 350000,
      'odenen', 350000,
      'vade_tarihi', '2025-11-29',
      'odendi_tarih', '2025-12-03',
      'durum', 'Kapandı',
      'not_metni', '2. Kermes POS çekimlerinden (662.045 ₺) mahsup edilerek kapatıldı. Kalan 312.000 ₺''nin 150.000 ₺''si Kurtköy''e gönderildi, 162.000 ₺ bakiye Ümit Çelik''te bekliyor.'
    ),
    v_kullanici_id,
    v_kullanici_id
  );
END $$;
