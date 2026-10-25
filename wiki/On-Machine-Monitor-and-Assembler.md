# 🛠️ On-Machine Monitor, Line Assembler (`KODLA`) & Label Assembler (`DERLE`)

> 🇹🇷 **Türkçe Sürüm:** [Makine İçi Monitör, Satır Assembler (`KODLA`) ve Etiketli Derleyici (`DERLE`)](Makine-Ici-Monitor-ve-Assembler)

TÜRK-8 includes a complete self-hosted machine-code monitor, interactive line assembler, source editor, and two-pass symbolic assembler right inside its **16 KB BIOS ROM**—no external host compiler required.

---

## 1. Woz-Style Hex Monitor (`addr:` and `addr: byte...`)

Inspired by the Apple-1 Woz Monitor for rapid memory inspection and byte entry:
```text
> 0300: 10 48 05 01 10 49 05 01 91
> 0300:
0300: 10 48 05 01 10 49 05 01  .H...I..
...
> 0300 ÇALIŞTIR
HI
```

---

## 2. Interactive Line Assembler (`[addr] KODLA`)

Assembles all 91 ISA v1.0 instructions directly into RAM line by line:
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

## 3. Source Editor (`DÜZENLE`) & Two-Pass Symbolic Assembler (`DERLE`)

Write multi-line assembly programs with labels (`dongu:`), constants (`.TANIM`), strings (`.METİN`), data directives (`.BAYT`, `.KELİME`, `.BOŞLUK`), and low/high byte operators (`<label`, `>label`):

```text
> DÜZENLE
.BAŞLANGIÇ 0x0300
basla:
  <mesaj X YÜKLE
  >mesaj Y YÜKLE
  2 SİSTEM
  DÖN
mesaj:
  .METİN "ASSEMBLED ON-MACHINE!"
  .BAYT 10, 0
.
> KAYNAK
1: .BAŞLANGIÇ 0x0300
2: basla:
...
> SELAM DERLE
BAŞLANGIÇ: 0300 BOYUT: 0021
KAYDEDİLDİ.
> SELAM ÇALIŞTIR
ASSEMBLED ON-MACHINE!
```
