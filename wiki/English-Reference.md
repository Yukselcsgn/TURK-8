# 🌍 TÜRK-8 v1.0 — English Technical Reference

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

| Opcode | C Constant | Syntax Pattern | Size | Description |
| :---: | :--- | :--- | :---: | :--- |
| `0x00` | `KMT_BOS` | `BOŞ` | 1 B | No operation; advances 1 clock cycle (`NOP`). |
| `0x01` | `KMT_DUR` | `DUR` | 1 B | Halt processor execution (`HALT`). |
| `0x02` | `KMT_KESME_AC` | `KESME AÇ` | 1 B | Enable hardware interrupts (`K = 0`). |
| `0x03` | `KMT_KESME_KAPAT` | `KESME KAPAT` | 1 B | Disable hardware interrupts (`K = 1`). |
| `0x04` | `KMT_SIFIRLA` | `SIFIRLA` | 1 B | Clear registers and status flags. |
| `0x05` | `KMT_SISTEM` | `{n} SİSTEM` | 2 B | Invoke BIOS syscall `{n}` via vector `0xFFFA`. |
| `0x06` | `KMT_KARE_BEKLE` | `KARE BEKLE` | 1 B | Suspend CPU until the next 50 Hz frame tick. |
| `0x07` | `KMT_RASTGELE` | `RASTGELE` | 1 B | Load random byte (`0..255`) from hardware LFSR into `T`. |
| `0x10` | `KMT_YUKLE_SABIT_T` | `{n} T YÜKLE` | 2 B | Load 8-bit immediate `{n}` into Accumulator `T`. |
| `0x11` | `KMT_YUKLE_ADRES_T` | `[{a}] T YÜKLE` | 3 B | Load byte at 16-bit address `{a}` into `T`. |
| `0x12` | `KMT_YUKLE_INDEKS_X_T` | `[{a} + X] T YÜKLE` | 3 B | Load byte at `{a} + X` into `T`. |
| `0x13` | `KMT_YUKLE_SABIT_X` | `{n} X YÜKLE` | 2 B | Load 8-bit immediate `{n}` into index register `X`. |
| `0x14` | `KMT_YUKLE_SABIT_Y` | `{n} Y YÜKLE` | 2 B | Load 8-bit immediate `{n}` into index register `Y`. |
| `0x15` | `KMT_SAKLA_T_ADRES` | `T [{a}] SAKLA` | 3 B | Store `T` to 16-bit memory address `{a}`. |
| `0x16` | `KMT_SAKLA_T_INDEKS_X` | `T [{a} + X] SAKLA` | 3 B | Store `T` to memory address `{a} + X`. |
| `0x17` | `KMT_SAKLA_X_ADRES` | `X [{a}] SAKLA` | 3 B | Store `X` to 16-bit memory address `{a}`. |
| `0x18` | `KMT_SAKLA_Y_ADRES` | `Y [{a}] SAKLA` | 3 B | Store `Y` to 16-bit memory address `{a}`. |
| `0x19` | `KMT_AKTAR_X_T` | `X T AKTAR` | 1 B | Copy `X` into `T` (`T = X`). |
| `0x1A` | `KMT_AKTAR_T_X` | `T X AKTAR` | 1 B | Copy `T` into `X` (`X = T`). |
| `0x1B` | `KMT_AKTAR_Y_T` | `Y T AKTAR` | 1 B | Copy `Y` into `T` (`T = Y`). |
| `0x1C` | `KMT_AKTAR_T_Y` | `T Y AKTAR` | 1 B | Copy `T` into `Y` (`Y = T`). |
| `0x1D` | `KMT_YUKLE_DOLAYLI_T` | `[[{a}]] T YÜKLE` | 3 B | Indirect load: read 16-bit pointer at `{a}`, load byte from that address into `T`. |
| `0x1E` | `KMT_SAKLA_T_DOLAYLI` | `T [[{a}]] SAKLA` | 3 B | Indirect store: store `T` to the 16-bit address stored at `{a}`. |
| `0x20` | `KMT_YUKLE_ADRES_X` | `[{a}] X YÜKLE` | 3 B | Load byte at `{a}` into `X`. |
| `0x21` | `KMT_YUKLE_ADRES_Y` | `[{a}] Y YÜKLE` | 3 B | Load byte at `{a}` into `Y`. |
| `0x22` | `KMT_YUKLE_INDEKS_Y_T` | `[{a} + Y] T YÜKLE` | 3 B | Load byte at `{a} + Y` into `T`. |
| `0x23` | `KMT_SAKLA_T_INDEKS_Y` | `T [{a} + Y] SAKLA` | 3 B | Store `T` to memory address `{a} + Y`. |
| `0x24` | `KMT_YUKLE_DOLAYLI_Y_T` | `[[{a}] + Y] T YÜKLE` | 3 B | Indirect Y-indexed load: read pointer at `{a}`, load byte at `ptr + Y` into `T`. |
| `0x25` | `KMT_SAKLA_T_DOLAYLI_Y` | `T [[{a}] + Y] SAKLA` | 3 B | Indirect Y-indexed store: read pointer at `{a}`, store `T` to `ptr + Y`. |
| `0x26` | `KMT_AKTAR_YG_T` | `YG T AKTAR` | 1 B | Copy stack pointer `YG` into `T`. |
| `0x27` | `KMT_AKTAR_T_YG` | `T YG AKTAR` | 1 B | Copy `T` into stack pointer `YG`. |
| `0x28` | `KMT_KOPYALA` | `KOPYALA` | 1 B | Block copy `Y` bytes from zero-page pointer `[X..X+1]` to `[X+2..X+3]` (overlap-safe). |
| `0x29` | `KMT_DOLDUR` | `DOLDUR` | 1 B | Block fill `Y` bytes starting at zero-page pointer `[X..X+1]` with value `T`. |
| `0x30` | `KMT_TOPLA_SABIT` | `{n} TOPLA` | 2 B | `T = T + {n}` (updates Carry, Zero, Negative, Overflow). |
| `0x31` | `KMT_TOPLA_ADRES` | `[{a}] TOPLA` | 3 B | `T = T + [{a}]` (add memory byte to `T`). |
| `0x32` | `KMT_TOPLA_ELDEYLE` | `{n} ELDEYLE TOPLA` | 2 B | `T = T + {n} + E` (add with carry for multi-byte addition). |
| `0x33` | `KMT_CIKAR_SABIT` | `{n} ÇIKAR` | 2 B | `T = T - {n}` (subtract immediate from `T`). |
| `0x34` | `KMT_CIKAR_ADRES` | `[{a}] ÇIKAR` | 3 B | `T = T - [{a}]` (subtract memory byte from `T`). |
| `0x35` | `KMT_ARTIR_T` | `T ARTIR` | 1 B | Increment `T` (`T++`). |
| `0x36` | `KMT_ARTIR_X` | `X ARTIR` | 1 B | Increment `X` (`X++`). |
| `0x37` | `KMT_ARTIR_Y` | `Y ARTIR` | 1 B | Increment `Y` (`Y++`). |
| `0x38` | `KMT_AZALT_T` | `T AZALT` | 1 B | Decrement `T` (`T--`). |
| `0x39` | `KMT_AZALT_X` | `X AZALT` | 1 B | Decrement `X` (`X--`). |
| `0x3A` | `KMT_AZALT_Y` | `Y AZALT` | 1 B | Decrement `Y` (`Y--`). |
| `0x3B` | `KMT_KARSILASTIR_SABIT` | `{n} KARŞILAŞTIR` | 2 B | Compare `T` with immediate `{n}` (`T - {n}`). |
| `0x3C` | `KMT_KARSILASTIR_X` | `{n} X KARŞILAŞTIR` | 2 B | Compare `X` with immediate `{n}` (`X - {n}`). |
| `0x3D` | `KMT_KARSILASTIR_Y` | `{n} Y KARŞILAŞTIR` | 2 B | Compare `Y` with immediate `{n}` (`Y - {n}`). |
| `0x3E` | `KMT_KARSILASTIR_ADRES` | `[{a}] KARŞILAŞTIR` | 3 B | Compare `T` with memory byte `[{a}]` (`T - [{a}]`). |
| `0x3F` | `KMT_CIKAR_BORCLA` | `{n} BORÇLA ÇIKAR` | 2 B | `T = T - {n} - (1 - E)` (subtract with borrow for 16-bit subtraction). |
| `0x40` | `KMT_ELDE_KUR` | `ELDE KUR` | 1 B | Set Carry flag (`E = 1`). |
| `0x41` | `KMT_ELDE_TEMIZLE` | `ELDE TEMİZLE` | 1 B | Clear Carry flag (`E = 0`). |
| `0x42` | `KMT_ARTIR_ADRES` | `[{a}] ARTIR` | 3 B | Increment byte in memory at `{a}` (`[{a}]++`). |
| `0x43` | `KMT_AZALT_ADRES` | `[{a}] AZALT` | 3 B | Decrement byte in memory at `{a}` (`[{a}]--`). |
| `0x44` | `KMT_RAKAMLARA_AYIR` | `T RAKAMLARA AYIR` | 1 B | Split `T` into decimal digits: hundreds in `Y`, tens in `X`, ones in `T`. |
| `0x50` | `KMT_VE_SABIT` | `{n} VE` | 2 B | `T = T & {n}` (bitwise AND with immediate). |
| `0x51` | `KMT_VEYA_SABIT` | `{n} VEYA` | 2 B | `T = T | {n}` (bitwise OR with immediate). |
| `0x52` | `KMT_OZELVEYA_SABIT` | `{n} ÖZELVEYA` | 2 B | `T = T ^ {n}` (bitwise XOR with immediate). |
| `0x53` | `KMT_DEGILLE_T` | `T DEĞİLLE` | 1 B | `T = ~T` (bitwise NOT). |
| `0x54` | `KMT_KAYDIR_SOLA` | `T SOLA KAYDIR` | 1 B | Logical shift left `T` by 1 bit (bit 7 -> `E`). |
| `0x55` | `KMT_KAYDIR_SAGA` | `T SAĞA KAYDIR` | 1 B | Logical shift right `T` by 1 bit (bit 0 -> `E`). |
| `0x56` | `KMT_DONDUR_SOLA` | `T SOLA DÖNDÜR` | 1 B | Rotate left `T` through Carry (`ROL`). |
| `0x57` | `KMT_DONDUR_SAGA` | `T SAĞA DÖNDÜR` | 1 B | Rotate right `T` through Carry (`ROR`). |
| `0x58` | `KMT_BIT_SINA` | `{n} BİT SINA` | 2 B | Test bits (`T & {n}`); updates Zero flag `S` without modifying `T`. |
| `0x59` | `KMT_VE_ADRES` | `[{a}] VE` | 3 B | `T = T & [{a}]` (bitwise AND with memory byte). |
| `0x5A` | `KMT_VEYA_ADRES` | `[{a}] VEYA` | 3 B | `T = T | [{a}]` (bitwise OR with memory byte). |
| `0x70` | `KMT_ATLA` | `{a} ATLA` | 3 B | Unconditional jump to `{a}` (`PS = {a}`). |
| `0x71` | `KMT_ESITSE_ATLA` | `{a} EŞİTSE ATLA` | 3 B | Jump to `{a}` if Equal (`S == 1`). |
| `0x72` | `KMT_FARKLIYSA_ATLA` | `{a} FARKLIYSA ATLA` | 3 B | Jump to `{a}` if Not Equal (`S == 0`). |
| `0x73` | `KMT_BUYUKSE_ATLA` | `{a} BÜYÜKSE ATLA` | 3 B | Jump to `{a}` if Unsigned Greater (`E == 1` and `S == 0`). |
| `0x74` | `KMT_KUCUKSE_ATLA` | `{a} KÜÇÜKSE ATLA` | 3 B | Jump to `{a}` if Unsigned Less (`E == 0`). |
| `0x75` | `KMT_ELDE_VARSA_ATLA` | `{a} ELDE VARSA ATLA` | 3 B | Jump to `{a}` if Carry Set / Unsigned Greater or Equal (`E == 1`). |
| `0x76` | `KMT_ELDE_YOKSA_ATLA` | `{a} ELDE YOKSA ATLA` | 3 B | Jump to `{a}` if Carry Clear (`E == 0`). |
| `0x77` | `KMT_NEGATIFSE_ATLA` | `{a} NEGATİFSE ATLA` | 3 B | Jump to `{a}` if Negative (`N == 1`). |
| `0x78` | `KMT_POZITIFSE_ATLA` | `{a} POZİTİFSE ATLA` | 3 B | Jump to `{a}` if Positive or Zero (`N == 0`). |
| `0x79` | `KMT_TASMA_VARSA_ATLA` | `{a} TAŞMA VARSA ATLA` | 3 B | Jump to `{a}` if Signed Overflow (`T == 1`). |
| `0x7A` | `KMT_KUCUK_ESITSE_ATLA` | `{a} KÜÇÜK VEYA EŞİTSE ATLA` | 3 B | Jump to `{a}` if Unsigned Less or Equal (`E == 0` or `S == 1`). |
| `0x7B` | `KMT_ATLA_DOLAYLI` | `[{a}] ATLA` | 3 B | Indirect jump through 16-bit pointer at `{a}` (`PS = [{a}]`). |
| `0x7C` | `KMT_CAGIR_DOLAYLI` | `[{a}] ÇAĞIR` | 3 B | Indirect subroutine call through 16-bit pointer at `{a}`. |
| `0x90` | `KMT_CAGIR` | `{a} ÇAĞIR` | 3 B | Call subroutine at `{a}` (pushes return address onto stack). |
| `0x91` | `KMT_DON` | `DÖN` | 1 B | Return from subroutine (`RET`). |
| `0x92` | `KMT_KESMEDEN_DON` | `KESMEDEN DÖN` | 1 B | Return from interrupt (`RTI`: pops `DURUM` and `PS`). |
| `0x93` | `KMT_IT_T` | `T İT` | 1 B | Push `T` onto hardware stack. |
| `0x94` | `KMT_CEK_T` | `T ÇEK` | 1 B | Pop byte from hardware stack into `T`. |
| `0x95` | `KMT_IT_DURUM` | `DURUM İT` | 1 B | Push `DURUM` status flags onto stack. |
| `0x96` | `KMT_CEK_DURUM` | `DURUM ÇEK` | 1 B | Pop `DURUM` status flags from stack. |
| `0x97` | `KMT_IT_X` | `X İT` | 1 B | Push `X` onto hardware stack. |
| `0x98` | `KMT_CEK_X` | `X ÇEK` | 1 B | Pop byte from hardware stack into `X`. |
| `0x99` | `KMT_IT_Y` | `Y İT` | 1 B | Push `Y` onto hardware stack. |
| `0x9A` | `KMT_CEK_Y` | `Y ÇEK` | 1 B | Pop byte from hardware stack into `Y`. |
| `0xB0` | `KMT_GIRIS` | `{n} GİRİŞ` | 2 B | Read byte from MMIO port `0xA000 + {n}` into `T`. |
| `0xB1` | `KMT_CIKIS` | `{n} ÇIKIŞ` | 2 B | Write `T` to MMIO port `0xA000 + {n}`. |
| `0x75` *(alias)* | `KMT_ELDE_VARSA_ATLA` | `{a} BÜYÜK VEYA EŞİTSE ATLA` | 3 B | Alias for `ELDE VARSA ATLA` (unsigned $\ge$). |
