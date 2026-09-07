-- =====================================================================
-- SEMERKAND KURTKÖY VAKFI — Bölüm 2
-- İlk kullanıcının kendini Müdür olarak kurmasını sağlar.
-- Supabase > SQL Editor'a yapıştır, Run.
-- =====================================================================

-- Sistemde HİÇ kullanıcı yoksa, giriş yapan ilk kişiyi Erkek Müdür yapar.
-- Bir kullanıcı varsa hiçbir şey yapmaz — yani sonradan kimse bu yolla
-- kendini müdür yapamaz.
create or replace function ilk_kullanici_kur(p_ad text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare mevcut int;
begin
  select count(*) into mevcut from kullanicilar;
  if mevcut > 0 then return false; end if;
  if auth.uid() is null then return false; end if;

  insert into kullanicilar (id, ad_soyad, kol, gorev)
  values (auth.uid(), coalesce(nullif(trim(p_ad),''), 'Yönetici'), 'erkek', 'mudur');
  return true;
end $$;

grant execute on function ilk_kullanici_kur(text) to authenticated;

-- Sistemde kullanıcı olup olmadığını giriş ekranının sorabilmesi için
create or replace function kurulum_gerekli()
returns boolean
language sql security definer set search_path = public as $$
  select count(*) = 0 from kullanicilar
$$;

grant execute on function kurulum_gerekli() to anon, authenticated;
