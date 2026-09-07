-- =====================================================================
-- SEMERKAND KURTKÖY VAKFI — TAKİP SİSTEMİ
-- Bölüm 1: Veritabanı şeması, roller, yetkiler
-- Supabase > SQL Editor'a yapıştır, Run.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. TEMEL TİPLER
-- ---------------------------------------------------------------------

create type kol_tipi    as enum ('erkek', 'kadin');
create type gorev_tipi  as enum ('baskan', 'mudur', 'ticaret', 'sosyal', 'dergi', 'vekil');
create type alan_tipi   as enum ('metin', 'uzun_metin', 'sayi', 'para', 'tarih', 'secim', 'evet_hayir');
create type talep_tipi  as enum ('ekleme', 'duzeltme', 'silme');
create type talep_durum as enum ('beklemede', 'onaylandi', 'reddedildi');


-- ---------------------------------------------------------------------
-- 2. KULLANICILAR
--    Supabase Auth'a bağlı profil tablosu.
-- ---------------------------------------------------------------------

create table kullanicilar (
  id            uuid primary key references auth.users(id) on delete cascade,
  ad_soyad      text not null,
  telefon       text,
  kol           kol_tipi   not null,
  gorev         gorev_tipi not null,
  aktif         boolean    not null default true,
  olusturuldu   timestamptz not null default now()
);

comment on table kullanicilar is 'Vakıf kullanıcıları. Kol (erkek/kadin) + Görev ikilisi rolü belirler.';


-- ---------------------------------------------------------------------
-- 3. MODÜLLER
--    Yeni modül = buraya bir satır. Kod değişmiyor.
-- ---------------------------------------------------------------------

create table moduller (
  id             uuid primary key default gen_random_uuid(),
  kod            text not null unique,          -- 'borclar', 'simit_siparis' ...
  ad             text not null,                 -- Ekranda görünen ad
  aciklama       text,
  kol            kol_tipi,                      -- NULL = ortak, iki kol da görür
  sahip_gorev    gorev_tipi,                    -- Bu modül varsayılan olarak kimin işi
  ikon           text default 'folder',
  sira           int  not null default 100,
  aktif          boolean not null default true,
  olusturuldu    timestamptz not null default now()
);

comment on column moduller.kol         is 'NULL ise ortak modül. erkek/kadin ise sadece o kol görür.';
comment on column moduller.sahip_gorev is 'Bu göreve sahip kullanıcı ayrı izin gerekmeden erişir.';


-- ---------------------------------------------------------------------
-- 4. MODÜL ALANLARI
--    Her modülün kendi form alanları. Kolon eklemek = satır eklemek.
-- ---------------------------------------------------------------------

create table modul_alanlari (
  id          uuid primary key default gen_random_uuid(),
  modul_id    uuid not null references moduller(id) on delete cascade,
  kod         text not null,                    -- 'tutar', 'vade_tarihi' ...
  etiket      text not null,                    -- 'Tutar', 'Vade Tarihi'
  tip         alan_tipi not null default 'metin',
  secenekler  text[],                           -- tip='secim' ise seçenek listesi
  zorunlu     boolean not null default false,
  sira        int not null default 100,
  unique (modul_id, kod)
);


-- ---------------------------------------------------------------------
-- 5. KAYITLAR
--    Tüm modüllerin verisi burada. Alanlar JSONB olarak tutulur.
-- ---------------------------------------------------------------------

create table kayitlar (
  id           uuid primary key default gen_random_uuid(),
  modul_id     uuid not null references moduller(id) on delete cascade,
  kol          kol_tipi not null,               -- Kaydın ait olduğu kol
  baslik       text,                            -- Listede görünen kısa ad
  veri         jsonb not null default '{}'::jsonb,
  olusturan    uuid references kullanicilar(id),
  guncelleyen  uuid references kullanicilar(id),
  olusturuldu  timestamptz not null default now(),
  guncellendi  timestamptz not null default now()
);

create index on kayitlar (modul_id);
create index on kayitlar (kol);
create index on kayitlar using gin (veri);


-- ---------------------------------------------------------------------
-- 6. MODÜL İZİNLERİ
--    Başkan/Müdür panelden tik atarak verir.
-- ---------------------------------------------------------------------

create table modul_izinleri (
  id            uuid primary key default gen_random_uuid(),
  kullanici_id  uuid not null references kullanicilar(id) on delete cascade,
  modul_id      uuid not null references moduller(id) on delete cascade,
  okuyabilir    boolean not null default true,
  yazabilir     boolean not null default false,
  silebilir     boolean not null default false,
  veren_id      uuid references kullanicilar(id),
  olusturuldu   timestamptz not null default now(),
  unique (kullanici_id, modul_id)
);


-- ---------------------------------------------------------------------
-- 7. TALEPLER
--    Yetkisi olmayan kullanıcı talep açar, yetkili onaylar.
-- ---------------------------------------------------------------------

create table talepler (
  id            uuid primary key default gen_random_uuid(),
  modul_id      uuid not null references moduller(id) on delete cascade,
  kayit_id      uuid references kayitlar(id) on delete set null,
  tip           talep_tipi not null,
  durum         talep_durum not null default 'beklemede',
  veri          jsonb not null default '{}'::jsonb,
  not_metni     text,
  olusturan     uuid not null references kullanicilar(id),
  karar_veren   uuid references kullanicilar(id),
  karar_notu    text,
  olusturuldu   timestamptz not null default now(),
  karar_tarihi  timestamptz
);


-- ---------------------------------------------------------------------
-- 8. İŞLEM GÜNLÜĞÜ
--    Kim ne zaman ne yaptı. Vakıf işinde bu şart.
-- ---------------------------------------------------------------------

create table gunluk (
  id           bigserial primary key,
  kullanici_id uuid references kullanicilar(id),
  tablo        text not null,
  kayit_id     uuid,
  islem        text not null,                   -- INSERT / UPDATE / DELETE
  eski_veri    jsonb,
  yeni_veri    jsonb,
  tarih        timestamptz not null default now()
);

create index on gunluk (tarih desc);


-- =====================================================================
-- 9. YETKİ FONKSİYONLARI
-- =====================================================================

-- Giriş yapan kişinin kolu
create or replace function benim_kolum() returns kol_tipi
language sql stable security definer set search_path = public as $$
  select kol from kullanicilar where id = auth.uid() and aktif
$$;

-- Giriş yapan kişinin görevi
create or replace function benim_gorevim() returns gorev_tipi
language sql stable security definer set search_path = public as $$
  select gorev from kullanicilar where id = auth.uid() and aktif
$$;

-- ERKEK Başkan / Müdür = her şeyi görür, her şeyi yapar
create or replace function tam_yetkili() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from kullanicilar
    where id = auth.uid() and aktif
      and kol = 'erkek' and gorev in ('baskan','mudur')
  )
$$;

-- KADIN Başkan / Müdür = kadın kolunun her şeyini görür
create or replace function kadin_yonetici() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from kullanicilar
    where id = auth.uid() and aktif
      and kol = 'kadin' and gorev in ('baskan','mudur')
  )
$$;

-- Vekil = her koşulda sadece okur, asla yazamaz
create or replace function sadece_okur() returns boolean
language sql stable security definer set search_path = public as $$
  select benim_gorevim() = 'vekil'
$$;

-- Bu modülü okuyabilir miyim?
create or replace function modul_okuyabilir(p_modul uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select
    tam_yetkili()
    or (
      kadin_yonetici()
      and exists (select 1 from moduller m
                  where m.id = p_modul and (m.kol = 'kadin' or m.kol is null))
    )
    or exists (                                  -- kendi görevinin modülü
      select 1 from moduller m
      where m.id = p_modul and m.aktif
        and m.sahip_gorev = benim_gorevim()
        and (m.kol = benim_kolum() or m.kol is null)
    )
    or exists (                                  -- açıkça verilmiş izin
      select 1 from modul_izinleri i
      join moduller m on m.id = i.modul_id
      where i.modul_id = p_modul
        and i.kullanici_id = auth.uid()
        and i.okuyabilir
        and (m.kol = benim_kolum() or m.kol is null)
    )
$$;

-- Bu modüle yazabilir miyim?
create or replace function modul_yazabilir(p_modul uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select case
    when sadece_okur() then false
    when tam_yetkili() then true
    when kadin_yonetici() then exists (
      select 1 from moduller m
      where m.id = p_modul and (m.kol = 'kadin' or m.kol is null))
    else
      exists (select 1 from moduller m
              where m.id = p_modul and m.aktif
                and m.sahip_gorev = benim_gorevim()
                and (m.kol = benim_kolum() or m.kol is null))
      or exists (select 1 from modul_izinleri i
                 join moduller m on m.id = i.modul_id
                 where i.modul_id = p_modul
                   and i.kullanici_id = auth.uid()
                   and i.yazabilir
                   and (m.kol = benim_kolum() or m.kol is null))
  end
$$;

-- Bu modülde silebilir miyim?
create or replace function modul_silebilir(p_modul uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select case
    when sadece_okur() then false
    when tam_yetkili() then true
    when kadin_yonetici() then exists (
      select 1 from moduller m
      where m.id = p_modul and (m.kol = 'kadin' or m.kol is null))
    else exists (select 1 from modul_izinleri i
                 where i.modul_id = p_modul
                   and i.kullanici_id = auth.uid()
                   and i.silebilir)
  end
$$;


-- =====================================================================
-- 10. RLS — SATIR BAZLI GÜVENLİK
--     Yetkisiz veri veritabanından hiç çıkmaz.
-- =====================================================================

alter table kullanicilar    enable row level security;
alter table moduller        enable row level security;
alter table modul_alanlari  enable row level security;
alter table kayitlar        enable row level security;
alter table modul_izinleri  enable row level security;
alter table talepler        enable row level security;
alter table gunluk          enable row level security;

-- --- kullanicilar ---
create policy k_oku on kullanicilar for select using (
  tam_yetkili()
  or (kadin_yonetici() and kol = 'kadin')
  or id = auth.uid()
);
create policy k_yaz on kullanicilar for insert with check (tam_yetkili());
create policy k_guncelle on kullanicilar for update using (
  tam_yetkili() or (kadin_yonetici() and kol = 'kadin')
);
create policy k_sil on kullanicilar for delete using (tam_yetkili());

-- --- moduller ---  (modül ekleyip çıkarmak sadece erkek Başkan/Müdür)
create policy m_oku on moduller for select using (
  aktif and (
    tam_yetkili()
    or (kadin_yonetici() and (kol = 'kadin' or kol is null))
    or modul_okuyabilir(id)
  )
);
create policy m_yaz on moduller for all using (tam_yetkili()) with check (tam_yetkili());

-- --- modul_alanlari ---
create policy ma_oku on modul_alanlari for select using (modul_okuyabilir(modul_id));
create policy ma_yaz on modul_alanlari for all using (tam_yetkili()) with check (tam_yetkili());

-- --- kayitlar ---  (kol filtresi burada devreye giriyor)
create policy kay_oku on kayitlar for select using (
  modul_okuyabilir(modul_id)
  and (tam_yetkili() or kol = benim_kolum())
);
create policy kay_ekle on kayitlar for insert with check (
  modul_yazabilir(modul_id)
  and (tam_yetkili() or kol = benim_kolum())
);
create policy kay_guncelle on kayitlar for update using (
  modul_yazabilir(modul_id)
  and (tam_yetkili() or kol = benim_kolum())
);
create policy kay_sil on kayitlar for delete using (
  modul_silebilir(modul_id)
  and (tam_yetkili() or kol = benim_kolum())
);

-- --- modul_izinleri ---
create policy mi_oku on modul_izinleri for select using (
  tam_yetkili() or kadin_yonetici() or kullanici_id = auth.uid()
);
create policy mi_yaz on modul_izinleri for all
  using (tam_yetkili() or kadin_yonetici())
  with check (tam_yetkili() or kadin_yonetici());

-- --- talepler ---  (herkes talep açabilir, yetkili karar verir)
create policy t_oku on talepler for select using (
  tam_yetkili()
  or olusturan = auth.uid()
  or modul_yazabilir(modul_id)
);
create policy t_ac on talepler for insert with check (
  olusturan = auth.uid() and modul_okuyabilir(modul_id)
);
create policy t_karar on talepler for update using (
  tam_yetkili() or modul_yazabilir(modul_id)
);

-- --- gunluk ---  (sadece üst yönetim okur, kimse silemez)
create policy g_oku on gunluk for select using (tam_yetkili());


-- =====================================================================
-- 11. OTOMATİK GÜNLÜK KAYDI
-- =====================================================================

create or replace function gunluge_yaz() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into gunluk (kullanici_id, tablo, kayit_id, islem, eski_veri, yeni_veri)
  values (
    auth.uid(), tg_table_name,
    coalesce(new.id, old.id), tg_op,
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) end
  );
  return coalesce(new, old);
end $$;

create trigger tg_kayitlar_gunluk
  after insert or update or delete on kayitlar
  for each row execute function gunluge_yaz();

create trigger tg_izin_gunluk
  after insert or update or delete on modul_izinleri
  for each row execute function gunluge_yaz();

-- guncellendi alanını otomatik güncelle
create or replace function guncelleme_zamani() returns trigger
language plpgsql as $$
begin
  new.guncellendi := now();
  new.guncelleyen := auth.uid();
  return new;
end $$;

create trigger tg_kayit_zaman before update on kayitlar
  for each row execute function guncelleme_zamani();


-- =====================================================================
-- 12. BAŞLANGIÇ MODÜLLERİ
--     İstemediğini sil, yenisini ekle.
-- =====================================================================

insert into moduller (kod, ad, kol, sahip_gorev, sira, ikon) values
  ('borclar',        'Borçlar / Alacaklar',   null,     'mudur',   10, 'wallet'),
  ('simit_siparis',  'Simit Siparişleri',     'erkek',  'ticaret', 20, 'shopping-cart'),
  ('simit_odeme',    'Simit Ödemeleri',       'erkek',  'ticaret', 30, 'credit-card'),
  ('kurban',         'Kurban Ödemeleri',      null,     'ticaret', 40, 'gift'),
  ('kermes',         'Kermes Gelirleri',      null,     'sosyal',  50, 'store'),
  ('dergi',          'Dergi Abonelik',        null,     'dergi',   60, 'book'),
  ('bagis',          'Bağışlar',              null,     'sosyal',  70, 'heart'),
  ('uyeler',         'Üyeler',                null,     'mudur',   80, 'users'),
  ('k_borclar',      'Borçlar / Alacaklar',   'kadin',  'mudur',   90, 'wallet'),
  ('k_kermes',       'Kermes Gelirleri',      'kadin',  'sosyal', 100, 'store'),
  ('k_sosyal',       'Sosyal Faaliyetler',    'kadin',  'sosyal', 110, 'calendar');


-- Borçlar modülünün alanları (mevcut Excel defterine göre)
insert into modul_alanlari (modul_id, kod, etiket, tip, sira, zorunlu, secenekler)
select m.id, v.kod, v.etiket, v.tip::alan_tipi, v.sira, v.zorunlu, v.secenekler
from moduller m,
(values
  ('tarih',        'Tarih',             'tarih',      10, true,  null::text[]),
  ('aciklama',     'Açıklama',          'metin',      20, true,  null),
  ('para_birimi',  'Para Birimi',       'secim',      30, true,  array['TL','ALTIN','EUR','USD']),
  ('toplam_birim', 'Toplam Birim',      'sayi',       40, false, null),
  ('kur',          'Anlık Kur',         'sayi',       50, false, null),
  ('borc',         'Borç (TL)',         'para',       60, true,  null),
  ('odenen',       'Ödenen Borç (TL)',  'para',       70, false, null),
  ('vade_tarihi',  'Vade Tarihi',       'tarih',      80, false, null),
  ('odendi_tarih', 'Ödendiği Tarih',    'tarih',      90, false, null),
  ('durum',        'Durum',             'secim',     100, true,  array['Açık','Kısmi Ödendi','Kapandı']),
  ('not_metni',    'Not',               'uzun_metin',110, false, null)
) as v(kod, etiket, tip, sira, zorunlu, secenekler)
where m.kod in ('borclar','k_borclar');


-- =====================================================================
-- 13. İLK KULLANICIYI YETKİLENDİR
--     Supabase > Authentication > Users'tan kendini ekledikten sonra
--     aşağıdaki e-postayı kendi e-postanla değiştir ve bu bloğu çalıştır.
-- =====================================================================

-- insert into kullanicilar (id, ad_soyad, kol, gorev)
-- select id, 'Erol Kaan', 'erkek', 'mudur'
-- from auth.users where email = 'SENIN_EPOSTAN@ornek.com';
