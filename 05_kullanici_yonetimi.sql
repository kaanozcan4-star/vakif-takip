-- =====================================================================
-- SEMERKAND KURTKÖY VAKFI — Bölüm 5
-- Kullanıcı yönetimi: kullanıcı adı ile giriş, çalışma yeri (şube/dergah),
-- yöneticinin şifre sıfırlaması ve güncel şifreleri görebilmesi.
-- Supabase > SQL Editor'a yapıştır, Run. Tekrar çalıştırmak zararsızdır.
-- =====================================================================

-- 1) kullanicilar tablosuna yeni alanlar
alter table kullanicilar add column if not exists kullanici_adi text;
alter table kullanicilar add column if not exists calisma_yeri text;   -- 'sube' | 'dergah'
create unique index if not exists kullanicilar_kullanici_adi_ux on kullanicilar (lower(kullanici_adi));

-- Mevcut hesaplara e-postanın @ öncesini kullanıcı adı yap
update kullanicilar k set kullanici_adi = split_part(u.email, '@', 1)
from auth.users u where u.id = k.id and k.kullanici_adi is null;

-- 2) Şifre notları — SADECE erkek Başkan/Müdür okur
create table if not exists kullanici_sifreleri (
  kullanici_id uuid primary key references kullanicilar(id) on delete cascade,
  sifre        text not null,
  guncelleyen  uuid,
  guncellendi  timestamptz not null default now()
);
alter table kullanici_sifreleri enable row level security;
drop policy if exists ks_oku on kullanici_sifreleri;
drop policy if exists ks_yaz on kullanici_sifreleri;
create policy ks_oku on kullanici_sifreleri for select using (tam_yetkili());
create policy ks_yaz on kullanici_sifreleri for all using (tam_yetkili()) with check (tam_yetkili());

-- 3) Yönetici şifre sıfırlar (giriş sistemindeki şifreyi de değiştirir)
create or replace function sifre_sifirla(p_kullanici uuid, p_sifre text) returns boolean
language plpgsql security definer set search_path = public, extensions as $$
begin
  if not tam_yetkili() then raise exception 'Bu işlem için yetkiniz yok'; end if;
  if length(p_sifre) < 6 then raise exception 'Şifre en az 6 karakter olmalı'; end if;
  update auth.users
     set encrypted_password = extensions.crypt(p_sifre, extensions.gen_salt('bf')),
         email_confirmed_at = coalesce(email_confirmed_at, now()),
         updated_at = now()
   where id = p_kullanici;
  insert into kullanici_sifreleri (kullanici_id, sifre, guncelleyen)
  values (p_kullanici, p_sifre, auth.uid())
  on conflict (kullanici_id) do update
    set sifre = excluded.sifre, guncelleyen = excluded.guncelleyen, guncellendi = now();
  return true;
end $$;
grant execute on function sifre_sifirla(uuid, text) to authenticated;

-- 4) Kullanıcı kendi şifresini değiştirince notu günceller (yönetici görsün)
create or replace function sifre_notu_guncelle(p_sifre text) returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return false; end if;
  insert into kullanici_sifreleri (kullanici_id, sifre, guncelleyen)
  values (auth.uid(), p_sifre, auth.uid())
  on conflict (kullanici_id) do update
    set sifre = excluded.sifre, guncelleyen = auth.uid(), guncellendi = now();
  return true;
end $$;
grant execute on function sifre_notu_guncelle(text) to authenticated;

-- 5) Kullanıcı adıyla giriş: kullanıcı adından giriş e-postasını bulur
create or replace function kullanici_eposta(p_kullanici_adi text) returns text
language sql security definer set search_path = public as $$
  select u.email from kullanicilar k join auth.users u on u.id = k.id
  where lower(k.kullanici_adi) = lower(trim(p_kullanici_adi)) and k.aktif
  limit 1
$$;
grant execute on function kullanici_eposta(text) to anon, authenticated;

-- 6) Yönetici kullanıcıyı tamamen siler (giriş hesabı dahil)
create or replace function kullanici_sil(p_kullanici uuid) returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if not tam_yetkili() then raise exception 'Bu işlem için yetkiniz yok'; end if;
  if p_kullanici = auth.uid() then raise exception 'Kendi hesabınızı silemezsiniz'; end if;
  delete from auth.users where id = p_kullanici;   -- kullanicilar satırı cascade ile gider
  return true;
end $$;
grant execute on function kullanici_sil(uuid) to authenticated;

-- 7) Kurulum sırasında açılan deneme hesabını temizle
delete from auth.users where email in ('deneme.silinecek@vakif.local', 'deneme.silinecek2@semerkandkurtkoy.org');

-- Kontrol
select k.ad_soyad, k.kullanici_adi, k.kol, k.gorev, k.calisma_yeri, k.aktif
from kullanicilar k order by k.ad_soyad;
