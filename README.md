# 🇹🇷 TÜRK-8: 8-Bit Turkish Personal Computer Architecture & Emulator (v1.0)

> 🇹🇷 **Türkçe Dokümantasyon:** Türkçe anlatım için [OKUBENI.md](OKUBENI.md), kapsamlı kılavuz için [KULLANIM_KILAVUZU.md](KULLANIM_KILAVUZU.md) ve [`wiki/`](wiki/Home.md) sayfalarına göz atabilirsiniz.  
> 📖 **Comprehensive Manual:** For the complete 91-opcode ISA v1.0 reference, BIOS API, On-Machine Assembler, and Turkish BASIC guide in English, see [USER_MANUAL.md](USER_MANUAL.md) and [`wiki/English-Reference.md`](wiki/English-Reference.md).

---

**TÜRK-8** is a complete, standalone 8-bit personal computer architecture, two-pass assembler, virtual disk system, and CRT emulator written in standard C11. Designed around the mathematical and agglutinative nature of the Turkish language, it follows a **Subject/Object $\rightarrow$ Verb (Postfix / SOV)** grammatical structure across its entire stack—from CPU instructions (`5 T YÜKLE`) to its ROM command shell (`PONG ÇALIŞTIR`) and built-in Turkish BASIC interpreter (`"MERHABA" YAZ`).

---

## ✨ Key Highlights (v1.0)

- **🖥️ Turn-Key Boot into BIOS & Shell (`./turk8`):** Running `./turk8` with no arguments boots straight from the 16 KB System BIOS ROM (`0xC000`), runs a non-destructive 31 KB RAM POST check, sounds the startup beep, and drops into the interactive `> ` command shell.
- **🧠 Frozen ISA v1.0 (91 Opcodes):** Full 8-bit CPU instruction set featuring indirect and Y-indexed addressing (`[[a]]`, `[[a] + Y]`), 16-bit multi-byte arithmetic (`ELDEYLE TOPLA`, `BORÇLA ÇIKAR`), hardware block move/fill (`KOPYALA`, `DOLDUR`), hardware BCD extraction (`T RAKAMLARA AYIR`), LFSR random number generation (`RASTGELE`), 50 Hz frame sync (`KARE BEKLE`), and BIOS syscall traps (`{n} SİSTEM`).
- **💾 64 KB Virtual Disk (`disk.t8`):** Memory-mapped DMA disk controller (`0xA010–0xA017`) with a 256-sector, 16-entry flat filesystem. Manage programs directly from the shell via `LİSTE`, `<NAME> YÜKLE`, `<NAME> [addr] [size] KAYDET`, `<NAME> SİL`, and `<NAME> ÇALIŞTIR`, or from the host via `python3 araclar/disk.py`.
- **🛠️ On-Machine Coding (Self-Hosted Toolchain in ROM):**
  - **Woz-Style Hex Monitor:** Enter raw hex bytes with `0300: 10 2A 91` and inspect memory with `0300:`.
  - **Interactive Line Assembler (`[addr] KODLA`):** Assemble all 91 ISA v1.0 mnemonics directly into RAM line by line.
  - **Source Editor & Two-Pass Label Assembler (`DÜZENLE`, `KAYNAK`, `[addr|name] DERLE`):** Write multi-line assembly with labels (`dongu:`), `.TANIM`, `.BAŞLANGIÇ`, `.METİN`, `.BAYT`, `.KELİME`, `.BOŞLUK`, and `<label`/`>label` byte-selection operators right inside the virtual machine and assemble directly to RAM or disk.
- **🚀 Turkish BASIC v1.0 (`BASIC`):** Built-in 3.6 KB BASIC interpreter on disk providing 22 KB of free user program space (`0x1800–0x6FFF`). Supports both natural Turkish SOV order (`"MERHABA" YAZ`, `25 + 17 YAZ`, `10 GİT`, `T GİRDİ`, `I SONRAKİ`, `500 ÇAĞIR`, `OYUN KAYDET`) and classic BASIC order (`YAZ "MERHABA"`, `GİT 10`).
- **🔤 Single-Byte 8-Bit Turkish Character Set (ISO-8859-9):** All Turkish letters (`Ç, ç, Ğ, ğ, İ, ı, Ö, ö, Ş, ş, Ü, ü`) are mapped to single-byte codes (`0xC0–0xFF`) in both RAM and VRAM.

---

## 🏛️ Processor Architecture

- **Data Bus:** 8-Bit ($0$ – $255$)
- **Address Bus:** 16-Bit (Full **64 KB** address space: `0x0000` – `0xFFFF`)
- **Registers:**
  - **`T` (Accumulator / Toplaç):** Primary 8-bit register for arithmetic, logic, and data transfers.
  - **`X` (1st Index Register):** 8-bit register for loops, array indexing, and `KOPYALA`/`DOLDUR` parameters.
  - **`Y` (2nd Index Register):** 8-bit secondary index register for `[[a] + Y]` lookups and block operations.
  - **`YG` (Stack Pointer / Yığın Göstergesi):** 8-bit pointer managing the hardware stack page (`0x0100` – `0x01FF`).
  - **`PS` (Program Counter / Program Sayacı):** 16-bit address of the next instruction.
  - **`DURUM` (Status Flags):** `E` (Carry), `S` (Zero), `K` (Interrupt Disable), `N` (Negative), `T` (Signed Overflow).

---

## 🗺️ 64 KB Memory Map

| Address Range | Region | Description |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | **Zero Page** | Fast-access 256-byte system & user scratchpad RAM |
| `0x0100 - 0x01FF` | **Hardware Stack** | 256-byte LIFO stack managed by `YG` (Stack Pointer) |
| `0x0200 - 0x7FFF` | **User RAM** | User programs, BASIC interpreter, and source editor buffer (31.5 KB) |
| `0x8000 - 0x83E7` | **VRAM (Video RAM)** | 40 columns $\times$ 25 rows (1000 characters) green phosphor CRT screen |
| `0xA000 - 0xA0FF` | **Memory-Mapped I/O (MMIO)**| 16-byte keyboard FIFO, 50 Hz timer, sound, LFSR RNG, DMA disk (`0xA010–0xA017`) |
| `0xC000 - 0xFFFF` | **System ROM / BIOS** | 16 KB read-only firmware: POST, BIOS API, Shell, Monitor, Assembler |
| `0xFFFA - 0xFFFB` | **Syscall Vector** | `<n> SİSTEM` entry address (`0..8` BIOS services) |
| `0xFFFC - 0xFFFD` | **Reset Vector** | Power-on / reset entry point for the CPU |
| `0xFFFE - 0xFFFF` | **Interrupt Vector (IRQ)** | 50 Hz hardware timer interrupt service routine address |

---

## 🛠️ Quick Start (Building & Running)

### 1. Build the Emulator, BIOS ROM & Virtual Disk
```bash
make
```
This compiles `./turk8`, assembles `roms/bios.rom`, and builds the 64 KB `disk.t8` virtual disk preloaded with `MERHABA`, `TOPLAM`, `PONG`, `KABUK`, and `BASIC`.

### 2. Boot the Personal Computer (Recommended)
```bash
./turk8
```
TÜRK-8 boots directly into the BIOS shell (`> `). Try these commands at the prompt:
```text
> YARDIM                ; List all built-in BIOS shell commands
> LİSTE                 ; List files stored on disk.t8
> PONG ÇALIŞTIR         ; Load and play Ping Pong from disk (W/S: Move, Q: Return to BIOS)
> BASIC                 ; Launch Turkish BASIC v1.0 interpreter (Type ÇIK to return)
> 0300 KODLA            ; Start interactive line assembler at 0x0300
> DÜZENLE               ; Open built-in source editor for labeled assembly programs
```

### 3. Run the Automated Test Suite (52+ Tests)
```bash
make test
```

---

## 🚀 Turkish BASIC v1.0 Example

Type `BASIC` at the BIOS `> ` prompt to enter the BASIC environment (`] ` prompt):

```text
> BASIC
TÜRK-8 BASIC v1.0 (22 KB SERBEST)
HAZIR.
] "SELAM TURK-8!" YAZ
SELAM TURK-8!
] 25 + 17 YAZ
42
] 10 DÖNGÜ I = 1 BİTİŞ 5
] 20 "SAYI: ", I, " KARE: ", I * I YAZ
] 30 I SONRAKİ
] 40 BİTİR
] ÇALIŞTIR
SAYI: 1 KARE: 1
SAYI: 2 KARE: 4
SAYI: 3 KARE: 9
SAYI: 4 KARE: 16
SAYI: 5 KARE: 25
] KARE KAYDET
KAYDEDİLDİ.
] ÇIK
>
```

---

## 🌐 Cross-Platform Compatibility

TÜRK-8 is written in portable C11 and Python 3 with zero external library dependencies:

- **🍎 macOS:** Native support using Clang and POSIX `termios` (`make && ./turk8`).
- **🐧 Linux (Ubuntu, Debian, Fedora, Arch, etc.):** Builds out-of-the-box with GCC or Clang (`make && ./turk8`).
- **🪟 Windows (10 / 11):**
  - **WSL & Git Bash:** Works identically to Linux.
  - **Native Windows (CMD / PowerShell):** Supported via the `#ifdef _WIN32` Win32 Console API layer (`<windows.h>`, `<conio.h>`, `_kbhit()`, `_getch()`). Compiles natively with MinGW or MSVC to `turk8.exe`.
