# 🛠️ Makine İçi Monitör, Satır Assembler (`KODLA`) ve Etiketli Derleyici (`DERLE`)

> 🌍 **English Version:** [On-Machine Monitor, Line Assembler (`KODLA`) & Label Assembler (`DERLE`)](On-Machine-Monitor-and-Assembler)

TÜRK-8, dışarıdaki Python derleyicisine (`araclar/derleyici.py`) hiç ihtiyaç duymadan, **doğrudan kendi 16 KB BIOS ROM'u içindeki araçlarla** makine kodu ve etiketli assembly programı geliştirebilir.

---

## 1. Woz Tarzı Hex Monitör (`adres:` ve `adres: bayt...`)

Apple-1 Woz Monitor geleneğinden esinlenen hızlı bellek inceleme ve değiştirme kipi:
```text
> 0300: 10 48 05 01 10 49 05 01 91
> 0300:
0300: 10 48 05 01 10 49 05 01  .H...I..
...
> 0300 ÇALIŞTIR
HI
```

---

## 2. Satır İçi Etkileşimli Assembler (`[adres] KODLA`)

91 komutluk ISA v1.0 setinin tamamını satır satır anında makine koduna çevirir:
```text
> 0300 KODLA
0300: 0 X YÜKLE
0300: 13 00
0302: 'T' T YÜKLE
0302: 10 54
0304: 1 SİSTEM
0304: 05 01
0306: DÖN
0306: 91
0307:
> 0300 ÇALIŞTIR
T
```

---

## 3. Kaynak Düzenleyici (`DÜZENLE`) ve 2 Geçişli Etiketli Derleyici (`DERLE`)

Etiketler (`dongu:`), sabitler (`.TANIM`), metin dizileri (`.METİN`) ve alt/üst bayt operatörleri (`<etiket`, `>etiket`) içeren tam teşekküllü programlar için:

```text
> DÜZENLE
.BAŞLANGIÇ 0x0300
basla:
  <mesaj X YÜKLE
  >mesaj Y YÜKLE
  2 SİSTEM
  DÖN
mesaj:
  .METİN "MAKİNE İÇİNDE DERLENDİ!"
  .BAYT 10, 0
.
> KAYNAK
1: .BAŞLANGIÇ 0x0300
2: basla:
...
> SELAM DERLE
BAŞLANGIÇ: 0300 BOYUT: 0023
KAYDEDİLDİ.
> SELAM ÇALIŞTIR
MAKİNE İÇİNDE DERLENDİ!
```
