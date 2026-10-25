# 🚀 Turkish BASIC v1.0 Guide

> 🇹🇷 **Türkçe Sürüm:** [Türkçe BASIC v1.0 Kılavuzu](Turkce-BASIC-Kilavuzu)

Launched via `> BASIC` from the BIOS shell, Turkish BASIC v1.0 (`programlar/basic.asm`) resides at `0x0200–0x104A` and provides **22 KB of free user program RAM (`0x1800–0x6FFF`)**.

---

## 1. Two Operating Modes: Immediate Mode vs. Program Mode

- **Immediate Mode (No Line Number):** Statements execute **immediately** when you press `Enter` and are not stored in program memory:
  ```text
  ] "MERHABA!" YAZ
  MERHABA!
  ] 25 + 17 YAZ
  42
  ```
- **Program Mode (Prefixed with a Line Number):** Lines starting with a number (`10`, `20`, `30`...) are automatically sorted into RAM (`0x1800+`) using the CPU's hardware `KOPYALA` instruction and executed when you type `ÇALIŞTIR`.

---

## 2. Dual Syntax: Natural Turkish SOV & Classic BASIC

Every BASIC statement supports both word orders:
- **Natural Turkish (SOV — Verb at the End):** `"MERHABA" YAZ`, `10 GİT`, `X GİRDİ`, `I SONRAKİ`, `500 ÇAĞIR`, `OYUN KAYDET`
- **Classic BASIC (SVO — Verb at the Start):** `YAZ "MERHABA"`, `GİT 10`, `GİRDİ X`, `SONRAKİ I`, `ÇAĞIR 500`, `KAYDET OYUN`

---

## 3. Sample Program: Number Guessing Game

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
- Run program in RAM: `ÇALIŞTIR`
- Save persistently to `disk.t8`: `TAHMIN KAYDET`
- Load back from `disk.t8`: `TAHMIN YÜKLE`
