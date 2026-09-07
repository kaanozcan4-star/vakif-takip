-- =====================================================================
-- SEMERKAND KURTKÖY VAKFI — Bölüm 4
-- Kira Takip modülü: dergah tanımları + son 12 ayın ödeme geçmişi.
-- Supabase > SQL Editor'a yapıştır, Run. Bir kez çalıştırılır.
-- Tekrar çalıştırılırsa hiçbir şey yapmaz (modül zaten varsa çıkar).
-- =====================================================================

DO $$
DECLARE
  v_modul   uuid;
  v_kul     uuid;
  v_yer     uuid;
  v_ay      date;
  v_bas     date;
  r         record;
BEGIN
  -- Modül zaten varsa dokunma
  IF EXISTS (SELECT 1 FROM moduller WHERE kod = 'kira') THEN
    RAISE NOTICE 'kira modülü zaten var, atlandı';
    RETURN;
  END IF;

  -- Ödemeleri kaydeden kişi: sistemdeki ilk aktif Müdür
  SELECT id INTO v_kul FROM kullanicilar
   WHERE aktif AND gorev = 'mudur' ORDER BY olusturuldu LIMIT 1;

  -- 1) Modül (ortak, müdürün sorumluluğunda, menüde en üstte)
  INSERT INTO moduller (kod, ad, aciklama, kol, sahip_gorev, sira, ikon)
  VALUES ('kira', 'Kira Takip', 'Dergah kiraları — her ayın 5''i', null, 'mudur', 5, 'home')
  RETURNING id INTO v_modul;

  -- Ödeme formu için alan tanımları (panel kendi formunu kullanır; talep ekranı bunları gösterir)
  INSERT INTO modul_alanlari (modul_id, kod, etiket, tip, sira, zorunlu) VALUES
    (v_modul, 'donem',     'Dönem (YYYY-AA)', 'metin', 10, true),
    (v_modul, 'tarih',     'Ödeme Tarihi',    'tarih', 20, true),
    (v_modul, 'tutar',     'Tutar',           'para',  30, false),
    (v_modul, 'odeyen',    'Ödeyen',          'metin', 40, true),
    (v_modul, 'not_metni', 'Not',             'uzun_metin', 50, false);

  -- 2) Dergahlar (kira yerleri). Tutar bilinmiyor, panelden "Düzenle" ile girilir.
  --    Son 12 ay: bu aydan önceki 12 ay (örn. Eyl 2025 – Ağu 2026)
  v_bas := (date_trunc('month', current_date) - interval '12 months')::date;

  FOR r IN
    SELECT * FROM (VALUES
      ('Erkek Merkez Dergahı',   'Kurtköy Merkez', 'erkek', 1),
      ('Kadın Merkez Dergahı',   '',          'kadin', 2),
      ('Aydos Kadın Dergahı',    'Aydos',     'kadin', 3),
      ('Çınardere Kadın Dergahı','Çınardere', 'kadin', 4)
    ) AS t(ad, adres, kol, sira)
  LOOP
    INSERT INTO kayitlar (modul_id, kol, baslik, veri, olusturan)
    VALUES (
      v_modul, r.kol::kol_tipi, r.ad,
      jsonb_build_object(
        'tip', 'yer', 'ad', r.ad, 'adres', r.adres,
        'tutar', null, 'vade_gunu', 5, 'sira', r.sira, 'aktif', true),
      v_kul)
    RETURNING id INTO v_yer;

    -- 3) Geçmiş 12 ayın ödemeleri — her ayın 5'inde Erol Kaan Özcan ödedi
    v_ay := v_bas;
    WHILE v_ay < date_trunc('month', current_date)::date LOOP
      INSERT INTO kayitlar (modul_id, kol, baslik, veri, olusturan, olusturuldu)
      VALUES (
        v_modul, r.kol::kol_tipi,
        r.ad || ' — ' || to_char(v_ay, 'YYYY-MM'),
        jsonb_build_object(
          'tip', 'odeme',
          'yer_id', v_yer,
          'donem', to_char(v_ay, 'YYYY-MM'),
          'tarih', to_char(v_ay + 4, 'YYYY-MM-DD'),   -- ayın 5'i
          'tutar', null,
          'odeyen', 'Erol Kaan Özcan',
          'not_metni', 'Geçmiş dönem — toplu aktarım'),
        v_kul, (v_ay + 4)::timestamptz);
      v_ay := (v_ay + interval '1 month')::date;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Kira modülü kuruldu: 4 dergah, 48 geçmiş ödeme';
END $$;

-- Kontrol: dergahlar ve ödeme sayısı
SELECT k.baslik AS dergah, k.kol,
       (SELECT count(*) FROM kayitlar o
         WHERE o.veri->>'tip' = 'odeme' AND o.veri->>'yer_id' = k.id::text) AS odeme_sayisi
FROM kayitlar k
WHERE k.veri->>'tip' = 'yer'
ORDER BY (k.veri->>'sira')::int;
