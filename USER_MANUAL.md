# 🇹🇷 TÜRK-8 PROGRAMMING & USER MANUAL
### *Complete Technical Reference for the 8-Bit Turkish Computer Architecture*

> 🇹🇷 **Türkçe Kılavuz:** Türkçe kullanım kılavuzu için [KULLANIM_KILAVUZU.md](KULLANIM_KILAVUZU.md) belgesine göz atabilirsiniz.  
> 🏠 **Project Overview:** See [README.md](README.md) or [OKUBENI.md](OKUBENI.md).

---

## 📑 TABLE OF CONTENTS
1. [Introduction & Syntax Philosophy](#1-introduction--syntax-philosophy)
2. [Processor Architecture & Registers](#2-processor-architecture--registers)
3. [64 KB Memory Map & Hardware Addresses](#3-64-kb-memory-map--hardware-addresses)
4. [Complete Instruction Set Reference (46 Opcodes)](#4-complete-instruction-set-reference)
5. [Step-by-Step Programming Guide (Lessons)](#5-step-by-step-programming-guide)
6. [Assembling, Running & Debugging](#6-assembling-running--debugging)
7. [Cross-Platform Compatibility](#7-cross-platform-compatibility)

---

## 1. Introduction & Syntax Philosophy

TÜRK-8 is designed in harmony with the agglutinative and mathematical nature of the Turkish language.
In traditional English assembly languages, the action verb comes first (`LOAD 5`, `JUMP loop`);
in **TÜRK-8, the action verb is always placed at the very end of the statement**:

```
[Operands / Source / Destination]  ----->  [ACTION (VERB)]
```

### Comparison:
| Action | Traditional Assembly (English) | TÜRK-8 (Turkish Syntax) | English Literal Meaning |
| :--- | :--- | :--- | :--- |
| Load 5 into Accumulator | `LDA #5` | **`5 T YÜKLE`** | *"5 into T LOAD"* |
| Add 10 to Accumulator | `ADD #10` | **`10 TOPLA`** | *"10 ADD"* |
| Store Accumulator to Screen | `STA $8000` | **`T [0x8000] SAKLA`** | *"T at 0x8000 STORE"* |
| Increment X register | `INX` | **`X ARTIR`** | *"X INCREMENT"* |
| Jump to loop | `JMP loop` | **`dongu ATLA`** | *"loop JUMP"* |
| Jump if Equal | `BEQ done` | **`bitti EŞİTSE ATLA`** | *"done IF-EQUAL JUMP"* |

---

## 2. Processor Architecture & Registers

The CPU features 8-bit data registers and 16-bit address registers:

| Register | Name | Width | Role |
| :---: | :--- | :---: | :--- |
| **`T`** | **Accumulator (Toplaç)** | 8-Bit (0-255) | Central register for all arithmetic, logic, and data operations. |
| **`X`** | **1st Index Register** | 8-Bit (0-255) | Primary index register for counters, loops, and array indexing. |
| **`Y`** | **2nd Index Register** | 8-Bit (0-255) | Secondary index register for nested loops and lookup tables. |
| **`YG`** | **Stack Pointer (SP)** | 8-Bit (0-255) | Hardware stack pointer managing page 1 (`0x0100` – `0x01FF`). |
| **`PS`** | **Program Counter (PC)**| 16-Bit (0-65535)| Holds the 16-bit memory address of the next instruction. |
| **`DURUM`**| **Status Flags Register** | 8-Bit | Reflects the state of the last operation: |

### Status Flags (`DURUM`):
- **`E` (Carry / Elde):** Set to `1` on arithmetic carry (sum $> 255$) or borrow in subtraction.
- **`S` (Zero / Sıfır):** Set to `1` if the result of an operation is zero ($= 0$).
- **`N` (Negative / Negatif):** Set to `1` if the highest bit (bit 7) is 1.
- **`K` (Interrupt Disable / Kesme):** Masks/unmasks hardware interrupts.
- **`T` (Overflow / Taşma):** Set to `1` on signed two's-complement arithmetic overflow.

---

## 3. 64 KB Memory Map & Hardware Addresses

The CPU addresses a flat 64 Kilobyte memory space:

```
0x0000 ┌──────────────────────────────────────────┐
       │ Zero Page RAM (Fast Access) - 256 Bytes  │
0x00FF ├──────────────────────────────────────────┤
0x0100 │ Hardware Stack (Page 1) - 256 Bytes      │ (Managed by YG / Stack Pointer)
0x01FF ├──────────────────────────────────────────┤
0x0200 │                                          │
       │ User RAM (Programs & Data - 31.5 KB)     │ (User programs load here)
       │                                          │
0x7FFF ├──────────────────────────────────────────┤
0x8000 │                                          │
       │ VRAM: CRT Character Buffer (40x25 Cells) │ (Writes display on screen!)
0x83E7 │                                          │
0x83E8 ├──────────────────────────────────────────┤
       │ Expansion / Scratch Area                 │
0x9FFF ├──────────────────────────────────────────┤
0xA000 │ Memory-Mapped I/O (MMIO Ports)           │ (Keyboard, Timer, Serial Console)
0xA0FF ├──────────────────────────────────────────┤
0xC000 │                                          │
       │ System ROM / BIOS Area (16 KB)           │ (Read-only firmware)
0xFFFF └──────────────────────────────────────────┘
```

### Key Hardware Memory Addresses:
- **`0x8000` - `0x83E7` (VRAM):** 40 columns $\times$ 25 rows = 1000 characters.
  - Formula: `0x8000 + (Row * 40) + Column`. Writing an ASCII byte immediately renders that glyph on the CRT monitor.
- **`0xA000` (Keyboard Data):** Returns the ASCII code of the most recent key press.
- **`0xA001` (Keyboard Ready):** Returns `1` if a new key is available, `0` otherwise.
- **`0xA002` (Hardware Timer):** Millisecond tick counter.
- **`0xA003` (Terminal Console Port):** Bytes written here stream to host stdout.

---

## 4. Complete Instruction Set Reference

### A) Data Loading, Storing & Transfer
| Instruction | Syntax | Opcode | Description |
| :--- | :--- | :---: | :--- |
| **`YÜKLE` (Load Imm T)** | `<val> T YÜKLE` | `0x10` | Load immediate 8-bit value into Accumulator `T`. |
| **`YÜKLE` (Load Abs T)** | `[addr] T YÜKLE` | `0x11` | Load byte from 16-bit address into `T`. |
| **`YÜKLE` (Load Idx T)** | `[addr + X] T YÜKLE` | `0x12` | Load byte from `addr + X` into `T` (Array index). |
| **`YÜKLE` (Load Imm X)** | `<val> X YÜKLE` | `0x13` | Load immediate value into X index register. |
| **`YÜKLE` (Load Imm Y)** | `<val> Y YÜKLE` | `0x14` | Load immediate value into Y index register. |
| **`SAKLA` (Store Abs T)**| `T [addr] SAKLA` | `0x15` | Store Accumulator `T` to 16-bit memory address. |
| **`SAKLA` (Store Idx T)**| `T [addr + X] SAKLA` | `0x16` | Store Accumulator `T` to `addr + X`. |
| **`SAKLA` (Store Abs X)**| `X [addr] SAKLA` | `0x17` | Store X index register to memory address. |
| **`SAKLA` (Store Abs Y)**| `Y [addr] SAKLA` | `0x18` | Store Y index register to memory address. |
| **`AKTAR` (Transfer X-T)**| `X T AKTAR` | `0x19` | Copy X into Accumulator `T` (`T = X`). |
| **`AKTAR` (Transfer T-X)**| `T X AKTAR` | `0x1A` | Copy Accumulator `T` into X (`X = T`). |
| **`AKTAR` (Transfer Y-T)**| `Y T AKTAR` | `0x1B` | Copy Y into Accumulator `T` (`T = Y`). |
| **`AKTAR` (Transfer T-Y)**| `T Y AKTAR` | `0x1C` | Copy Accumulator `T` into Y (`Y = T`). |

---

### B) Arithmetic & Comparisons
| Instruction | Syntax | Opcode | Description |
| :--- | :--- | :---: | :--- |
| **`TOPLA` (Add Imm)** | `<val> TOPLA` | `0x30` | Add immediate value to `T` (`T = T + val`). |
| **`TOPLA` (Add Abs)** | `[addr] TOPLA` | `0x31` | Add byte from memory address to `T`. |
| **`ELDEYLE TOPLA` (ADC)**| `<val> ELDEYLE TOPLA`| `0x32` | Add with carry flag: `T = T + val + Carry`. |
| **`ÇIKAR` (Sub Imm)** | `<val> ÇIKAR` | `0x33` | Subtract immediate value from `T` (`T = T - val`). |
| **`ÇIKAR` (Sub Abs)** | `[addr] ÇIKAR` | `0x34` | Subtract byte from memory address from `T`. |
| **`ARTIR` (Inc T)** | `T ARTIR` | `0x35` | Increment Accumulator (`T++`). |
| **`ARTIR` (Inc X)** | `X ARTIR` | `0x36` | Increment X index register (`X++`). |
| **`ARTIR` (Inc Y)** | `Y ARTIR` | `0x37` | Increment Y index register (`Y++`). |
| **`AZALT` (Dec T)** | `T AZALT` | `0x38` | Decrement Accumulator (`T--`). |
| **`AZALT` (Dec X)** | `X AZALT` | `0x39` | Decrement X index register (`X--`). |
| **`AZALT` (Dec Y)** | `Y AZALT` | `0x3A` | Decrement Y index register (`Y--`). |
| **`KARŞILAŞTIR` (Cmp T)**| `<val> KARŞILAŞTIR` | `0x3B` | Compare `T` with immediate value (updates flags). |
| **`KARŞILAŞTIR` (Cmp X)**| `<val> X KARŞILAŞTIR`| `0x3C` | Compare X with immediate value (loop condition). |

---

### C) Logic & Bit Manipulation
| Instruction | Syntax | Opcode | Description |
| :--- | :--- | :---: | :--- |
| **`VE` (Bitwise AND)** | `<val> VE` | `0x50` | Bitwise AND with `T` (`T = T & val`). |
| **`VEYA` (Bitwise OR)** | `<val> VEYA` | `0x51` | Bitwise OR with `T` (`T = T \| val`). |
| **`ÖZELVEYA` (XOR)** | `<val> ÖZELVEYA` | `0x52` | Bitwise XOR with `T` (`T = T ^ val`). |
| **`DEĞİLLE` (NOT)** | `T DEĞİLLE` | `0x53` | Bitwise Invert `T` (`T = ~T`). |
| **`SOLA KAYDIR` (SHL)**| `T SOLA KAYDIR` | `0x54` | Shift left by 1 bit (Multiply by 2). |
| **`SAĞA KAYDIR` (SHR)**| `T SAĞA KAYDIR` | `0x55` | Shift right by 1 bit (Divide by 2). |

---

### D) Control Flow & Conditional Branching
| Instruction | Syntax | Opcode | Description |
| :--- | :--- | :---: | :--- |
| **`ATLA` (Jump Unconditional)** | `<target> ATLA` | `0x70` | Unconditional jump to 16-bit address (`JMP`). |
| **`EŞİTSE ATLA` (BEQ)** | `<target> EŞİTSE ATLA` | `0x71` | Jump if Equal / Zero flag is set (`BEQ`). |
| **`FARKLIYSA ATLA` (BNE)** | `<target> FARKLIYSA ATLA`| `0x72` | Jump if Not Equal / Zero flag is clear (`BNE`). |
| **`BÜYÜKSE ATLA` (BGT)** | `<target> BÜYÜKSE ATLA` | `0x73` | Jump if Greater (Zero = 0 and Negative = 0). |
| **`KÜÇÜKSE ATLA` (BLT)** | `<target> KÜÇÜKSE ATLA` | `0x74` | Jump if Less (Negative = 1). |
| **`ELDE VARSA ATLA` (BCS)** | `<target> ELDE VARSA ATLA`| `0x75` | Jump if Carry flag is set (`BCS`). |

---

### E) Subroutines & Hardware Stack
| Instruction | Syntax | Opcode | Description |
| :--- | :--- | :---: | :--- |
| **`ÇAĞIR` (Call Subroutine)** | `<target> ÇAĞIR` | `0x90` | Push return address to stack, jump to target (`CALL`). |
| **`DÖN` (Return Subroutine)** | `DÖN` | `0x91` | Pop return address from stack and return (`RET`). |
| **`T İT` (Push T)** | `T İT` | `0x93` | Push Accumulator `T` onto stack (`PUSH`). |
| **`T ÇEK` (Pop T)** | `T ÇEK` | `0x94` | Pop byte from stack into Accumulator `T` (`POP`). |
| **`DURUM İT` (Push Flags)**| `DURUM İT` | `0x95` | Push status flags register onto stack. |
| **`DURUM ÇEK` (Pop Flags)**| `DURUM ÇEK` | `0x96` | Pop status flags register from stack. |

---

### F) System & I/O
| Instruction | Syntax | Opcode | Description |
| :--- | :--- | :---: | :--- |
| **`BOŞ` (NOP)** | `BOŞ` | `0x00` | No Operation. Waits for 1 clock cycle. |
| **`DUR` (HALT)** | `DUR` | `0x01` | Halt the CPU. |
| **`GİRİŞ` (Port IN)** | `<port> GİRİŞ` | `0xB0` | Read byte from hardware I/O port into `T`. |
| **`ÇIKIŞ` (Port OUT)** | `<port> ÇIKIŞ` | `0xB1` | Output byte from `T` to hardware I/O port. |

---

## 5. Step-by-Step Programming Guide

### Lesson 1: Arithmetic & Variables
```assembly
.BAŞLANGIÇ 0x0200

    15 T YÜKLE          ; Load 15 into Accumulator T
    25 TOPLA            ; Add 25 (T = 40)
    T [sonuc] SAKLA     ; Store 40 into variable 'sonuc'
    DUR                 ; Halt CPU

sonuc:
    .BAYT 0             ; Reserve 1 byte for storage
```

---

### Lesson 2: Printing a Glyph to Screen (VRAM)
```assembly
.BAŞLANGIÇ 0x0200

    65 T YÜKLE          ; ASCII for 'A' is 65
    T [0x8000] SAKLA    ; Write to top-left cell of VRAM screen
    DUR
```

---

### Lesson 3: Counting Loop (10 down to 1)
```assembly
.BAŞLANGIÇ 0x0200

    10 X YÜKLE          ; X counter = 10

dongu:
    ; Do some work here...
    X AZALT             ; X = X - 1
    0 X KARŞILAŞTIR     ; Is X == 0?
    dongu FARKLIYSA ATLA; Continue loop while not equal to 0

    DUR                 ; Halt when done
```

---

### Lesson 4: Iterating Strings & Screen Display
```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    0 X YÜKLE                  ; Character index X = 0

dongu:
    [mesaj + X] T YÜKLE        ; Load character at mesaj[X]
    0 KARŞILAŞTIR              ; Null terminator check
    bitti EŞİTSE ATLA          ; Exit loop on 0

    T [0x8000 + X] SAKLA       ; Render character to CRT VRAM
    X ARTIR                    ; Next character index
    dongu ATLA                 ; Repeat

bitti:
    DUR

mesaj:
    .METİN "MERHABA TURK-8!"
    .BAYT 0
```

---

### Lesson 5: Writing Subroutines (Functions)
```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    65 T YÜKLE                 ; 'A'
    harf_yaz ÇAĞIR             ; Call subroutine

    66 T YÜKLE                 ; 'B'
    harf_yaz ÇAĞIR             ; Call subroutine again

    DUR

; --- Subroutine ---
harf_yaz:
    T [0x8000 + X] SAKLA       ; Write character to VRAM
    X ARTIR                    ; Advance cursor
    DÖN                        ; Return to caller
```

---

## 6. Assembling, Running & Debugging

### 1. Save your code
Create a new file in `programlar/`, e.g., `programlar/ornek.asm`.

### 2. Assemble to binary ROM
```bash
python3 araclar/derleyici.py programlar/ornek.asm programlar/ornek.rom
```

### 3. Run
```bash
# A) Real-time interactive CRT green monitor (Recommended)
./turk8 -c programlar/ornek.rom

# B) Run and inspect register/screen summary at exit
./turk8 -e -y programlar/ornek.rom

# C) Step-by-step interactive system monitor
./turk8 -m programlar/ornek.rom
```

---

## 7. Cross-Platform Compatibility

- **🍎 macOS:** Compiles natively with Clang (`make`). Terminal raw mode uses standard POSIX `termios`.
- **🐧 Linux (Ubuntu, Debian, Fedora, Arch, etc.):** Builds out-of-the-box with GCC or Clang with zero dependencies.
- **🪟 Windows (10 / 11):**
  - **WSL & Git Bash:** Identical to Linux.
  - **Native Windows Console:** Built-in `#ifdef _WIN32` layer binds directly to Windows Console APIs (`<windows.h>`, `<conio.h>`, `_kbhit()`, `_getch()`). Compiles natively with MinGW or MSVC to `turk8.exe`. Modern Windows Terminal natively renders green phosphor ANSI colors.

Enjoy hacking with TÜRK-8! 🇹🇷💻

