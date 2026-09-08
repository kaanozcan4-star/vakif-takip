#!/usr/bin/env python3
"""
Supabase'deki tüm vakıf verisini tek bir JSON dosyasına çeker.
GitHub Actions tarafından her gece çalıştırılır (.github/workflows/yedek.yml).
Elle çalıştırmak için:
  SUPABASE_URL=... SUPABASE_SERVICE_KEY=... python3 yedek/yedek_al.py /tmp/yedek.json
"""
import json, os, sys, urllib.request, urllib.error, datetime as dt

URL = os.environ.get("SUPABASE_URL", "https://zfujfdzhymlrighxhebl.supabase.co").rstrip("/")
KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")
# Yerel test: SUPABASE_JWT verilirse anon anahtar + kullanıcı oturumu ile çalışır (RLS uygulanır)
JWT = os.environ.get("SUPABASE_JWT", "")
ANON = os.environ.get("SUPABASE_ANON_KEY", "sb_publishable_9kUSG4qWWfUI7M8MkQdpQw_LDza6AMj")
CIKTI = sys.argv[1] if len(sys.argv) > 1 else "/tmp/yedek.json"
TABLOLAR = ["kullanicilar", "moduller", "modul_alanlari", "kayitlar",
            "modul_izinleri", "talepler", "gunluk", "kullanici_sifreleri"]

if JWT: KEY = JWT
if not KEY:
    sys.exit("HATA: SUPABASE_SERVICE_KEY tanımlı değil. GitHub > Settings > Secrets and variables > Actions altına ekleyin.")

def istek(path, headers=None):
    h = {"apikey": ANON if JWT else KEY, "Authorization": "Bearer " + KEY, **(headers or {})}
    r = urllib.request.Request(URL + path, headers=h)
    with urllib.request.urlopen(r, timeout=60) as resp:
        return json.loads(resp.read() or b"null"), resp.headers

def tablo_cek(tablo):
    satirlar, bas = [], 0
    while True:
        try:
            sira = "kullanici_id" if tablo == "kullanici_sifreleri" else "id"
            veri, _ = istek(f"/rest/v1/{tablo}?select=*&order={sira}", {"Range": f"{bas}-{bas+999}"})
        except urllib.error.HTTPError as e:
            if e.code == 404: return None            # tablo yok (örn. 05 SQL çalıştırılmadı)
            raise
        satirlar += veri
        if len(veri) < 1000: break
        bas += 1000
    return satirlar

yedek = {"olusturuldu": dt.datetime.now(dt.timezone.utc).isoformat(), "kaynak": URL, "tablolar": {}, "auth_kullanicilar": []}
for t in TABLOLAR:
    v = tablo_cek(t)
    if v is None:
        print(f"  {t}: tablo yok, atlandı"); continue
    yedek["tablolar"][t] = v
    print(f"  {t}: {len(v)} satır")

# Giriş hesapları (id, e-posta) — geri yüklemede kullanicilar.id eşlemesi için
try:
    sayfa = 1
    while True:
        veri, _ = istek(f"/auth/v1/admin/users?page={sayfa}&per_page=1000")
        kul = veri.get("users", veri) if isinstance(veri, dict) else veri
        yedek["auth_kullanicilar"] += [{"id": u["id"], "email": u.get("email"), "created_at": u.get("created_at")} for u in kul]
        if len(kul) < 1000: break
        sayfa += 1
    print(f"  auth kullanıcıları: {len(yedek['auth_kullanicilar'])}")
except Exception as e:
    print("  auth kullanıcıları alınamadı:", e)

toplam = sum(len(v) for v in yedek["tablolar"].values())
if toplam == 0:
    sys.exit("HATA: Hiç veri gelmedi. SUPABASE_SERVICE_KEY yanlış olabilir.")
with open(CIKTI, "w", encoding="utf-8") as f:
    json.dump(yedek, f, ensure_ascii=False, indent=1)
print(f"Yedek yazıldı: {CIKTI} ({toplam} satır, {os.path.getsize(CIKTI)//1024} KB)")
