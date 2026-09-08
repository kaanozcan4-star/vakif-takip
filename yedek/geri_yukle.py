#!/usr/bin/env python3
"""
Yedek JSON'unu bir Supabase projesine geri yükler (tablolar upsert edilir).
Önce hedef projede 01, 02, 04, 05 SQL dosyaları çalıştırılmış olmalı.
Giriş hesapları: yedekteki her auth kullanıcısı için hedefte aynı e-posta yoksa
kullanici_sifreleri'ndeki şifreyle hesap açılır; id değişirse kullanicilar ve
tüm referanslar yeni id'ye eşlenir.

  SUPABASE_URL=... SUPABASE_SERVICE_KEY=... python3 yedek/geri_yukle.py yedek.json
"""
import json, os, sys, urllib.request, urllib.error

URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")
if not URL or not KEY or len(sys.argv) < 2:
    sys.exit("Kullanım: SUPABASE_URL=... SUPABASE_SERVICE_KEY=... python3 geri_yukle.py yedek.json")
yedek = json.load(open(sys.argv[1], encoding="utf-8"))
T = yedek["tablolar"]

def istek(path, method="GET", body=None, prefer=None):
    h = {"apikey": KEY, "Authorization": "Bearer " + KEY, "Content-Type": "application/json"}
    if prefer: h["Prefer"] = prefer
    r = urllib.request.Request(URL + path, data=json.dumps(body).encode() if body is not None else None, headers=h, method=method)
    try:
        with urllib.request.urlopen(r, timeout=60) as resp: return json.loads(resp.read() or b"null")
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HATA {e.code} {path}: {e.read().decode()[:400]}")

# 1) Giriş hesapları: e-postaya göre eşle, yoksa aç
mevcut = {u["email"]: u["id"] for u in istek("/auth/v1/admin/users?per_page=1000").get("users", [])}
sifreler = {s["kullanici_id"]: s["sifre"] for s in T.get("kullanici_sifreleri", [])}
esle = {}
for u in yedek.get("auth_kullanicilar", []):
    if u["email"] in mevcut:
        esle[u["id"]] = mevcut[u["email"]]
    else:
        sifre = sifreler.get(u["id"]) or "Degistir123"
        yeni = istek("/auth/v1/admin/users", "POST", {"email": u["email"], "password": sifre, "email_confirm": True})
        esle[u["id"]] = yeni["id"]
        print(f"hesap açıldı: {u['email']} (şifre: {'yedekten' if u['id'] in sifreler else 'Degistir123'})")
def m(x): return esle.get(x, x) if isinstance(x, str) else x

# 2) Tablolar, bağımlılık sırasıyla
def yukle(tablo, satirlar, alanlar_id=()):
    if not satirlar: return
    for s in satirlar:
        for a in alanlar_id: s[a] = m(s.get(a))
    for i in range(0, len(satirlar), 500):
        istek(f"/rest/v1/{tablo}?on_conflict=id", "POST", satirlar[i:i+500], "resolution=merge-duplicates,return=minimal")
    print(f"{tablo}: {len(satirlar)}")

yukle("kullanicilar", T.get("kullanicilar"), ("id",))
yukle("moduller", T.get("moduller"))
yukle("modul_alanlari", T.get("modul_alanlari"))
yukle("kayitlar", T.get("kayitlar"), ("olusturan", "guncelleyen"))
yukle("modul_izinleri", T.get("modul_izinleri"), ("kullanici_id", "veren_id"))
yukle("talepler", T.get("talepler"), ("olusturan", "karar_veren"))
ks = T.get("kullanici_sifreleri", [])
for s in ks: s["kullanici_id"] = m(s["kullanici_id"]); s["guncelleyen"] = m(s.get("guncelleyen"))
if ks: istek("/rest/v1/kullanici_sifreleri?on_conflict=kullanici_id", "POST", ks, "resolution=merge-duplicates,return=minimal"); print(f"kullanici_sifreleri: {len(ks)}")
g = T.get("gunluk", [])
for s in g: s["kullanici_id"] = m(s.get("kullanici_id"))
if g:
    for i in range(0, len(g), 500): istek("/rest/v1/gunluk", "POST", g[i:i+500], "return=minimal")
    print(f"gunluk: {len(g)}")
print("Geri yükleme tamam.")
