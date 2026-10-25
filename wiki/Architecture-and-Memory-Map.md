# 🏛️ Processor Architecture, 64 KB Memory Map & Hardware

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
| `0x7800 - 0x7FFF` | 2 KB | **Symbol Table** | Symbol table for the two-pass on-machine `DERLE` assembler (64 symbols $\times$ 16 bytes). |
| `0x8000 - 0x83E7` | 1000 B | **VRAM Screen Buffer** | 40 columns $\times$ 25 rows green phosphor CRT screen (`0x8000 + row*40 + col`). |
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
