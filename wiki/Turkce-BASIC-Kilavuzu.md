# 🚀 Türkçe BASIC v1.0 Kılavuzu

> 🌍 **English Version:** [Turkish BASIC v1.0 Guide](Turkish-BASIC-Guide)

BIOS kabuğunda `> BASIC` komutuyla başlatılan Türkçe BASIC v1.0 (`programlar/basic.asm`), `0x0200–0x104A` adreslerinde çalışır ve kullanıcı programları için **`0x1800–0x6FFF` arasında 22 KB serbest RAM** sunar.

---

## 1. İki Çalışma Kipi: Anlık Kip vs. Programlama Kipi

- **Anlık Kip (Satır Numarasız):** Yazdığınız komut `Enter`'a basınca **anında çalışır** ve hafızaya kaydedilmez:
  ```text
  ] "MERHABA!" YAZ
  MERHABA!
  ] 25 + 17 YAZ
  42
  ```
- **Programlama Kipi (Başında Satır Numarası Var):** `10`, `20`, `30` gibi satır numaralarıyla yazılan komutlar hemen çalışmaz; RAM'de satır numarasına göre otomatik sıralanarak saklanır ve `ÇALIŞTIR` yazıldığında baştan sona koşulur.

---

## 2. Doğal Türkçe SOV ve Klasik Sözdizimi

Türkçe BASIC her komutta iki yazımı da destekler:
- **Doğal Türkçe (SOV — Fiil Sonda):** `"MERHABA" YAZ`, `10 GİT`, `X GİRDİ`, `I SONRAKİ`, `500 ÇAĞIR`, `OYUN KAYDET`
- **Klasik BASIC (SVO — Fiil Başta):** `YAZ "MERHABA"`, `GİT 10`, `GİRDİ X`, `SONRAKİ I`, `ÇAĞIR 500`, `KAYDET OYUN`

---

## 3. Örnek Uygulama: Sayı Tahmin Oyunu

```text
10 "=== SAYI TAHMİN OYUNU ===" YAZ
20 H = RASTGELE % 20 + 1
30 A = 0
40 "1-20 ARASI TAHMİNİN:" YAZ
50 T GİRDİ
60 A = A + 1
70 EĞER T = H İSE 110 GİT
80 EĞER T < H İSE "DAHA BÜYÜK!" YAZ
90 EĞER T > H İSE "DAHA KÜÇÜK!" YAZ
100 40 GİT
110 120, 4 SES
120 "TEBRİKLER! ADIM: ", A YAZ
130 BİTİR
```
- Çalıştırmak için: `ÇALIŞTIR`
- Diske kalıcı kaydetmek için: `TAHMIN KAYDET`
- Daha sonra diskten geri yüklemek için: `TAHMIN YÜKLE`
