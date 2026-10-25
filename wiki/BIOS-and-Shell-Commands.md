# 🖥️ BIOS ROM (`0xC000`) & Built-in Shell Commands

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
| **`1`** | `1 SİSTEM` | `T` = Character | Print character `T` at cursor (handles `\n`, `\b`, and automatic scrolling). |
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
