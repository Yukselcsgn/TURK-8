# 🇹🇷 TÜRK-8 Wiki — 8-Bit Türkçe Kişisel Bilgisayar Ansiklopedisi / Encyclopedia

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
