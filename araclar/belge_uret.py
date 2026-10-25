#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRK-8 Dokümantasyon ve Wiki Üreticisi (Faz 8)
araclar/isa.py içindeki tek kaynaklı (single-source-of-truth) komut tablosundan
KULLANIM_KILAVUZU.md, USER_MANUAL.md ve wiki/*.md dosyalarındaki ISA v1.0
tablolarını ve referans sayfalarını otomatik üretir.
"""

import os
import sys

KOK_DIZIN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if KOK_DIZIN not in sys.path:
    sys.path.insert(0, KOK_DIZIN)

from araclar.isa import KOMUTLAR, TAKMA_ADLAR

# Her opkod için Türkçe ve İngilizce açıklama sözlüğü
ACIKLAMALAR_TR = {
    0x00: "İşlem yapmadan 1 çevrim bekler (`NOP`).",
    0x01: "İşlemciyi durdurur (`HALT`).",
    0x02: "Donanım kesmelerini etkinleştirir (`K = 0`).",
    0x03: "Donanım kesmelerini devre dışı bırakır (`K = 1`).",
    0x04: "Yazmaçları ve durum bayraklarını sıfırlar.",
    0x05: "`{n}` numaralı BIOS sistem çağrısını (`0xFFFA`) tetikler.",
    0x06: "Bir sonraki 50 Hz ekran karesine (frame) kadar bekler.",
    0x07: "Donanım LFSR üretecinden `T` yazmacına rastgele bayt (`0..255`) yükler.",
    0x10: "8-bit sabit sayıyı `T` (Toplaç) yazmacına yükler.",
    0x11: "`{a}` bellek adresindeki baytı `T` yazmacına yükler.",
    0x12: "`{a} + X` adresindeki baytı `T` yazmacına yükler.",
    0x13: "8-bit sabit sayıyı `X` indeks yazmacına yükler.",
    0x14: "8-bit sabit sayıyı `Y` indeks yazmacına yükler.",
    0x15: "`T` yazmacındaki baytı `{a}` bellek adresine yazar.",
    0x16: "`T` yazmacındaki baytı `{a} + X` adresine yazar.",
    0x17: "`X` yazmacındaki baytı `{a}` bellek adresine yazar.",
    0x18: "`Y` yazmacındaki baytı `{a}` bellek adresine yazar.",
    0x19: "`X` değerini `T` yazmacına kopyalar (`T = X`).",
    0x1A: "`T` değerini `X` yazmacına kopyalar (`X = T`).",
    0x1B: "`Y` değerini `T` yazmacına kopyalar (`T = Y`).",
    0x1C: "`T` değerini `Y` yazmacına kopyalar (`Y = T`).",
    0x1D: "`{a}` adresinde tutulan 16-bit işaretçinin gösterdiği baytı `T`'ye yükler.",
    0x1E: "`T` değerini `{a}` adresindeki 16-bit işaretçinin gösterdiği adrese yazar.",
    0x20: "`{a}` bellek adresindeki baytı `X` yazmacına yükler.",
    0x21: "`{a}` bellek adresindeki baytı `Y` yazmacına yükler.",
    0x22: "`{a} + Y` adresindeki baytı `T` yazmacına yükler.",
    0x23: "`T` yazmacındaki baytı `{a} + Y` adresine yazar.",
    0x24: "`({a} adresindeki 16-bit işaretçi) + Y` adresindeki baytı `T`'ye yükler.",
    0x25: "`T` değerini `({a} adresindeki 16-bit işaretçi) + Y` adresine yazar.",
    0x26: "Yığın göstergesini (`YG`) `T` yazmacına kopyalar.",
    0x27: "`T` değerini yığın göstergesine (`YG`) kopyalar.",
    0x28: "Sıfır sayfadaki kaynak (`[X..X+1]`), hedef (`[X+2..X+3]`) ve `Y` bayt uzunluğa göre blok kopyalar.",
    0x29: "Sıfır sayfadaki hedef (`[X..X+1]`) adresinden itibaren `Y` baytı `T` değeriyle doldurur.",
    0x30: "`T = T + {n}` (Elde, Sıfır, Negatif, Taşma bayraklarını günceller).",
    0x31: "`T = T + [{a}]` (Bellekteki baytı `T`'ye ekler).",
    0x32: "`T = T + {n} + E` (Elde bayrağıyla toplar — 16-bit toplama için).",
    0x33: "`T = T - {n}` (Sabit sayıyı `T`'den çıkarır).",
    0x34: "`T = T - [{a}]` (Bellekteki baytı `T`'den çıkarır).",
    0x35: "`T` yazmacını 1 artırır (`T++`).",
    0x36: "`X` yazmacını 1 artırır (`X++`).",
    0x37: "`Y` yazmacını 1 artırır (`Y++`).",
    0x38: "`T` yazmacını 1 azaltır (`T--`).",
    0x39: "`X` yazmacını 1 azaltır (`X--`).",
    0x3A: "`Y` yazmacını 1 azaltır (`Y--`).",
    0x3B: "`T` ile `{n}` sabitini karşılaştırır (`T - {n}`, bayrakları günceller).",
    0x3C: "`X` ile `{n}` sabitini karşılaştırır (`X - {n}`).",
    0x3D: "`Y` ile `{n}` sabitini karşılaştırır (`Y - {n}`).",
    0x3E: "`T` ile `[{a}]` bellekteki baytı karşılaştırır (`T - [{a}]`).",
    0x3F: "`T = T - {n} - (1 - E)` (Borçla çıkarma — 16-bit çıkarma için).",
    0x40: "Elde (`E`) bayrağını `1` yapar.",
    0x41: "Elde (`E`) bayrağını `0` yapar.",
    0x42: "`{a}` bellek adresindeki baytı doğrudan 1 artırır (`[{a}]++`).",
    0x43: "`{a}` bellek adresindeki baytı doğrudan 1 azaltır (`[{a}]--`).",
    0x44: "`T` değerini yüzler (`Y`), onlar (`X`) ve birler (`T`) basamaklarına ayırır.",
    0x50: "`T = T & {n}` (Bit düzeyinde VE).",
    0x51: "`T = T | {n}` (Bit düzeyinde VEYA).",
    0x52: "`T = T ^ {n}` (Bit düzeyinde ÖZELVEYA / XOR).",
    0x53: "`T = ~T` (Tüm bitleri tersler / NOT).",
    0x54: "`T` bitlerini 1 sola kaydırır (7. bit `E`'ye gider, 0. bit `0` olur).",
    0x55: "`T` bitlerini 1 sağa kaydırır (0. bit `E`'ye gider, 7. bit `0` olur).",
    0x56: "`T` bitlerini Elde (`E`) üzerinden 1 sola döndürür (`ROL`).",
    0x57: "`T` bitlerini Elde (`E`) üzerinden 1 sağa döndürür (`ROR`).",
    0x58: "`T & {n}` işlemini yapar; `T` değişmez, yalnızca `S` (Sıfır) bayrağı güncellenir.",
    0x59: "`T = T & [{a}]` (Bellekteki bayt ile VE).",
    0x5A: "`T = T | [{a}]` (Bellekteki bayt ile VEYA).",
    0x70: "Koşulsuz olarak `{a}` adresine atlar (`PS = {a}`).",
    0x71: "Eşitse (`S == 1`) `{a}` adresine atlar.",
    0x72: "Farklıysa (`S == 0`) `{a}` adresine atlar.",
    0x73: "İşaretsiz karşılaştırmada büyükse (`E == 1` ve `S == 0`) `{a}` adresine atlar.",
    0x74: "İşaretsiz karşılaştırmada küçükse (`E == 0`) `{a}` adresine atlar.",
    0x75: "Elde varsa / büyük veya eşitse (`E == 1`) `{a}` adresine atlar.",
    0x76: "Elde yoksa (`E == 0`) `{a}` adresine atlar.",
    0x77: "Sonuç negatifse (`N == 1`) `{a}` adresine atlar.",
    0x78: "Sonuç pozitif veya sıfırsa (`N == 0`) `{a}` adresine atlar.",
    0x79: "İşaretli taşma varsa (`T == 1`) `{a}` adresine atlar.",
    0x7A: "İşaretsiz karşılaştırmada küçük veya eşitse (`E == 0` veya `S == 1`) `{a}` adresine atlar.",
    0x7B: "`{a}` adresinde kayıtlı 16-bit hedefe dolaylı atlar (`PS = [{a}]`).",
    0x7C: "`{a}` adresinde kayıtlı 16-bit alt programı dolaylı çağırır.",
    0x90: "Dönüş adresini yığına itip `{a}` alt programını çağırır (`CALL`).",
    0x91: "Yığından dönüş adresini çekip alt programdan döner (`RET`).",
    0x92: "Yığından `DURUM` ve `PS` değerlerini çekip kesmeden döner (`RTI`).",
    0x93: "`T` yazmacını donanım yığınına iter (`PUSH T`).",
    0x94: "Donanım yığınından 1 bayt çekip `T` yazmacına yazar (`POP T`).",
    0x95: "`DURUM` bayrak yazmacını yığına iter.",
    0x96: "Yığından 1 bayt çekip `DURUM` bayrak yazmacına yazar.",
    0x97: "`X` indeks yazmacını yığına iter (`PUSH X`).",
    0x98: "Yığından 1 bayt çekip `X` indeks yazmacına yazar (`POP X`).",
    0x99: "`Y` indeks yazmacını yığına iter (`PUSH Y`).",
    0x9A: "Yığından 1 bayt çekip `Y` indeks yazmacına yazar (`POP Y`).",
    0xB0: "`0xA000 + {n}` MMIO portundan 1 bayt okuyup `T` yazmacına yükler.",
    0xB1: "`T` yazmacındaki baytı `0xA000 + {n}` MMIO portuna yazar.",
}

ACIKLAMALAR_EN = {
    0x00: "No operation; advances 1 clock cycle (`NOP`).",
    0x01: "Halt processor execution (`HALT`).",
    0x02: "Enable hardware interrupts (`K = 0`).",
    0x03: "Disable hardware interrupts (`K = 1`).",
    0x04: "Clear registers and status flags.",
    0x05: "Invoke BIOS syscall `{n}` via vector `0xFFFA`.",
    0x06: "Suspend CPU until the next 50 Hz frame tick.",
    0x07: "Load random byte (`0..255`) from hardware LFSR into `T`.",
    0x10: "Load 8-bit immediate `{n}` into Accumulator `T`.",
    0x11: "Load byte at 16-bit address `{a}` into `T`.",
    0x12: "Load byte at `{a} + X` into `T`.",
    0x13: "Load 8-bit immediate `{n}` into index register `X`.",
    0x14: "Load 8-bit immediate `{n}` into index register `Y`.",
    0x15: "Store `T` to 16-bit memory address `{a}`.",
    0x16: "Store `T` to memory address `{a} + X`.",
    0x17: "Store `X` to 16-bit memory address `{a}`.",
    0x18: "Store `Y` to 16-bit memory address `{a}`.",
    0x19: "Copy `X` into `T` (`T = X`).",
    0x1A: "Copy `T` into `X` (`X = T`).",
    0x1B: "Copy `Y` into `T` (`T = Y`).",
    0x1C: "Copy `T` into `Y` (`Y = T`).",
    0x1D: "Indirect load: read 16-bit pointer at `{a}`, load byte from that address into `T`.",
    0x1E: "Indirect store: store `T` to the 16-bit address stored at `{a}`.",
    0x20: "Load byte at `{a}` into `X`.",
    0x21: "Load byte at `{a}` into `Y`.",
    0x22: "Load byte at `{a} + Y` into `T`.",
    0x23: "Store `T` to memory address `{a} + Y`.",
    0x24: "Indirect Y-indexed load: read pointer at `{a}`, load byte at `ptr + Y` into `T`.",
    0x25: "Indirect Y-indexed store: read pointer at `{a}`, store `T` to `ptr + Y`.",
    0x26: "Copy stack pointer `YG` into `T`.",
    0x27: "Copy `T` into stack pointer `YG`.",
    0x28: "Block copy `Y` bytes from zero-page pointer `[X..X+1]` to `[X+2..X+3]` (overlap-safe).",
    0x29: "Block fill `Y` bytes starting at zero-page pointer `[X..X+1]` with value `T`.",
    0x30: "`T = T + {n}` (updates Carry, Zero, Negative, Overflow).",
    0x31: "`T = T + [{a}]` (add memory byte to `T`).",
    0x32: "`T = T + {n} + E` (add with carry for multi-byte addition).",
    0x33: "`T = T - {n}` (subtract immediate from `T`).",
    0x34: "`T = T - [{a}]` (subtract memory byte from `T`).",
    0x35: "Increment `T` (`T++`).",
    0x36: "Increment `X` (`X++`).",
    0x37: "Increment `Y` (`Y++`).",
    0x38: "Decrement `T` (`T--`).",
    0x39: "Decrement `X` (`X--`).",
    0x3A: "Decrement `Y` (`Y--`).",
    0x3B: "Compare `T` with immediate `{n}` (`T - {n}`).",
    0x3C: "Compare `X` with immediate `{n}` (`X - {n}`).",
    0x3D: "Compare `Y` with immediate `{n}` (`Y - {n}`).",
    0x3E: "Compare `T` with memory byte `[{a}]` (`T - [{a}]`).",
    0x3F: "`T = T - {n} - (1 - E)` (subtract with borrow for 16-bit subtraction).",
    0x40: "Set Carry flag (`E = 1`).",
    0x41: "Clear Carry flag (`E = 0`).",
    0x42: "Increment byte in memory at `{a}` (`[{a}]++`).",
    0x43: "Decrement byte in memory at `{a}` (`[{a}]--`).",
    0x44: "Split `T` into decimal digits: hundreds in `Y`, tens in `X`, ones in `T`.",
    0x50: "`T = T & {n}` (bitwise AND with immediate).",
    0x51: "`T = T | {n}` (bitwise OR with immediate).",
    0x52: "`T = T ^ {n}` (bitwise XOR with immediate).",
    0x53: "`T = ~T` (bitwise NOT).",
    0x54: "Logical shift left `T` by 1 bit (bit 7 -> `E`).",
    0x55: "Logical shift right `T` by 1 bit (bit 0 -> `E`).",
    0x56: "Rotate left `T` through Carry (`ROL`).",
    0x57: "Rotate right `T` through Carry (`ROR`).",
    0x58: "Test bits (`T & {n}`); updates Zero flag `S` without modifying `T`.",
    0x59: "`T = T & [{a}]` (bitwise AND with memory byte).",
    0x5A: "`T = T | [{a}]` (bitwise OR with memory byte).",
    0x70: "Unconditional jump to `{a}` (`PS = {a}`).",
    0x71: "Jump to `{a}` if Equal (`S == 1`).",
    0x72: "Jump to `{a}` if Not Equal (`S == 0`).",
    0x73: "Jump to `{a}` if Unsigned Greater (`E == 1` and `S == 0`).",
    0x74: "Jump to `{a}` if Unsigned Less (`E == 0`).",
    0x75: "Jump to `{a}` if Carry Set / Unsigned Greater or Equal (`E == 1`).",
    0x76: "Jump to `{a}` if Carry Clear (`E == 0`).",
    0x77: "Jump to `{a}` if Negative (`N == 1`).",
    0x78: "Jump to `{a}` if Positive or Zero (`N == 0`).",
    0x79: "Jump to `{a}` if Signed Overflow (`T == 1`).",
    0x7A: "Jump to `{a}` if Unsigned Less or Equal (`E == 0` or `S == 1`).",
    0x7B: "Indirect jump through 16-bit pointer at `{a}` (`PS = [{a}]`).",
    0x7C: "Indirect subroutine call through 16-bit pointer at `{a}`.",
    0x90: "Call subroutine at `{a}` (pushes return address onto stack).",
    0x91: "Return from subroutine (`RET`).",
    0x92: "Return from interrupt (`RTI`: pops `DURUM` and `PS`).",
    0x93: "Push `T` onto hardware stack.",
    0x94: "Pop byte from hardware stack into `T`.",
    0x95: "Push `DURUM` status flags onto stack.",
    0x96: "Pop `DURUM` status flags from stack.",
    0x97: "Push `X` onto hardware stack.",
    0x98: "Pop byte from hardware stack into `X`.",
    0x99: "Push `Y` onto hardware stack.",
    0x9A: "Pop byte from hardware stack into `Y`.",
    0xB0: "Read byte from MMIO port `0xA000 + {n}` into `T`.",
    0xB1: "Write `T` to MMIO port `0xA000 + {n}`.",
}


def isa_tablosu_uret_tr():
    satirlar = [
        "| Opkod | C Sabiti | Söz Dizimi Deseni | Boyut | Açıklama |",
        "| :---: | :--- | :--- | :---: | :--- |",
    ]
    for k in KOMUTLAR:
        aciklama = ACIKLAMALAR_TR.get(k.opkod, "")
        satirlar.append(
            f"| `0x{k.opkod:02X}` | `{k.ad}` | `{k.desen}` | {k.boyut} bayt | {aciklama} |"
        )
    for k in TAKMA_ADLAR:
        satirlar.append(
            f"| `0x{k.opkod:02X}` *(takma ad)* | `{k.ad}` | `{k.desen}` | {k.boyut} bayt | `ELDE VARSA ATLA` ile aynı opkoda derlenir (işaretsiz $\\ge$). |"
        )
    return "\n".join(satirlar)


def isa_tablosu_uret_en():
    satirlar = [
        "| Opcode | C Constant | Syntax Pattern | Size | Description |",
        "| :---: | :--- | :--- | :---: | :--- |",
    ]
    for k in KOMUTLAR:
        aciklama = ACIKLAMALAR_EN.get(k.opkod, "")
        satirlar.append(
            f"| `0x{k.opkod:02X}` | `{k.ad}` | `{k.desen}` | {k.boyut} B | {aciklama} |"
        )
    for k in TAKMA_ADLAR:
        satirlar.append(
            f"| `0x{k.opkod:02X}` *(alias)* | `{k.ad}` | `{k.desen}` | {k.boyut} B | Alias for `ELDE VARSA ATLA` (unsigned $\\ge$). |"
        )
    return "\n".join(satirlar)


def kullanim_kilavuzu_uret(tablo_tr):
    return f"""# 🇹🇷 TÜRK-8 PROGRAMLAMA VE KULLANIM KILAVUZU (v1.0)
### *8-Bit Türkçe Kişisel Bilgisayar Mimarisi Tam Teknik Referansı*

> 🌍 **English Version:** For the English user manual and instruction set reference, see [USER_MANUAL.md](USER_MANUAL.md).  
> 🏠 **Proje Özeti & Wiki:** [OKUBENI.md](OKUBENI.md), [README.md](README.md) ve [`wiki/Home.md`](wiki/Home.md) belgelerine göz atabilirsiniz.

---

## 📑 İÇİNDEKİLER
1. [Giriş ve Türkçe Söz Dizimi Mantığı (SOV)](#1-giriş-ve-türkçe-söz-dizimi-mantığı-sov)
2. [İşlemci Mimarisi, Yazmaçlar ve Türkçe Karakter Seti](#2-işlemci-mimarisi-yazmaçlar-ve-türkçe-karakter-seti)
3. [64 KB Bellek Haritası, MMIO Donanımı ve BIOS Servisleri](#3-64-kb-bellek-haritası-mmio-donanımı-ve-bios-servisleri)
4. [Eksiksiz Komut Seti Referansı — ISA v1.0 (91 Komut)](#4-eksiksiz-komut-seti-referansı--isa-v10-91-komut)
5. [BIOS Kabuk Komutları ve Sanal Disk (`disk.t8`)](#5-bios-kabuk-komutları-ve-sanal-disk-diskt8)
6. [Makine İçi Monitör, Satır Assembler (`KODLA`) ve Etiketli Derleyici (`DÜZENLE` / `DERLE`)](#6-makine-içi-monitör-satır-assembler-kodla-ve-etiketli-derleyici-düzenle--derle)
7. [Türkçe BASIC v1.0 Kullanım Kılavuzu](#7-türkçe-basic-v10-kullanım-kılavuzu)
8. [Adım Adım Assembly Dersleri ve Çoklu Platform Desteği](#8-adım-adım-assembly-dersleri-ve-çoklu-platform-desteği)

---

## 1. Giriş ve Türkçe Söz Dizimi Mantığı (SOV)

TÜRK-8, Türkçenin doğal dilbilgisi kurallarına (**Özne / Nesne $\\rightarrow$ Yüklem**) göre tasarlanmıştır. Klasik İngilizce mimarilerde fiil başta gelirken (`LOAD 5`, `JUMP loop`), **TÜRK-8'de hem işlemci komutlarında, hem BIOS kabuğunda, hem de Türkçe BASIC dilinde eylem (yüklem) cümlenin sonundadır:**

| Katman | Klasik (İngilizce / SVO) | TÜRK-8 (Doğal Türkçe / SOV) |
| :--- | :--- | :--- |
| **İşlemci (ISA v1.0)** | `LDA #5` / `JMP dongu` | **`5 T YÜKLE`** / **`dongu ATLA`** |
| **BIOS Kabuğu** | `RUN PONG` / `LOAD BASIC` | **`PONG ÇALIŞTIR`** / **`BASIC YÜKLE`** |
| **Türkçe BASIC v1.0** | `PRINT "SELAM"` / `GOTO 10` | **`"SELAM" YAZ`** / **`10 GİT`** |

---

## 2. İşlemci Mimarisi, Yazmaçlar ve Türkçe Karakter Seti

| Yazmaç | Adı | Genişlik | Açıklama |
| :---: | :--- | :---: | :--- |
| **`T`** | **Toplaç (Akümülatör)** | 8 Bit (`0..255`) | Tüm aritmetik, mantık ve veri transferlerinin ana merkezidir. |
| **`X`** | **1. İndeks Yazmacı** | 8 Bit (`0..255`) | Sayaçlar, `[a + X]` dizi indeksleme ve `KOPYALA`/`DOLDUR` parametreleri. |
| **`Y`** | **2. İndeks Yazmacı** | 8 Bit (`0..255`) | `[a + Y]`, dolaylı `[[a] + Y]` indeksleme ve blok uzunluğu. |
| **`YG`** | **Yığın Göstergesi (SP)** | 8 Bit (`0..255`) | Donanım yığınının (`0x0100 - 0x01FF`) tepe adresini tutar (`0xFF`'ten aşağı büyür). |
| **`PS`** | **Program Sayacı (PC)** | 16 Bit (`0..65535`)| Sıradaki çalıştırılacak komutun bellek adresini tutar. |
| **`DURUM`**| **Durum Bayrakları** | 8 Bit | `E` (Elde/Bit 0), `S` (Sıfır/Bit 1), `K` (Kesme/Bit 2), `N` (Negatif/Bit 6), `T` (Taşma/Bit 7). |

### 8-Bit Tek Baytlık Türkçe Karakter Seti (ISO-8859-9)
TÜRK-8'de tüm Türkçe harfler bellekte ve VRAM'de **tam 1 bayt** yer kaplar:
- Büyük harfler: `Ğ` (`0xD0`), `Ü` (`0xDC`), `Ş` (`0xDE`), `İ` (`0xDD`), `Ö` (`0xD6`), `Ç` (`0xC7`)
- Küçük harfler: `ğ` (`0xF0`), `ü` (`0xFC`), `ş` (`0xFE`), `ı` (`0xFD`), `ö` (`0xF6`), `ç` (`0xE7`)

---

## 3. 64 KB Bellek Haritası, MMIO Donanımı ve BIOS Servisleri

| Adres Aralığı | Bölge | Açıklama |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | **Sıfır Sayfa (Zero Page)** | Hızlı erişimli 256 bayt RAM (`0x00D0–0x00FF`: BIOS/Kabuk çalışma alanı) |
| `0x0100 - 0x01FF` | **Donanım Yığını (Stack)** | `YG` ile yönetilen 256 bayt LIFO yığını |
| `0x0200 - 0x7FFF` | **Kullanıcı Belleği (RAM)** | Programlar (`0x0200+`), BASIC (`0x1800+`), `DÜZENLE` tamponu (`0x6000+`) |
| `0x8000 - 0x83E7` | **VRAM Ekran Belleği** | 40 sütun $\\times$ 25 satır = 1000 karakterlik CRT ekran (`0x8000 + satır*40 + sütun`) |
| `0xA000 - 0xA0FF` | **MMIO Donanım Portları** | Klavye FIFO, 50 Hz zamanlayıcı, ses, LFSR RNG, DMA disk denetleyicisi |
| `0xC000 - 0xFFFF` | **Sistem ROM / BIOS** | 16 KB salt okunur BIOS, Kabuk, Monitör, Assembler ve vektörler |

### MMIO Donanım Portları (`0xA000 - 0xA0FF`)
- **`0xA000` (`PORT_KLAVYE_VERI`):** 16 baytlık klavye FIFO kuyruğundan sıradaki tuşu çeker.
- **`0xA001` (`PORT_KLAVYE_DURUM`):** Bit 0: Tuş hazır (`1`), Bit 1: FIFO taştı (`1`).
- **`0xA002` (`PORT_ZAMANLAYICI`):** 50 Hz (20 ms) donanım sayacı.
- **`0xA003` (`PORT_SERI_CIKIS`):** Yazılan baytı doğrudan ana makine terminaline (`stdout`) basar.
- **`0xA004` / `0xA005` (`PORT_SES_FREKANS` / `PORT_SES_SURE`):** Frekans ve süre yazılınca ses üretir.
- **`0xA006` (`PORT_RASTGELE`):** 16-bit LFSR donanım rastgele sayı üreteci.
- **`0xA010 - 0xA016` (`PORT_DISK_*`):** DMA sanal disk denetleyicisi (`KOMUT`, `DURUM`, `SEKTOR`, `ADRES_ALT`, `ADRES_UST`, `SAYI`, `HATA`).

### BIOS Sistem Çağrıları (`<n> SİSTEM` — Vektör `0xFFFA`)
| Çağrı | Komut | Girdi Yazmaçları | Çıktı / Açıklama |
| :---: | :--- | :--- | :--- |
| `0` | `0 SİSTEM` | — | Ekranı temizler, imleci `(0, 0)` konumuna alır. |
| `1` | `1 SİSTEM` | `T` = Karakter | `T`'deki karakteri imleç konumuna basar (`\\n`, `\\b`, kaydırma destekli). |
| `2` | `2 SİSTEM` | `X` = Alt, `Y` = Üst adres | `Y:X` adresindeki sıfır sonlandırmalı metni ekrana basar. |
| `3` | `3 SİSTEM` | — | Beklemesiz tuş okur: tuş varsa `T` = tuş ve `S=0`, yoksa `T=0` ve `S=1`. |
| `4` | `4 SİSTEM` | — | Tuş basılana kadar bekler, basılan tuşu `T` içinde döndürür. |
| `5` | `5 SİSTEM` | — | Klavyeden `Enter`'a kadar bir satır okur (`0x0080` tamponuna yazar, `T` = uzunluk). |
| `6` | `6 SİSTEM` | — | VRAM ekranını 1 satır yukarı kaydırır, en alt satırı temizler. |
| `7` | `7 SİSTEM` | `X` = Frekans, `Y` = Süre | Belirtilen frekans ve sürede ses çalar. |
| `8` | `8 SİSTEM` | — | 50 Hz çalışma süresi sayacını okur (`T` = alt, `X` = orta, `Y` = üst bayt). |

---

## 4. Eksiksiz Komut Seti Referansı — ISA v1.0 (91 Komut)

> **Not:** Bu tablo doğrudan [`araclar/isa.py`](araclar/isa.py) içindeki tek kaynaklı komut tablosundan otomatik üretilmiştir.

{tablo_tr}

---

## 5. BIOS Kabuk Komutları ve Sanal Disk (`disk.t8`)

`./turk8` ile açılışta gelen `> ` isteminde hem doğal Türkçe SOV (`PONG ÇALIŞTIR`) hem de klasik (`ÇALIŞTIR PONG`) sırayla aşağıdaki komutları kullanabilirsiniz:

| Komut | Açıklama |
| :--- | :--- |
| **`YARDIM`** | Tüm yerleşik kabuk, disk, monitör ve derleyici komutlarını listeler. |
| **`TEMİZLE`** | Ekranı temizler. |
| **`BİLGİ`** | İşlemci, ROM, RAM ve donanım özetini gösterir. |
| **`SÜRE`** | Bilgisayarın açılışından beri geçen 50 Hz tik sayısını (onaltılık) gösterir. |
| **`[adres] BELLEK`** | Belirtilen adresten itibaren 64 baytı hex ve ASCII olarak döker. |
| **`LİSTE`** | `disk.t8` üzerindeki dosyaları ve bayt boyutlarını listeler. |
| **`<AD> YÜKLE`** | Dosyayı diskten başlangıç adresine (`0x0200`) yükler. |
| **`<AD> [adr] [boyut] KAYDET`** | Bellekteki `[adr]` bölgesinden `[boyut]` baytı diske kaydeder. |
| **`<AD> SİL`** | Dosyayı disk dizininden siler. |
| **`<AD \| adres> ÇALIŞTIR`** | Diskteki programı yükleyip çalıştırır veya verilen bellek adresine dallanır. |
| **`BASIC`** | Diskten Türkçe BASIC v1.0 yorumlayıcısını yükleyip başlatır. |

---

## 6. Makine İçi Monitör, Satır Assembler (`KODLA`) ve Etiketli Derleyici (`DÜZENLE` / `DERLE`)

### A) Woz Tarzı Hex Monitör
- **Bellek Dökümü:** `> 0300:` yazarak `0x0300` adresinden itibaren 64 baytı görüntüleyin.
- **Belleğe Bayt Yazma:** `> 0300: 10 2A 15 00 80 91` yazarak baytları doğrudan RAM'e işleyin.

### B) Satır İçi Etkileşimli Assembler (`[adres] KODLA`)
```text
> 0300 KODLA
0300: 'A' T YÜKLE
0300: 10 41
0302: 1 SİSTEM
0302: 05 01
0304: DÖN
0304: 91
0305:              ; Boş satırda Enter ile çıkılır
> 0300 ÇALIŞTIR
A
```

### C) Tam Ekran Kaynak Düzenleyici (`DÜZENLE`) ve 2 Geçişli Etiketli Derleyici (`DERLE`)
`0x6000–0x77FF` arasındaki kaynak tamponuna etiketli assembly programı yazıp makinenin kendi içinde derleyebilirsiniz:
```text
> DÜZENLE
.BAŞLANGIÇ 0x0300
.TANIM HARF 0x42
basla:
  HARF T YÜKLE
  1 SİSTEM
  DÖN
.                  ; Tek nokta ile düzenleyiciden çıkılır
> KAYNAK           ; Yazılan kaynak kodu numaralı satırlarla listeler
> DERLE            ; 2 geçişli derleyiciyle 0x0300 adresine derler (veya: SELAM DERLE ile diske kaydeder)
> 0300 ÇALIŞTIR
B
```
- Düzenleyici içi özel komutlar: `SİL` (son satırı siler), `YENİ` (kaynak tamponunu sıfırlar), `.` (düzenleyiciden çıkar).
- Desteklenen sözde komutlar: `.BAŞLANGIÇ`, `.TANIM`, `.BAYT`, `.KELİME`, `.BOŞLUK`, `.METİN`, `<etiket` (alt bayt) ve `>etiket` (üst bayt).

---

## 7. Türkçe BASIC v1.0 Kullanım Kılavuzu

BIOS kabuğunda `> BASIC` yazarak `] ` istemine geçilir. Kullanılabilir 26 tam sayı değişkeni (`A`–`Z`, 16-bit `0..65535`) ve 22 KB program alanı (`0x1800–0x6FFF`) vardır.

| Komut (Doğal SOV / Klasik) | Açıklama ve Örnek |
| :--- | :--- |
| **`"METİN", İFADE YAZ`** / `YAZ ...` | Ekrana metin veya matematiksel ifade basar (`"SONUC: ", A + B YAZ`). |
| **`DEĞİŞKEN GİRDİ`** / `GİRDİ DEĞİŞKEN` | Kullanıcıdan `? ` istemiyle sayı okur (`X GİRDİ`). |
| **`EĞER <koşul> İSE <komut>`** | Koşul (`=`, `<>`, `!=`, `<`, `>`, `<=`, `>=`) doğruysa komutu çalıştırır. |
| **`<satır> GİT`** / `GİT <satır>` | Belirtilen satır numarasına dallanır (`100 GİT`). |
| **`<satır> ÇAĞIR`** ve **`DÖN`** | Alt programa gider ve `DÖN` ile çağrıldığı satırın sonrasına döner. |
| **`DÖNGÜ I = <baş> BİTİŞ <son>`** ... **`I SONRAKİ`** | `I` değişkenini `<baş>` değerinden `<son>` değerine kadar 1'er artırarak döndürür. |
| **`RASTGELE`** | İfadelerde `0..255` arası donanım rastgele sayısı üretir (`X = RASTGELE % 10`). |
| **`<frek>, <süre> SES`** / `SES <f>, <s>` | Hoparlörden ses çalar (`120, 4 SES`). |
| **`TEMİZLE`** | Ekranı temizler. |
| **`BİTİR`** / **`DUR`** | Programın çalışmasını sonlandırır. |
| **`LİSTELE`**, **`ÇALIŞTIR`**, **`YENİ`** | Programı listeler, çalıştırır veya hafızadan siler. |
| **`<AD> KAYDET`** / **`<AD> YÜKLE`** | BASIC programını `disk.t8` üzerine kaydeder veya diskten geri yükler. |
| **`ÇIK`** | BASIC'ten çıkıp BIOS `> ` kabuğuna döner. |

---

## 8. Adım Adım Assembly Dersleri ve Çoklu Platform Desteği

### Ders: BIOS Çağrısı (`2 SİSTEM`) ile Türkçe Metin Yazdırma
```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    <mesaj X YÜKLE             ; Mesaj adresinin alt baytı -> X
    >mesaj Y YÜKLE             ; Mesaj adresinin üst baytı -> Y
    2 SİSTEM                   ; BIOS Servis 2: Sıfır sonlandırmalı metni ekrana yaz
    DÖN                        ; BIOS kabuğuna temizce geri dön

mesaj:
    .METİN "MERHABA TÜRK-8 KİŞİSEL BİLGİSAYARI!"
    .BAYT 10, 0                ; Yeni satır ve sıfır sonlandırıcı
```

### Çoklu Platform Desteği (macOS, Linux, Windows)
- **🍎 macOS & 🐧 Linux:** `make && ./turk8` ile hiçbir ek kütüphane kurmadan doğrudan derlenir ve çalışır; `make test` ile tüm otomatik testler koşulur.
- **🪟 Windows (10 / 11):** WSL, Git Bash veya yerel MinGW/MSVC (`#ifdef _WIN32` konsol katmanı) ile doğrudan derlenip çalıştırılır.
"""


def user_manual_uret(tablo_en):
    return f"""# 🇹🇷 TÜRK-8 PROGRAMMING & USER MANUAL (v1.0)
### *Complete Technical Reference for the 8-Bit Turkish Personal Computer Architecture*

> 🇹🇷 **Türkçe Kılavuz:** Türkçe kullanım kılavuzu için [KULLANIM_KILAVUZU.md](KULLANIM_KILAVUZU.md) ve [`wiki/Home.md`](wiki/Home.md) belgelerine göz atabilirsiniz.  
> 🏠 **Project Overview:** See [README.md](README.md) or [OKUBENI.md](OKUBENI.md).

---

## 📑 TABLE OF CONTENTS
1. [Introduction & Syntax Philosophy (SOV)](#1-introduction--syntax-philosophy-sov)
2. [Processor Architecture, Registers & Turkish Charset](#2-processor-architecture-registers--turkish-charset)
3. [64 KB Memory Map, MMIO Hardware & BIOS Services](#3-64-kb-memory-map-mmio-hardware--bios-services)
4. [Complete Instruction Set Reference — ISA v1.0 (91 Opcodes)](#4-complete-instruction-set-reference--isa-v10-91-opcodes)
5. [BIOS Shell Commands & Virtual Disk (`disk.t8`)](#5-bios-shell-commands--virtual-disk-diskt8)
6. [On-Machine Monitor, Line Assembler (`KODLA`) & Label Assembler (`DÜZENLE` / `DERLE`)](#6-on-machine-monitor-line-assembler-kodla--label-assembler-düzenle--derle)
7. [Turkish BASIC v1.0 Reference](#7-turkish-basic-v10-reference)
8. [Assembly Tutorials & Cross-Platform Guide](#8-assembly-tutorials--cross-platform-guide)

---

## 1. Introduction & Syntax Philosophy (SOV)

TÜRK-8 is designed around the agglutinative and Subject-Object-Verb (**SOV / Postfix**) structure of the Turkish language. Across the CPU instruction set, the ROM command shell, and the built-in Turkish BASIC interpreter, **operands come first and the action verb comes last**:

| Layer | Traditional (English / SVO) | TÜRK-8 (Turkish SOV) | Literal Meaning |
| :--- | :--- | :--- | :--- |
| **CPU ISA v1.0** | `LDA #5` / `JMP loop` | **`5 T YÜKLE`** / **`dongu ATLA`** | *"5 into T LOAD"* / *"loop JUMP"* |
| **BIOS Shell** | `RUN PONG` / `LOAD BASIC` | **`PONG ÇALIŞTIR`** / **`BASIC YÜKLE`** | *"PONG RUN"* / *"BASIC LOAD"* |
| **Turkish BASIC** | `PRINT "HI"` / `GOTO 10` | **`"HI" YAZ`** / **`10 GİT`** | *'"HI" PRINT'* / *"10 GO"* |

---

## 2. Processor Architecture, Registers & Turkish Charset

| Register | Name | Width | Role |
| :---: | :--- | :---: | :--- |
| **`T`** | **Accumulator (Toplaç)** | 8-Bit (`0..255`) | Primary register for all arithmetic, logic, and data operations. |
| **`X`** | **1st Index Register** | 8-Bit (`0..255`) | Loop counter, `[a + X]` indexing, and `KOPYALA`/`DOLDUR` zero-page pointer index. |
| **`Y`** | **2nd Index Register** | 8-Bit (`0..255`) | `[a + Y]` and `[[a] + Y]` indexing, and byte count for block operations. |
| **`YG`** | **Stack Pointer (SP)** | 8-Bit (`0..255`) | Hardware stack pointer managing page 1 (`0x0100 – 0x01FF`, grows downward from `0xFF`). |
| **`PS`** | **Program Counter (PC)**| 16-Bit (`0..65535`)| Holds the 16-bit memory address of the next instruction. |
| **`DURUM`**| **Status Flags Register** | 8-Bit | `E` (Carry/Bit 0), `S` (Zero/Bit 1), `K` (IRQ Disable/Bit 2), `N` (Negative/Bit 6), `T` (Overflow/Bit 7). |

### Single-Byte 8-Bit Turkish Character Set (ISO-8859-9)
All Turkish characters occupy **1 byte** in memory and VRAM:
- Uppercase: `Ğ` (`0xD0`), `Ü` (`0xDC`), `Ş` (`0xDE`), `İ` (`0xDD`), `Ö` (`0xD6`), `Ç` (`0xC7`)
- Lowercase: `ğ` (`0xF0`), `ü` (`0xFC`), `ş` (`0xFE`), `ı` (`0xFD`), `ö` (`0xF6`), `ç` (`0xE7`)

---

## 3. 64 KB Memory Map, MMIO Hardware & BIOS Services

| Address Range | Region | Description |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | **Zero Page** | Fast 256-byte scratchpad (`0x00D0–0x00FF` reserved for BIOS/Shell state) |
| `0x0100 - 0x01FF` | **Hardware Stack** | 256-byte LIFO stack managed by `YG` |
| `0x0200 - 0x7FFF` | **User RAM** | User binaries (`0x0200+`), BASIC (`0x1800+`), `DÜZENLE` buffer (`0x6000+`) |
| `0x8000 - 0x83E7` | **VRAM** | 40 columns $\\times$ 25 rows = 1000-byte CRT character buffer |
| `0xA000 - 0xA0FF` | **MMIO Ports** | Keyboard FIFO, 50 Hz timer, sound, LFSR RNG, DMA disk controller |
| `0xC000 - 0xFFFF` | **System ROM / BIOS** | 16 KB firmware: POST, BIOS API, Shell, Monitor, On-Machine Assembler |

### MMIO Hardware Ports (`0xA000 - 0xA0FF`)
- **`0xA000` (`PORT_KLAVYE_VERI`):** Dequeues the next key byte from the 16-byte keyboard FIFO.
- **`0xA001` (`PORT_KLAVYE_DURUM`):** Bit 0: Key ready (`1`), Bit 1: FIFO overflow (`1`).
- **`0xA002` (`PORT_ZAMANLAYICI`):** 50 Hz (20 ms) hardware tick counter.
- **`0xA003` (`PORT_SERI_CIKIS`):** Writes byte directly to host `stdout`.
- **`0xA004` / `0xA005` (`PORT_SES_FREKANS` / `PORT_SES_SURE`):** Programmable beep frequency and duration.
- **`0xA006` (`PORT_RASTGELE`):** 16-bit LFSR hardware random number generator (`0..255`).
- **`0xA010 - 0xA016` (`PORT_DISK_*`):** DMA virtual disk controller (`CMD`, `STATUS`, `SECTOR`, `ADDR_LO`, `ADDR_HI`, `COUNT`, `ERR`).

### BIOS System Calls (`<n> SİSTEM` — Vector `0xFFFA`)
| Call | Instruction | Input Registers | Output / Behavior |
| :---: | :--- | :--- | :--- |
| `0` | `0 SİSTEM` | — | Clear VRAM screen and home cursor to `(0, 0)`. |
| `1` | `1 SİSTEM` | `T` = Character | Print character `T` at cursor (handles `\\n`, `\\b`, and scrolling). |
| `2` | `2 SİSTEM` | `X` = Low, `Y` = High addr | Print null-terminated string at `Y:X`. |
| `3` | `3 SİSTEM` | — | Non-blocking key read (`T` = key, `S=0` if available; `T=0`, `S=1` if empty). |
| `4` | `4 SİSTEM` | — | Blocking key read; waits for key and returns it in `T`. |
| `5` | `5 SİSTEM` | — | Read line into `0x0080` buffer until `Enter` (`T` = length). |
| `6` | `6 SİSTEM` | — | Scroll VRAM screen up by 1 row. |
| `7` | `7 SİSTEM` | `X` = Freq, `Y` = Duration | Play tone through hardware sound port. |
| `8` | `8 SİSTEM` | — | Read 24-bit 50 Hz uptime counter (`T` = low, `X` = mid, `Y` = high). |

---

## 4. Complete Instruction Set Reference — ISA v1.0 (91 Opcodes)

> **Note:** This table is automatically generated from the single-source instruction table in [`araclar/isa.py`](araclar/isa.py).

{tablo_en}

---

## 5. BIOS Shell Commands & Virtual Disk (`disk.t8`)

At the BIOS `> ` prompt, commands accept both natural Turkish SOV (`PONG ÇALIŞTIR`) and classic SVO (`ÇALIŞTIR PONG`) word order:

| Command | Description |
| :--- | :--- |
| **`YARDIM`** | List all built-in shell, disk, monitor, and assembler commands. |
| **`TEMİZLE`** | Clear the 40x25 screen. |
| **`BİLGİ`** | Display system architecture, ROM, and free RAM summary. |
| **`SÜRE`** | Print the 50 Hz uptime tick counter in hexadecimal. |
| **`[addr] BELLEK`** | Hex + ASCII dump of 64 bytes starting at `[addr]`. |
| **`LİSTE`** | List all files stored on `disk.t8` with their sizes in bytes. |
| **`<NAME> YÜKLE`** | Load `<NAME>` from disk into RAM at its load address (`0x0200`). |
| **`<NAME> [addr] [size] KAYDET`** | Save `[size]` bytes starting at `[addr]` to disk as `<NAME>`. |
| **`<NAME> SİL`** | Delete `<NAME>` from the virtual disk directory. |
| **`<NAME \| addr> ÇALIŞTIR`** | Load and execute `<NAME>` from disk, or jump to hex address `addr`. |
| **`BASIC`** | Load and start the Turkish BASIC v1.0 interpreter from disk. |

---

## 6. On-Machine Monitor, Line Assembler (`KODLA`) & Label Assembler (`DÜZENLE` / `DERLE`)

### A) Woz-Style Hex Monitor
- **Memory Dump:** Type `0300:` to dump 64 bytes starting at `0x0300`.
- **Byte Deposit:** Type `0300: 10 2A 15 00 80 91` to write raw hex bytes directly into RAM.

### B) Interactive Line Assembler (`[addr] KODLA`)
```text
> 0300 KODLA
0300: 'A' T YÜKLE
0300: 10 41
0302: 1 SİSTEM
0302: 05 01
0304: DÖN
0304: 91
0305:              ; Press Enter on an empty line to exit KODLA
> 0300 ÇALIŞTIR
A
```

### C) Source Editor (`DÜZENLE`) & Two-Pass Label Assembler (`DERLE`)
Write multi-line assembly programs with labels in the `0x6000–0x77FF` source buffer and assemble them inside the machine:
```text
> DÜZENLE
.BAŞLANGIÇ 0x0300
.TANIM HARF 0x42
basla:
  HARF T YÜKLE
  1 SİSTEM
  DÖN
.                  ; Single dot exits the editor
> KAYNAK           ; List buffered source code with line numbers
> DERLE            ; Two-pass assemble into RAM (or: SELAM DERLE to assemble & save to disk)
> 0300 ÇALIŞTIR
B
```

---

## 7. Turkish BASIC v1.0 Reference

Launch with `> BASIC`. Provides 26 16-bit unsigned integer variables (`A`–`Z`, `0..65535`) and 22 KB of program memory (`0x1800–0x6FFF`).

| Statement (Turkish SOV / Classic) | Description & Example |
| :--- | :--- |
| **`"TEXT", EXPR YAZ`** / `YAZ ...` | Print strings and arithmetic expressions (`"RESULT: ", A + B YAZ`). |
| **`VAR GİRDİ`** / `GİRDİ VAR` | Prompt `? ` and read an integer from the user (`X GİRDİ`). |
| **`EĞER <cond> İSE <stmt>`** | Conditional execution (`=`, `<>`, `!=`, `<`, `>`, `<=`, `>=`). |
| **`<line> GİT`** / `GİT <line>` | Jump to line number (`100 GİT`). |
| **`<line> ÇAĞIR`** & **`DÖN`** | Call subroutine at `<line>` (`GOSUB`) and return (`RETURN`). |
| **`DÖNGÜ I = <start> BİTİŞ <end>`** ... **`I SONRAKİ`** | `FOR` / `NEXT` loop incrementing `I` from `<start>` to `<end>`. |
| **`RASTGELE`** | Returns a random integer (`0..255`) in expressions (`X = RASTGELE % 10`). |
| **`<freq>, <dur> SES`** / `SES <f>, <d>` | Play a sound tone (`120, 4 SES`). |
| **`TEMİZLE`**, **`BİTİR`** / **`DUR`** | Clear screen; end program execution. |
| **`LİSTELE`**, **`ÇALIŞTIR`**, **`YENİ`** | List program, run program, or clear program memory. |
| **`<NAME> KAYDET`** / **`<NAME> YÜKLE`** | Save BASIC program to `disk.t8` or load it from disk. |
| **`ÇIK`** | Exit BASIC and return to the BIOS `> ` prompt. |

---

## 8. Assembly Tutorials & Cross-Platform Guide

### Example: Printing a String via BIOS Syscall (`2 SİSTEM`)
```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    <mesaj X YÜKLE             ; Low byte of message address -> X
    >mesaj Y YÜKLE             ; High byte of message address -> Y
    2 SİSTEM                   ; BIOS Service 2: print null-terminated string
    DÖN                        ; Return cleanly to BIOS shell

mesaj:
    .METİN "MERHABA TÜRK-8!"
    .BAYT 10, 0
```

### Cross-Platform Support
- **🍎 macOS & 🐧 Linux:** Build with `make`, run with `./turk8`, verify with `make test`.
- **🪟 Windows (10 / 11):** Run under WSL/Git Bash or compile natively with MinGW/MSVC (`turk8.exe`).
"""


def wiki_sayfalarini_uret(tablo_tr, tablo_en):
    wiki_dizin = os.path.join(KOK_DIZIN, "wiki")
    os.makedirs(wiki_dizin, exist_ok=True)

    sayfalar = {
        "Home.md": """# 🇹🇷 TÜRK-8 Wiki — 8-Bit Türkçe Kişisel Bilgisayar Ansiklopedisi / Encyclopedia

**TÜRK-8 v1.0** resmi teknik Wiki sayfalarına hoş geldiniz! (Welcome to the official **TÜRK-8 v1.0** technical Wiki!)
Tüm sayfalar hem **Türkçe** hem de **İngilizce** olarak birebir hazırlanmıştır.

---

## 🇹🇷 Türkçe Wiki Rehberi

1. **[Mimari ve 64 KB Bellek Haritası](Mimari-ve-Bellek-Haritasi)**
   - Yazmaçlar (`T`, `X`, `Y`, `YG`, `PS`, `DURUM`), 64 KB adres uzayı, MMIO donanım portları (`0xA000–0xA0FF`), 50 Hz kesme ve ISO-8859-9 tek baytlık Türkçe karakter tablosu.
2. **[Komut Seti Referansı (ISA v1.0 — 91 Komut)](Komut-Seti-Referansi-ISA-v1)**
   - Tek kaynaklı `araclar/isa.py` tablosundan üretilmiş tüm opkodlar (`0x00–0xB1`), bayt boyutları ve adresleme kipleri.
3. **[BIOS ROM ve Yerleşik Kabuk Komutları](BIOS-ve-Kabuk-Komutlari)**
   - `0xC000` BIOS açılış testi (POST), `0..8 SİSTEM` çağrıları ve etkileşimli `> ` kabuk komutları.
4. **[Sanal Disk Sistemi (`disk.t8`)](Sanal-Disk-Sistemi)**
   - 256 sektörlü disk formatı, DMA denetleyicisi (`0xA010–0xA016`), kabuktan ve `araclar/disk.py` ile dosya yönetimi.
5. **[Makine İçi Monitör, Satır Assembler (`KODLA`) ve Etiketli Derleyici (`DERLE`)](Makine-Ici-Monitor-ve-Assembler)**
   - Dış derleyici kullanmadan doğrudan TÜRK-8 içinde hex monitör, satır içi kodlama ve `DÜZENLE` / `DERLE` ile etiketli program geliştirme.
6. **[Türkçe BASIC v1.0 Kılavuzu](Turkce-BASIC-Kilavuzu)**
   - Doğal Türkçe SOV (`"MERHABA" YAZ`, `10 GİT`) ve klasik BASIC sözdizimi, tüm komutlar ve örnek uygulamalar.

---

## 🌍 English Wiki Guide

1. **[Architecture & 64 KB Memory Map](Architecture-and-Memory-Map)**
   - CPU registers (`T`, `X`, `Y`, `YG`, `PS`, `DURUM`), 64 KB address space, MMIO hardware ports (`0xA000–0xA0FF`), 50 Hz IRQ, and ISO-8859-9 single-byte Turkish charset.
2. **[Instruction Set Reference (ISA v1.0 — 91 Opcodes)](Instruction-Set-Reference-ISA-v1)**
   - Auto-generated table of all 91 frozen opcodes (`0x00–0xB1`), byte sizes, and addressing modes from `araclar/isa.py`.
3. **[BIOS ROM & Built-in Shell Commands](BIOS-and-Shell-Commands)**
   - `0xC000` BIOS power-on self-test (POST), `0..8 SİSTEM` syscalls, and interactive `> ` shell commands.
4. **[Virtual Disk System (`disk.t8`)](Virtual-Disk-System)**
   - 256-sector disk image layout, DMA controller (`0xA010–0xA016`), shell disk commands, and `araclar/disk.py` host tool.
5. **[On-Machine Monitor, Line Assembler (`KODLA`) & Label Assembler (`DERLE`)](On-Machine-Monitor-and-Assembler)**
   - Self-hosted development inside ROM: Woz hex monitor, interactive line assembler, and two-pass label assembler (`DÜZENLE` / `DERLE`).
6. **[Turkish BASIC v1.0 Guide](Turkish-BASIC-Guide)**
   - Natural Turkish SOV (`"MERHABA" YAZ`, `10 GİT`) and classic BASIC syntax, complete statement reference, and sample programs.
7. **[Single-Page English Technical Summary](English-Reference)**

---

## ⚡ Hızlı Başlangıç / Quick Start

```bash
make            # Build ./turk8, assemble roms/bios.rom, and create disk.t8
./turk8         # Boot directly into the BIOS shell (> )
make test       # Run the 55+ automated unit & integration test suite
```
""",
        "_Sidebar.md": """### 🇹🇷 TÜRK-8 Wiki (TR)

* 🏠 **[Ana Sayfa / Home](Home)**
* 🏛️ **[Mimari & Bellek Haritası](Mimari-ve-Bellek-Haritasi)**
* 🧠 **[Komut Seti (ISA v1.0)](Komut-Seti-Referansi-ISA-v1)**
* 🖥️ **[BIOS & Kabuk Komutları](BIOS-ve-Kabuk-Komutlari)**
* 💾 **[Sanal Disk (`disk.t8`)](Sanal-Disk-Sistemi)**
* 🛠️ **[Makine İçi Assembler](Makine-Ici-Monitor-ve-Assembler)**
* 🚀 **[Türkçe BASIC v1.0](Turkce-BASIC-Kilavuzu)**

---

### 🌍 English Wiki (EN)

* 🏛️ **[Architecture & Memory Map](Architecture-and-Memory-Map)**
* 🧠 **[Instruction Set (ISA v1.0)](Instruction-Set-Reference-ISA-v1)**
* 🖥️ **[BIOS & Shell Commands](BIOS-and-Shell-Commands)**
* 💾 **[Virtual Disk (`disk.t8`)](Virtual-Disk-System)**
* 🛠️ **[On-Machine Assembler](On-Machine-Monitor-and-Assembler)**
* 🚀 **[Turkish BASIC v1.0](Turkish-BASIC-Guide)**
* 📄 **[All-in-One EN Summary](English-Reference)**
""",
        "_Footer.md": """---
**TÜRK-8 v1.0** — 8-Bit Türkçe Kişisel Bilgisayar Mimarisi / 8-Bit Turkish Personal Computer Architecture | [GitHub Repository](https://github.com/Yukselcsgn/TURK-8)
""",
        "Mimari-ve-Bellek-Haritasi.md": """# 🏛️ İşlemci Mimarisi, 64 KB Bellek Haritası ve Donanım

> 🌍 **English Version:** [Architecture & 64 KB Memory Map](Architecture-and-Memory-Map)

## 1. Yazmaçlar (Registers)

| Yazmaç | Genişlik | Adı | Görevi |
| :---: | :---: | :--- | :--- |
| **`T`** | 8-Bit | **Toplaç (Akümülatör)** | Tüm aritmetik, mantık, karşılaştırma ve G/Ç işlemlerinin ana yazmacı. |
| **`X`** | 8-Bit | **1. İndeks Yazmacı** | Döngü sayacı, `[a + X]` indeksleme ve `KOPYALA`/`DOLDUR` sıfır sayfa taban indeksi. |
| **`Y`** | 8-Bit | **2. İndeks Yazmacı** | `[a + Y]`, `[[a] + Y]` dolaylı indeksleme ve blok işlem uzunluğu. |
| **`YG`** | 8-Bit | **Yığın Göstergesi (SP)** | `0x0100 - 0x01FF` donanım yığınında sıradaki boş adresi tutar (`0xFF`'ten aşağı büyür). |
| **`PS`** | 16-Bit | **Program Sayacı (PC)** | Sıradaki çalıştırılacak komutun 16-bit bellek adresi. |
| **`DURUM`** | 8-Bit | **Durum Bayrakları** | `E` (Elde/Bit 0), `S` (Sıfır/Bit 1), `K` (Kesme Engeli/Bit 2), `N` (Negatif/Bit 6), `T` (Taşma/Bit 7). |

---

## 2. 64 KB Bellek Haritası (`0x0000 - 0xFFFF`)

| Adres Aralığı | Boyut | Bölge | Açıklama |
| :--- | :---: | :--- | :--- |
| `0x0000 - 0x00CF` | 208 B | **Kullanıcı Sıfır Sayfa** | Hızlı erişimli işaretçi ve geçici değişken alanı (`0x0080–0x00BF`: satır tamponu). |
| `0x00D0 - 0x00FF` | 48 B | **BIOS Sıfır Sayfa** | İmleç, uptime sayacı, kabuk, monitör ve dahili derleyici durum değişkenleri. |
| `0x0100 - 0x01FF` | 256 B | **Donanım Yığını** | `İT`, `ÇEK`, `ÇAĞIR`, `DÖN` komutlarının kullandığı LIFO yığını. |
| `0x0200 - 0x17FF` | 5.5 KB | **Program RAM Alanı** | Diskten yüklenen ikili programlar (`MERHABA`, `PONG`, `BASIC` yorumlayıcısı) buraya yerleşir. |
| `0x1800 - 0x5FFF` | 18 KB | **BASIC / Genel RAM** | Türkçe BASIC kullanıcı programları (`0x1800–0x6FFF` arası toplam 22 KB) için serbest alan. |
| `0x6000 - 0x77FF` | 6 KB | **Kaynak Tamponu** | `DÜZENLE` ve `DERLE` komutlarının kullandığı metin kaynak tamponu. |
| `0x7800 - 0x7FFF` | 2 KB | **Sembol Tablosu** | 2 geçişli dahili `DERLE` assembler'ının etiket/sabit tablosu (64 sembol $\\times$ 16 bayt). |
| `0x8000 - 0x83E7` | 1000 B | **VRAM Ekran Belleği** | 40 sütun $\\times$ 25 satır yeşil fosforlu CRT ekran (`0x8000 + satır*40 + sütun`). |
| `0xA000 - 0xA0FF` | 256 B | **MMIO Donanım Portları** | Klavye FIFO, zamanlayıcı, ses, RNG, DMA disk ve test çıkış portları. |
| `0xC000 - 0xFFFF` | 16 KB | **Sistem ROM (BIOS)** | Yazma korumalı sistem yazılımı ve donanım vektörleri (`0xFFFA`, `0xFFFC`, `0xFFFE`). |

---

## 3. MMIO Donanım Portları (`0xA000 - 0xA0FF`)

| Adres | Port Adı | Yön | Açıklama |
| :---: | :--- | :---: | :--- |
| `0xA000` | `PORT_KLAVYE_VERI` | Oku | 16 baytlık klavye FIFO kuyruğundan sıradaki tuşu çeker (kuyruk boşsa `0`). |
| `0xA001` | `PORT_KLAVYE_DURUM` | Oku/Yaz | Bit 0: Tuş hazır (`1`), Bit 1: FIFO taşması (`1`). Yazıldığında taşma bayrağını temizler. |
| `0xA002` | `PORT_ZAMANLAYICI` | Oku | 50 Hz (her 20 ms'de +1) donanım zamanlayıcı sayacı. |
| `0xA003` | `PORT_SERI_CIKIS` | Yaz | Yazılan baytı doğrudan ana bilgisayar terminaline (`stdout`) gönderir. |
| `0xA004` | `PORT_SES_FREKANS` | Oku/Yaz | Ses üreteci frekans değeri (`1..255`). |
| `0xA005` | `PORT_SES_SURE` | Oku/Yaz | Ses süresi (tik); sıfırdan farklı bir değer yazıldığında sesi tetikler. |
| `0xA006` | `PORT_RASTGELE` | Oku/Yaz | 16-bit LFSR donanım rastgele sayı üreteci (yazıldığında tohum/seed güncellenir). |
| `0xA010` | `PORT_DISK_KOMUT` | Yaz | `1`: Sektör Oku, `2`: Sektör Yaz, `3`: Disk Bilgi. |
| `0xA011` | `PORT_DISK_DURUM` | Oku | `0x00`: Başarılı / Hazır, `0xFF`: Hata oluştu. |
| `0xA012` | `PORT_DISK_SEKTOR` | Oku/Yaz | Başlangıç sektör numarası (`0..255`). |
| `0xA013` | `PORT_DISK_ADRES_ALT` | Oku/Yaz | DMA RAM adresi alt baytı. |
| `0xA014` | `PORT_DISK_ADRES_UST` | Oku/Yaz | DMA RAM adresi üst baytı. |
| `0xA015` | `PORT_DISK_SAYI` | Oku/Yaz | Aktarılacak sektör sayısı (`1` sektör = 256 bayt). |
| `0xA016` | `PORT_DISK_HATA` | Oku | Hata kodu (`0`: Yok, `1`: Dosya yok, `2`: Sektör sınır dışı, `3`: RAM sınır dışı, `4`: G/Ç). |
| `0xA0FF` | `PORT_TEST_SONUC` | Yaz | Başsız (`--test`) kipte emülatörü sonlandırır (`1` = Başarılı, diğerleri = Hata). |

---

## 4. 8-Bit Tek Baytlık Türkçe Karakter Seti (ISO-8859-9)

| Harf | Hex | Onluk | Harf | Hex | Onluk |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **`Ç`** | `0xC7` | 199 | **`ç`** | `0xE7` | 231 |
| **`Ğ`** | `0xD0` | 208 | **`ğ`** | `0xF0` | 240 |
| **`İ`** | `0xDD` | 221 | **`ı`** | `0xFD` | 253 |
| **`Ö`** | `0xD6` | 214 | **`ö`** | `0xF6` | 246 |
| **`Ş`** | `0xDE` | 222 | **`ş`** | `0xFE` | 254 |
| **`Ü`** | `0xDC` | 220 | **`ü`** | `0xFC` | 252 |
""",
        "Architecture-and-Memory-Map.md": """# 🏛️ Processor Architecture, 64 KB Memory Map & Hardware

> 🇹🇷 **Türkçe Sürüm:** [Mimari ve 64 KB Bellek Haritası](Mimari-ve-Bellek-Haritasi)

## 1. CPU Registers

| Register | Width | Name | Role |
| :---: | :---: | :--- | :--- |
| **`T`** | 8-Bit | **Accumulator (Toplaç)** | Primary register for all arithmetic, logic, comparisons, and I/O. |
| **`X`** | 8-Bit | **1st Index Register** | Loop counter, `[a + X]` indexing, and zero-page base index for `KOPYALA`/`DOLDUR`. |
| **`Y`** | 8-Bit | **2nd Index Register** | `[a + Y]`, `[[a] + Y]` indirect indexing, and byte count for block operations. |
| **`YG`** | 8-Bit | **Stack Pointer (SP)** | Points to the next free byte in hardware stack `0x0100 - 0x01FF` (grows downward from `0xFF`). |
| **`PS`** | 16-Bit | **Program Counter (PC)** | Holds the 16-bit memory address of the next instruction to execute. |
| **`DURUM`** | 8-Bit | **Status Flags** | `E` (Carry/Bit 0), `S` (Zero/Bit 1), `K` (IRQ Disable/Bit 2), `N` (Negative/Bit 6), `T` (Overflow/Bit 7). |

---

## 2. 64 KB Memory Map (`0x0000 - 0xFFFF`)

| Address Range | Size | Region | Description |
| :--- | :---: | :--- | :--- |
| `0x0000 - 0x00CF` | 208 B | **User Zero Page** | Fast-access pointers and scratch variables (`0x0080–0x00BF`: line input buffer). |
| `0x00D0 - 0x00FF` | 48 B | **BIOS Zero Page** | Cursor coordinates, 24-bit uptime counter, shell, monitor, and assembler state. |
| `0x0100 - 0x01FF` | 256 B | **Hardware Stack** | LIFO stack used by `İT`, `ÇEK`, `ÇAĞIR`, `DÖN`, and hardware interrupts. |
| `0x0200 - 0x17FF` | 5.5 KB | **Program RAM** | Binary programs loaded from disk (`MERHABA`, `PONG`, `BASIC` interpreter). |
| `0x1800 - 0x5FFF` | 18 KB | **BASIC / User RAM** | Free space for user BASIC programs (`0x1800–0x6FFF` provides 22 KB total). |
| `0x6000 - 0x77FF` | 6 KB | **Source Buffer** | Text source buffer used by the built-in `DÜZENLE` editor and `DERLE` assembler. |
| `0x7800 - 0x7FFF` | 2 KB | **Symbol Table** | Symbol table for the two-pass on-machine `DERLE` assembler (64 symbols $\\times$ 16 bytes). |
| `0x8000 - 0x83E7` | 1000 B | **VRAM Screen Buffer** | 40 columns $\\times$ 25 rows green phosphor CRT screen (`0x8000 + row*40 + col`). |
| `0xA000 - 0xA0FF` | 256 B | **MMIO Hardware Ports** | Keyboard FIFO, 50 Hz timer, sound, LFSR RNG, DMA disk controller, and test port. |
| `0xC000 - 0xFFFF` | 16 KB | **System ROM (BIOS)** | Write-protected firmware and hardware vectors (`0xFFFA`, `0xFFFC`, `0xFFFE`). |

---

## 3. MMIO Hardware Ports (`0xA000 - 0xA0FF`)

| Address | Port Name | R/W | Description |
| :---: | :--- | :---: | :--- |
| `0xA000` | `PORT_KLAVYE_VERI` | R | Dequeues the next key byte from the 16-byte keyboard FIFO (`0` if empty). |
| `0xA001` | `PORT_KLAVYE_DURUM` | R/W | Bit 0: Key ready (`1`), Bit 1: FIFO overflow (`1`). Writing clears overflow flag. |
| `0xA002` | `PORT_ZAMANLAYICI` | R | 50 Hz (increments every 20 ms) hardware timer tick counter. |
| `0xA003` | `PORT_SERI_CIKIS` | W | Streams written byte directly to the host terminal (`stdout`). |
| `0xA004` | `PORT_SES_FREKANS` | R/W | Sound generator frequency (`1..255`). |
| `0xA005` | `PORT_SES_SURE` | R/W | Sound duration (ticks); writing a non-zero value triggers the tone. |
| `0xA006` | `PORT_RASTGELE` | R/W | 16-bit LFSR hardware random number generator (writing re-seeds the LFSR). |
| `0xA010` | `PORT_DISK_KOMUT` | W | `1`: Read Sectors, `2`: Write Sectors, `3`: Query Disk Status. |
| `0xA011` | `PORT_DISK_DURUM` | R | `0x00`: Success / Ready, `0xFF`: Error occurred. |
| `0xA012` | `PORT_DISK_SEKTOR` | R/W | Starting sector number (`0..255`). |
| `0xA013` | `PORT_DISK_ADRES_ALT` | R/W | DMA RAM address low byte. |
| `0xA014` | `PORT_DISK_ADRES_UST` | R/W | DMA RAM address high byte. |
| `0xA015` | `PORT_DISK_SAYI` | R/W | Number of sectors to transfer (`1` sector = 256 bytes). |
| `0xA016` | `PORT_DISK_HATA` | R | Error code (`0`: None, `1`: No disk, `2`: Bad sector, `3`: RAM bounds, `4`: I/O). |
| `0xA0FF` | `PORT_TEST_SONUC` | W | Terminates emulator in `--test` mode (`1` = Pass, other = Fail). |

---

## 4. Single-Byte 8-Bit Turkish Character Set (ISO-8859-9)

| Letter | Hex | Dec | Letter | Hex | Dec |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **`Ç`** | `0xC7` | 199 | **`ç`** | `0xE7` | 231 |
| **`Ğ`** | `0xD0` | 208 | **`ğ`** | `0xF0` | 240 |
| **`İ`** | `0xDD` | 221 | **`ı`** | `0xFD` | 253 |
| **`Ö`** | `0xD6` | 214 | **`ö`** | `0xF6` | 246 |
| **`Ş`** | `0xDE` | 222 | **`ş`** | `0xFE` | 254 |
| **`Ü`** | `0xDC` | 220 | **`ü`** | `0xFC` | 252 |
""",
        "Komut-Seti-Referansi-ISA-v1.md": f"""# 🧠 Komut Seti Referansı — ISA v1.0 (91 Komut)

> 🌍 **English Version:** [Instruction Set Reference (ISA v1.0 — 91 Opcodes)](Instruction-Set-Reference-ISA-v1)

Bu sayfa doğrudan [`araclar/isa.py`](https://github.com/Yukselcsgn/TURK-8/blob/main/araclar/isa.py) içindeki tek kaynaklı komut tablosundan otomatik üretilmiştir.

- `{{n}}`: 8-bitlik sabit sayı veya port işleneni (1 bayt)
- `{{a}}`: 16-bitlik bellek adresi veya etiket (2 bayt, küçük uçlu / little-endian)

---

{tablo_tr}
""",
        "Instruction-Set-Reference-ISA-v1.md": f"""# 🧠 Instruction Set Reference — ISA v1.0 (91 Opcodes)

> 🇹🇷 **Türkçe Sürüm:** [Komut Seti Referansı (ISA v1.0 — 91 Komut)](Komut-Seti-Referansi-ISA-v1)

This page is automatically generated from the single-source instruction table in [`araclar/isa.py`](https://github.com/Yukselcsgn/TURK-8/blob/main/araclar/isa.py).

- `{{n}}`: 8-bit immediate value or port number (1 byte)
- `{{a}}`: 16-bit memory address or label (2 bytes, little-endian)

---

{tablo_en}
""",
        "BIOS-ve-Kabuk-Komutlari.md": """# 🖥️ BIOS ROM (`0xC000`) ve Yerleşik Kabuk Komutları

> 🌍 **English Version:** [BIOS ROM & Built-in Shell Commands](BIOS-and-Shell-Commands)

## 1. Açılış Süreci (POST & Reset)

İşlemci sıfırlandığında `0xFFFC` Sıfırlama Vektöründen `bios_sifirlama` (`0xC000`) adresine zıplar:
1. Yığın göstergesi `YG = 0xFF` yapılır, sıfır sayfa çalışma alanı (`0x00D0–0x00FF`) temizlenir.
2. **Tahribatsız RAM Testi (POST):** `0x0200` ile `0x7FFF` arasındaki 31 KB RAM, her sayfanın mevcut baytı korunarak `0x55` ve `0xAA` desenleriyle sınanır.
3. Ekran temizlenir, başlangıç melodisi çalınır, 50 Hz kesmeler (`KESME AÇ`) etkinleştirilir ve `> ` komut istemi ekrana basılır.

---

## 2. BIOS Sistem Çağrıları (`<n> SİSTEM` — `0xFFFA`)

Kullanıcı programları donanımla doğrudan uğraşmak yerine `<n> SİSTEM` komutuyla BIOS servislerini çağırabilir:

| Servis No | Kullanım | Girdi | Çıktı / Açıklama |
| :---: | :--- | :--- | :--- |
| **`0`** | `0 SİSTEM` | — | Ekranı temizler, imleci sol üste `(0, 0)` taşır. |
| **`1`** | `1 SİSTEM` | `T` = Karakter | `T`'deki karakteri imleç konumuna yazar (`\\n`, `\\b` ve otomatik kaydırma destekli). |
| **`2`** | `2 SİSTEM` | `X` = Alt, `Y` = Üst adres | `Y:X` adresindeki sıfır (`0`) sonlandırmalı metni ekrana basar. |
| **`3`** | `3 SİSTEM` | — | Beklemesiz klavye okuma: tuş varsa `T` = tuş (`S=0`), yoksa `T=0` (`S=1`). |
| **`4`** | `4 SİSTEM` | — | Beklemeli klavye okuma: tuş basılana kadar bekler ve `T` içinde döndürür. |
| **`5`** | `5 SİSTEM` | — | Klavyeden `Enter`'a kadar satır okur (`0x0080` tamponuna yazar, `T` = uzunluk). |
| **`6`** | `6 SİSTEM` | — | VRAM ekranını 1 satır yukarı kaydırır. |
| **`7`** | `7 SİSTEM` | `X` = Frekans, `Y` = Süre | Belirtilen frekans ve sürede ses çalar. |
| **`8`** | `8 SİSTEM` | — | 24-bit 50 Hz çalışma süresi sayacını döndürür (`T` = alt, `X` = orta, `Y` = üst bayt). |

---

## 3. Yerleşik Kabuk Komutları (`> `)

Kabuk komutları büyük/küçük harf ve Türkçe karakter duyarsızdır (`ÇALIŞTIR` ile `calistir` aynıdır) ve hem **doğal Türkçe SOV** (`PONG ÇALIŞTIR`) hem de **klasik SVO** (`ÇALIŞTIR PONG`) sırasını destekler:

- **`YARDIM`**: Tüm kabuk komutlarını listeler.
- **`TEMİZLE`**: Ekranı temizler.
- **`BİLGİ`**: Sistem donanım ve bellek bilgisini görüntüler.
- **`SÜRE`**: 50 Hz çalışma süresi sayacını 24-bit onaltılık olarak basar.
- **`[adres] BELLEK`**: Belirtilen adresten (varsayılan `0x0200`) itibaren 64 baytı hex ve ASCII olarak döker.
- **`<AD | adres> ÇALIŞTIR`**: Diskteki programı yükleyip çalıştırır veya verilen hex adrese `ÇAĞIR` ile dallanır.
- **`BASIC`**: Türkçe BASIC v1.0 yorumlayıcısını diskten yükleyip başlatır.
""",
        "BIOS-and-Shell-Commands.md": """# 🖥️ BIOS ROM (`0xC000`) & Built-in Shell Commands

> 🇹🇷 **Türkçe Sürüm:** [BIOS ROM ve Yerleşik Kabuk Komutları](BIOS-ve-Kabuk-Komutlari)

## 1. Power-On Self-Test (POST) & Reset Sequence

Upon power-on or reset, the CPU reads the 16-bit Reset Vector at `0xFFFC` and jumps to `bios_sifirlama` (`0xC000`):
1. Initializes the hardware stack pointer `YG = 0xFF` and clears the BIOS zero-page workspace (`0x00D0–0x00FF`).
2. **Non-Destructive RAM POST:** Tests all 31 KB of user RAM (`0x0200–0x7FFF`) page-by-page using `0x55` and `0xAA` bit patterns while preserving existing bytes.
3. Clears VRAM, plays the startup chime, enables the 50 Hz timer interrupt (`KESME AÇ`), and displays the interactive `> ` shell prompt.

---

## 2. BIOS System Calls (`<n> SİSTEM` — `0xFFFA`)

User programs can invoke hardware-independent BIOS services via the `<n> SİSTEM` instruction:

| Service # | Syntax | Input Registers | Output / Behavior |
| :---: | :--- | :--- | :--- |
| **`0`** | `0 SİSTEM` | — | Clear VRAM screen and home cursor to `(0, 0)`. |
| **`1`** | `1 SİSTEM` | `T` = Character | Print character `T` at cursor (handles `\\n`, `\\b`, and automatic scrolling). |
| **`2`** | `2 SİSTEM` | `X` = Low, `Y` = High addr | Print null-terminated (`0`) string at `Y:X`. |
| **`3`** | `3 SİSTEM` | — | Non-blocking key read: if key ready `T` = key (`S=0`), else `T=0` (`S=1`). |
| **`4`** | `4 SİSTEM` | — | Blocking key read: waits for a key press and returns it in `T`. |
| **`5`** | `5 SİSTEM` | — | Read a line from keyboard into `0x0080` buffer until `Enter` (`T` = length). |
| **`6`** | `6 SİSTEM` | — | Scroll the 40x25 VRAM screen up by 1 row. |
| **`7`** | `7 SİSTEM` | `X` = Freq, `Y` = Duration | Play tone with given frequency and duration. |
| **`8`** | `8 SİSTEM` | — | Return 24-bit 50 Hz uptime tick counter (`T` = low, `X` = mid, `Y` = high). |

---

## 3. Built-in Shell Commands (`> `)

All shell commands are case-insensitive and Turkish-diacritic-insensitive (`ÇALIŞTIR` and `calistir` are identical) and support both **natural Turkish SOV** (`PONG ÇALIŞTIR`) and **classic SVO** (`ÇALIŞTIR PONG`) word orders:

- **`YARDIM`**: List all available shell, disk, monitor, and assembler commands.
- **`TEMİZLE`**: Clear the screen.
- **`BİLGİ`**: Display hardware, ROM, and RAM summary.
- **`SÜRE`**: Print the 24-bit 50 Hz uptime counter in hexadecimal.
- **`[addr] BELLEK`**: Dump 64 bytes of memory in hex and ASCII (defaults to `0x0200`).
- **`<NAME | addr> ÇALIŞTIR`**: Load and run `<NAME>` from disk, or call hex address `addr`.
- **`BASIC`**: Load and launch the Turkish BASIC v1.0 interpreter from disk.
""",
        "Sanal-Disk-Sistemi.md": """# 💾 Sanal Disk Sistemi (`disk.t8`)

> 🌍 **English Version:** [Virtual Disk System (`disk.t8`)](Virtual-Disk-System)

TÜRK-8, programları ve BASIC kaynaklarını kalıcı olarak saklamak için **64 KB boyutunda, 256 sektörlü (`disk.t8`)** bir sanal disk kullanır.

---

## 1. Disk İmaj Formatı (`disk.t8`)

- **Toplam Boyut:** 65.536 bayt (256 sektör $\\times$ 256 bayt)
- **Sektör 0 (`0x0000 - 0x00FF`):** 16 girişli kök dizin tablosu (her giriş 16 bayt).
- **Sektör 1..255:** Veri sektörleri.

### Dizin Girişi Yapısı (16 Bayt)
| Ofset | Uzunluk | Alan | Açıklama |
| :---: | :---: | :--- | :--- |
| `0x00` | 1 B | `durum` | `0x00` = Boş/Silinmiş, `0x01` = Kullanımda |
| `0x01..0x08` | 8 B | `ad` | Boşluk (`0x20`) dolgulu 8 karakterlik dosya adı (örn. `"PONG    "`) |
| `0x09` | 1 B | `bas_sektor` | Başlangıç sektörü (`1..255`) |
| `0x0A` | 1 B | `sektor_sayisi` | Ayrılan ardışık sektör sayısı |
| `0x0B..0x0C` | 2 B | `yukleme_adresi` | RAM'e yükleneceği 16-bit başlangıç adresi (küçük uçlu, örn. `0x0200`) |
| `0x0D..0x0E` | 2 B | `boyut` | Dosyanın gerçek bayt boyutu (küçük uçlu) |
| `0x0F` | 1 B | `tur` | `0x00` = Makine kodu (`.rom`), `0x01` = Veri / BASIC |

---

## 2. BIOS Kabuğundan Disk Kullanımı

```text
> LİSTE                         ; Diskteki dosyaları ve boyutlarını listeler
> MERHABA YÜKLE                 ; MERHABA dosyasını 0x0200 adresine yükler
> PONG ÇALIŞTIR                 ; PONG dosyasını yükleyip doğrudan çalıştırır
> ORNEK 0300 0020 KAYDET        ; 0x0300 adresinden 0x0020 (32) baytı ORNEK adıyla diske yazar
> ORNEK SİL                     ; ORNEK dosyasını diskten siler
```

---

## 3. Ana Bilgisayardan Disk Yönetimi (`araclar/disk.py`)

```bash
# Disk içeriğini görüntüle
python3 araclar/disk.py liste disk.t8

# Yeni bir .asm veya .rom dosyasını diske ekle
python3 araclar/disk.py ekle disk.t8 OYUN:programlar/pong.asm

# Diskten dosyayı dışarı çıkar
python3 araclar/disk.py cikar disk.t8 OYUN cikti.rom

# Diskten dosyayı sil
python3 araclar/disk.py sil disk.t8 OYUN
```
""",
        "Virtual-Disk-System.md": """# 💾 Virtual Disk System (`disk.t8`)

> 🇹🇷 **Türkçe Sürüm:** [Sanal Disk Sistemi (`disk.t8`)](Sanal-Disk-Sistemi)

TÜRK-8 uses a **64 KB, 256-sector (`disk.t8`)** virtual disk image for persistent storage of machine-code binaries and BASIC programs.

---

## 1. Disk Image Format (`disk.t8`)

- **Total Capacity:** 65,536 bytes (256 sectors $\\times$ 256 bytes)
- **Sector 0 (`0x0000 - 0x00FF`):** 16-entry root directory table (16 bytes per entry).
- **Sectors 1..255:** Contiguous data sectors.

### Directory Entry Layout (16 Bytes)
| Offset | Length | Field | Description |
| :---: | :---: | :--- | :--- |
| `0x00` | 1 B | `status` | `0x00` = Free/Deleted, `0x01` = In Use |
| `0x01..0x08` | 8 B | `name` | Space-padded (`0x20`) 8-byte filename (e.g. `"PONG    "`) |
| `0x09` | 1 B | `start_sector` | First data sector (`1..255`) |
| `0x0A` | 1 B | `sector_count` | Number of contiguous sectors allocated |
| `0x0B..0x0C` | 2 B | `load_address` | 16-bit target RAM address (little-endian, e.g. `0x0200`) |
| `0x0D..0x0E` | 2 B | `size` | Exact file size in bytes (little-endian) |
| `0x0F` | 1 B | `type` | `0x00` = Executable binary (`.rom`), `0x01` = Data / BASIC program |

---

## 2. Managing Files from the BIOS Shell

```text
> LİSTE                         ; List all files and byte sizes on disk.t8
> MERHABA YÜKLE                 ; Load MERHABA into RAM at 0x0200
> PONG ÇALIŞTIR                 ; Load and immediately run PONG
> ORNEK 0300 0020 KAYDET        ; Save 0x0020 (32) bytes from 0x0300 to disk as ORNEK
> ORNEK SİL                     ; Delete ORNEK from disk
```

---

## 3. Host Disk Utility (`araclar/disk.py`)

```bash
# List directory contents
python3 araclar/disk.py liste disk.t8

# Add an .asm or .rom file to disk.t8
python3 araclar/disk.py ekle disk.t8 OYUN:programlar/pong.asm

# Extract a file from disk.t8 to host
python3 araclar/disk.py cikar disk.t8 OYUN out.rom

# Delete a file from disk.t8
python3 araclar/disk.py sil disk.t8 OYUN
```
""",
        "Makine-Ici-Monitor-ve-Assembler.md": """# 🛠️ Makine İçi Monitör, Satır Assembler (`KODLA`) ve Etiketli Derleyici (`DERLE`)

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
""",
        "On-Machine-Monitor-and-Assembler.md": """# 🛠️ On-Machine Monitor, Line Assembler (`KODLA`) & Label Assembler (`DERLE`)

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
""",
        "Turkce-BASIC-Kilavuzu.md": """# 🚀 Türkçe BASIC v1.0 Kılavuzu

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
""",
        "Turkish-BASIC-Guide.md": """# 🚀 Turkish BASIC v1.0 Guide

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
""",
        "English-Reference.md": f"""# 🌍 TÜRK-8 v1.0 — English Technical Reference

> 🇹🇷 **Türkçe Ana Sayfa:** [Home](Home)

**TÜRK-8** is a complete 8-bit personal computer architecture and emulator featuring native **Turkish Subject-Object-Verb (SOV / Postfix)** syntax across its 91-opcode CPU instruction set, 16 KB BIOS ROM, 64 KB virtual disk (`disk.t8`), self-hosted monitor/assembler, and Turkish BASIC v1.0 interpreter.

---

## 1. Detailed English Wiki Chapters

- **[Architecture & 64 KB Memory Map](Architecture-and-Memory-Map)**
- **[Instruction Set Reference (ISA v1.0 — 91 Opcodes)](Instruction-Set-Reference-ISA-v1)**
- **[BIOS ROM & Built-in Shell Commands](BIOS-and-Shell-Commands)**
- **[Virtual Disk System (`disk.t8`)](Virtual-Disk-System)**
- **[On-Machine Monitor, Line Assembler (`KODLA`) & Label Assembler (`DERLE`)](On-Machine-Monitor-and-Assembler)**
- **[Turkish BASIC v1.0 Guide](Turkish-BASIC-Guide)**

---

## 2. Quick Start

```bash
make            # Build ./turk8, assemble roms/bios.rom, and create disk.t8
./turk8         # Boot directly into the BIOS shell (> )
make test       # Run the 55+ automated test suite
```

---

## 3. Complete ISA v1.0 Table (91 Opcodes)

{tablo_en}
""",
    }

    for dosya_adi, icerik in sayfalar.items():
        with open(os.path.join(wiki_dizin, dosya_adi), "w", encoding="utf-8") as f:
            f.write(icerik)


def ana():
    tablo_tr = isa_tablosu_uret_tr()
    tablo_en = isa_tablosu_uret_en()

    with open(os.path.join(KOK_DIZIN, "KULLANIM_KILAVUZU.md"), "w", encoding="utf-8") as f:
        f.write(kullanim_kilavuzu_uret(tablo_tr))

    with open(os.path.join(KOK_DIZIN, "USER_MANUAL.md"), "w", encoding="utf-8") as f:
        f.write(user_manual_uret(tablo_en))

    wiki_sayfalarini_uret(tablo_tr, tablo_en)
    print(f"[BELGE] KULLANIM_KILAVUZU.md, USER_MANUAL.md ve wiki/ ({len(KOMUTLAR)} opkod) güncellendi.")


if __name__ == "__main__":
    ana()
