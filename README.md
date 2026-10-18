# 🇹🇷 TÜRK-8: 8-Bit Virtual Computer Architecture & Emulator

> 🇹🇷 **Türkçe Dokümantasyon:** Türkçe anlatım için [OKUBENI.md](OKUBENI.md) ve kapsamlı kılavuz için [KULLANIM_KILAVUZU.md](KULLANIM_KILAVUZU.md) belgelerine göz atabilirsiniz.  
> 📖 **Comprehensive Manual:** For the detailed instruction set and coding tutorial in English, see [USER_MANUAL.md](USER_MANUAL.md).

---

**TÜRK-8** is a full-featured, educational 8-bit microcomputer architecture, two-pass assembler, and virtual machine emulator. Designed around the mathematical and agglutinative nature of the Turkish language, it follows a strict **Subject/Object $\rightarrow$ Verb (Postfix / SOV)** grammatical structure with a flat 64 KB address space.

---

## 🏛️ Architecture Overview

- **Data Bus:** 8-Bit (values $0$ – $255$)
- **Address Bus:** 16-Bit (Full **64 KB** memory address space: `0x0000` – `0xFFFF`)
- **Registers:**
  - **`T` (Accumulator / Toplaç):** Primary 8-bit register for all arithmetic, logic, and data transfers.
  - **`X` (1st Index Register):** 8-bit register for counters, loops, and array indexing.
  - **`Y` (2nd Index Register):** 8-bit secondary index register for nested loops and lookup tables.
  - **`YG` (Stack Pointer / Yığın Göstergesi):** 8-bit pointer managing hardware stack page (`0x0100` – `0x01FF`).
  - **`PS` (Program Counter / Program Sayacı):** 16-bit register holding the address of the next instruction.
  - **`DURUM` (Status Flags):** `E` (Carry), `S` (Zero), `K` (Interrupt Disable), `N` (Negative), `T` (Overflow).

---

## 🗺️ 64 KB Memory Map

| Address Range | Region | Description |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | **Zero Page** | Fast-access 256-byte scratchpad RAM |
| `0x0100 - 0x01FF` | **Hardware Stack** | 256-byte LIFO stack managed by `YG` (Stack Pointer) |
| `0x0200 - 0x7FFF` | **User RAM** | Program code and variable storage (31.5 KB) |
| `0x8000 - 0x83E7` | **VRAM (Video RAM)** | 40 columns $\times$ 25 rows (1000 characters) memory-mapped CRT screen |
| `0xA000 - 0xA0FF` | **Memory-Mapped I/O (MMIO)**| Keyboard data, key status, hardware timer, terminal output |
| `0xC000 - 0xFFFF` | **System ROM / BIOS** | 16 KB read-only permanent system firmware |
| `0xFFFC - 0xFFFD` | **Reset Vector** | Power-on / reset entry point for the CPU |
| `0xFFFE - 0xFFFF` | **Interrupt Vector (IRQ)** | Hardware interrupt service routine address |

---

## 🇹🇷 Natural Turkish Syntax (SOV / Postfix)

Unlike traditional assembly languages where the action verb comes first (`LOAD 5`, `JUMP loop`), TÜRK-8 follows natural Turkish grammar where **arguments and operands precede the verb (action is at the end)**:

```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    0 X YÜKLE                  ; Load 0 into X (X = 0)
dongu:
    [mesaj + X] T YÜKLE        ; Load character at mesaj[X] into Accumulator T
    0 KARŞILAŞTIR              ; Compare with 0 (null terminator?)
    bitti EŞİTSE ATLA          ; Jump to 'bitti' if Equal (Zero flag = 1)

    T [0x8000 + X] SAKLA       ; Store character to VRAM screen at (0x8000 + X)
    3 ÇIKIŞ                    ; Output byte to Port 3 (Terminal stdout)
    X ARTIR                    ; Increment X (X++)
    dongu ATLA                 ; Jump back to 'dongu'

bitti:
    DUR                        ; Halt the processor

mesaj:
    .METİN "MERHABA DUNYA! TURK-8 CALISIYOR."
    .BAYT 0
```

---

## 🛠️ Building & Running

### 1. Build the Virtual Machine (C11)
```bash
make
```

### 2. Assemble Turkish Assembly to Binary ROM
```bash
python3 araclar/derleyici.py programlar/kabuk.asm programlar/kabuk.rom
```

### 3. Run
```bash
# 1. PLAY THE RETRO PING PONG (PONG) GAME! (W: Up, S: Down, ESC: Exit)
./turk8 -c programlar/pong.rom

# 2. Real-Time Interactive CRT Shell Mode
./turk8 -c programlar/kabuk.rom

# 3. Batch Execution with Screen & Register Summary
./turk8 -e -y programlar/merhaba.rom

# 4. Interactive Debugger / System Monitor (Step-by-step)
./turk8 -m programlar/merhaba.rom
```

---

## 🔍 Interactive Monitor Commands
When running with `./turk8 -m <program.rom>`:
- `a [n]` : Step execute $n$ instructions
- `k` : Free run until halt or breakpoint
- `d [addr]` : Hex & ASCII memory dump
- `e` : Render 40x25 green phosphor CRT screen
- `y` : Display registers and upcoming disassembled instructions
- `b <addr>` : Set breakpoint at 16-bit address
- `c` : Exit monitor

---

## 🌐 Cross-Platform Compatibility

TÜRK-8 is written in standard C11 and has zero mandatory third-party dependencies:

- **🍎 macOS:** Native support using Clang and POSIX `termios`.
- **🐧 Linux (Ubuntu, Debian, Fedora, Arch, etc.):** Builds out-of-the-box with GCC or Clang (`make`).
- **🪟 Windows (10 / 11):**
  - **WSL & Git Bash:** Works identically to Linux.
  - **Native Windows (CMD / PowerShell):** Supported via built-in `#ifdef _WIN32` Win32 Console API layer (`<windows.h>`, `<conio.h>`, `_kbhit()`, `_getch()`). Compiles natively with MinGW or MSVC to `turk8.exe`.
