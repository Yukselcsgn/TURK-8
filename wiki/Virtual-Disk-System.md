# 💾 Virtual Disk System (`disk.t8`)

> 🇹🇷 **Türkçe Sürüm:** [Sanal Disk Sistemi (`disk.t8`)](Sanal-Disk-Sistemi)

TÜRK-8 uses a **64 KB, 256-sector (`disk.t8`)** virtual disk image for persistent storage of machine-code binaries and BASIC programs.

---

## 1. Disk Image Format (`disk.t8`)

- **Total Capacity:** 65,536 bytes (256 sectors $\times$ 256 bytes)
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
