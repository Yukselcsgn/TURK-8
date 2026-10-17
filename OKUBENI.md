# 🇹🇷 TÜRK-8: 8-Bit Tam Teşekküllü Türkçe Bilgisayar Mimarisi ve Sanal Makine

> 🌍 **English Version:** For the English documentation, see [README.md](README.md) and [USER_MANUAL.md](USER_MANUAL.md).  
> 📖 **Detaylı Kılavuz:** Komutların tüm detayları ve kodlama dersleri için [KULLANIM_KILAVUZU.md](KULLANIM_KILAVUZU.md) belgesini inceleyin.

---

TÜRK-8, Türkçenin matematiksel ve sondan eklemeli doğasına uygun olarak geliştirilmiş; **Özne/Nesne $\rightarrow$ Yüklem (Fiil Sonda)** kuralını benimseyen, 64 KB bellek adreslemeli özgün bir 8-bit mikrobilgisayar sistemidir.

---

## 🏛️ Mimari Özellikleri

- **Veri Yolu:** 8-Bit (0 – 255)
- **Adres Yolu:** 16-Bit (Tam **64 KB** adresleme uzayı)
- **Yazmaçlar (Registers):**
  - **`T` (Toplaç / Akümülatör):** Aritmetik ve mantık işlemlerinin ana merkezi (8-bit)
  - **`X` (1. İndeks):** Sayaç ve dizi indeksleme yazmacı (8-bit)
  - **`Y` (2. İndeks):** İkinci sayaç ve tablo yazmacı (8-bit)
  - **`YG` (Yığın Göstergesi / Stack Pointer):** `0x0100 - 0x01FF` alanını yönetir (8-bit)
  - **`PS` (Program Sayacı / PC):** Sıradaki komutun 16-bit bellek adresi
  - **`DURUM` (Durum Bayrakları):** `E` (Elde), `S` (Sıfır), `K` (Kesme), `N` (Negatif), `T` (Taşma)

---

## 🗺️ 64 KB Bellek Haritası

| Adres Aralığı | Bölge Adı | Açıklama |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | **Sıfır Sayfa (Zero Page)** | Hızlı erişimli 256 baytlık RAM |
| `0x0100 - 0x01FF` | **Donanım Yığını (Stack)** | `YG` ile yönetilen 256 baytlık LIFO yığını |
| `0x0200 - 0x7FFF` | **Kullanıcı Belleği (RAM)** | Kullanıcı programları ve değişkenler (31.5 KB) |
| `0x8000 - 0x83E7` | **VRAM Ekran Belleği** | 40 sütun x 25 satır (1000 karakter) doğrudan CRT ekranı |
| `0xA000 - 0xA0FF` | **Giriş / Çıkış (MMIO)** | Klavye tamponu, zamanlayıcı, terminal çıkış portu |
| `0xC000 - 0xFFFF` | **Sistem ROM / BIOS** | Salt okunur kalıcı sistem belleği (16 KB) |
| `0xFFFC - 0xFFFD` | **Sıfırlama Vektörü (RESET)**| İşlemcinin açılışta zıplayacağı adres |
| `0xFFFE - 0xFFFF` | **Kesme Vektörü (IRQ)** | Donanım kesmesi adresi |

---

## 🇹🇷 Doğal Türkçe Söz Dizimi (Syntax)

Türkçe kuralına göre **nesneler/sayılar başta, fiil (yüklem) en sondadır**:

```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    0 X YÜKLE                  ; 0'ı X'e YÜKLE
dongu:
    [mesaj + X] T YÜKLE        ; mesajın X. harfini Toplaca YÜKLE
    0 KARŞILAŞTIR              ; 0 ile KARŞILAŞTIR
    bitti EŞİTSE ATLA          ; Eşitse bitti'ye ATLA

    T [0x8000 + X] SAKLA       ; Harfi ekrana (VRAM) SAKLA
    3 ÇIKIŞ                    ; Terminal portuna bas
    X ARTIR                    ; X sayacını 1 ARTIR
    dongu ATLA                 ; Başa ATLA

bitti:
    DUR                        ; İşlemciyi DURDUR

mesaj:
    .METİN "MERHABA DUNYA! TURK-8 CALISIYOR."
    .BAYT 0
```

---

## 🛠️ Nasıl Derlenir ve Çalıştırılır?

### 1. Sanal Makineyi Derleme
```bash
make
```

### 2. Türkçe Assembly Kodunu Makine Koduna (.rom) Çevirme
```bash
python3 araclar/derleyici.py programlar/kabuk.asm
```

### 3. Programı Çalıştırma
```bash
# 1. GERÇEK ZAMANLI CANLI İNTERAKTİF EKRAN MODU (Önerilen!)
# Klavyenizden bastığınız harfler anında ekranda görünür! (Çıkış: ESC)
./turk8 -c programlar/kabuk.rom

# 2. Programı çalıştırıp bitince ekranı ve yazmaçları göster
./turk8 -e -y programlar/merhaba.rom

# 3. Canlı Etkileşimli Monitör / Ayıklayıcı ile adım adım (step by step) çalıştır
./turk8 -m programlar/merhaba.rom
```

---

## 🔍 Etkileşimli Sistem Monitörü Komutları
- `a [n]` : Adım çalıştır (Step $n$ komut)
- `k` : Serbest koşu (Run)
- `d [adres]` : Bellek dökümü (Hex + ASCII döküm)
- `e` : 40x25 yeşil fosfor VRAM ekranını çiz
- `y` : Yazmaçların ve sıradaki komutların durumunu göster
- `b <adres>` : Kesme noktası (Breakpoint) koy
- `c` : Çıkış

---

## 🌐 Platform Desteği (macOS, Linux, Windows)

TÜRK-8, tamamen platform bağımsız (cross-platform) C11 standardında geliştirilmiştir:

- **🍎 macOS:** `clang` ve yerel POSIX `termios` ile doğrudan çalışır.
- **🐧 Linux (Ubuntu, Debian, Fedora, Arch vb.):** `gcc` veya `clang` ile doğrudan derlenir (`make`), ek bağımlılık gerektirmez.
- **🪟 Windows (10 / 11):**
  - **WSL & Git Bash:** Doğrudan `make` ve `./turk8` ile çalışır.
  - **Yerel Windows (CMD / PowerShell):** Kod tabanındaki yerel Windows API katmanı (`<windows.h>`, `<conio.h>`, `_kbhit()`, `_getch()`) sayesinde MinGW (`gcc`) veya MSVC ile doğrudan `turk8.exe` olarak derlenip çalışır. Windows Terminal yeşil CRT fosfor renklerini (`\033[1;32m`) yerel olarak destekler.

