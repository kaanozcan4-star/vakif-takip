# Yedekler

Her gece 04:00'te GitHub Actions (`.github/workflows/yedek.yml`) veritabanının tamamını çeker,
`YEDEK_PAROLA` ile şifreler ve buraya yazar:

- `son.json.enc` — en son yedek
- `gunluk/vakif-YYYY-AA-GG.json.enc` — günlük yedekler (90 gün + her ayın 1'i kalıcı)
- `SON_YEDEK.txt` — son yedeğin tarihi ve tablo başına satır sayısı (şifresiz, site bunu okur)

Dosyalar şifreli olduğu için repo herkese açık olsa da içerik okunamaz.

## Kurulum (bir kez) — GitHub'da iki gizli anahtar

GitHub > repo > **Settings** > **Secrets and variables** > **Actions** > **New repository secret**:

| Ad | Değer |
|---|---|
| `SUPABASE_SERVICE_KEY` | Supabase > Project Settings > **API Keys** > `service_role` (secret) anahtarı |
| `YEDEK_PAROLA` | Kendi seçtiğin uzun bir parola. **Bir yere yaz**, yedeği açmak için lazım |

Sonra **Actions** sekmesi > "Günlük yedek" > **Run workflow** ile ilk yedeği hemen al.

## Yedeği açmak

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -in yedek/son.json.enc -out yedek.json -pass pass:PAROLA
```

## Geri yükleme

`yedek/geri_yukle.py` — boş bir Supabase projesine (01 + 02 + 04 + 05 SQL'leri çalıştırılmış) tabloları yükler:

```bash
SUPABASE_URL=https://YENI.supabase.co SUPABASE_SERVICE_KEY=... python3 yedek/geri_yukle.py yedek.json
```

Giriş hesapları (auth) yedekte id + e-posta olarak durur; `kullanici_sifreleri` tablosunda
şifreler olduğu için hesaplar aynı kullanıcı adı ve şifreyle yeniden açılabilir.
Bu işi Claude'a yaptır: "yedekten geri yükle" de, yeter.
