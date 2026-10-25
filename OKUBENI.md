# 🇹🇷 TÜRK-8: 8-Bit Tam Teşekküllü Türkçe Kişisel Bilgisayar ve Sanal Makine (v1.0)

> 🌍 **English Version:** For the English documentation, see [README.md](README.md) and [USER_MANUAL.md](USER_MANUAL.md).  
> 📖 **Detaylı Kılavuz & Wiki:** Komut seti, BIOS, Disk, Makine İçi Assembler ve Türkçe BASIC dersleri için [KULLANIM_KILAVUZU.md](KULLANIM_KILAVUZU.md) belgesini ve [`wiki/`](wiki/Home.md) sayfalarını inceleyin.

---

**TÜRK-8**, Türkçenin matematiksel ve sondan eklemeli doğasına uygun olarak geliştirilmiş; **Özne/Nesne $\rightarrow$ Yüklem (Fiil Sonda / SOV)** kuralını benimseyen, kendi **16 KB BIOS ROM'u**, **64 KB Sanal Diski (`disk.t8`)**, **Makine İçi Monitör ve Etiketli Assembler'ı (`KODLA` / `DÜZENLE` / `DERLE`)** ve **Türkçe BASIC v1.0 Yorumlayıcısı (`BASIC`)** ile doğrudan açılan tam teşekküllü bir 8-bit kişisel bilgisayar mimarisidir.

---

## ✨ Öne Çıkan Özellikler (v1.0)

- **🖥️ Doğrudan Kişisel Bilgisayar Açılışı (`./turk8`):** Argümansız çalıştırıldığında `0xC000` adresindeki 16 KB BIOS ROM'dan açılır, 31 KB kullanıcı RAM'ini test eder (POST), açılış bip sesini çalar ve etkileşimli `> ` kabuğuna düşer.
- **🧠 Dondurulmuş ISA v1.0 (91 Komut):** Dolaylı/indeksli adresleme (`[[a]]`, `[[a] + Y]`), 16-bit elde/borç aritmetiği (`ELDEYLE TOPLA`, `BORÇLA ÇIKAR`), donanım blok kopyalama/doldurma (`KOPYALA`, `DOLDUR`), BCD ayrıştırma (`T RAKAMLARA AYIR`), donanım rastgele sayı (`RASTGELE`), 50 Hz kare senkronizasyonu (`KARE BEKLE`) ve BIOS sistem çağrısı (`{n} SİSTEM`).
- **💾 64 KB Sanal Disk (`disk.t8`):** DMA tabanlı disk denetleyicisi (`0xA010–0xA017`) ve 16 girişli dosya sistemi. Kabuktan `LİSTE`, `<AD> YÜKLE`, `<AD> [adr] [boyut] KAYDET`, `<AD> SİL` ve `<AD> ÇALIŞTIR` komutlarıyla yönetilir.
- **🛠️ Makine İçinde Kodlama (Dış Derleyiciye İhtiyaç Duymadan):**
  - **Woz Tarzı Hex Monitör:** `0300: 10 2A 91` ile doğrudan belleğe bayt yazma, `0300:` ile bellek dökümü.
  - **Satır İçi Assembler (`[adres] KODLA`):** Türkçe assembly satırlarını anında makine koduna çevirir.
  - **Tam Ekran Kaynak Düzenleyici ve 2 Geçişli Etiketli Derleyici (`DÜZENLE`, `KAYNAK`, `[adres|ad] DERLE`):** Etiketler (`dongu:`), `.TANIM`, `.BAŞLANGIÇ`, `.METİN`, `.BAYT`, `.KELİME`, `.BOŞLUK` ve `<etiket`/`>etiket` operatörleriyle makinenin kendi içinde program geliştirip doğrudan diske kaydetme.
- **🚀 Türkçe BASIC v1.0 (`BASIC`):** Hem doğal Türkçe SOV (`"MERHABA" YAZ`, `25 + 17 YAZ`, `10 GİT`, `T GİRDİ`, `I SONRAKİ`, `500 ÇAĞIR`, `OYUN KAYDET`) hem de klasik (`YAZ "MERHABA"`, `GİT 10`) sözdizimini destekleyen, 22 KB serbest kullanıcı alanına (`0x1800–0x6FFF`) sahip yerleşik BASIC yorumlayıcısı.
- **🔤 Tek Baytlık 8-Bit Türkçe Karakter Seti (ISO-8859-9):** `Ç, ç, Ğ, ğ, İ, ı, Ö, ö, Ş, ş, Ü, ü` harfleri VRAM ve bellekte tam 1 bayt yer kaplar.

---

## 🏛️ İşlemci Mimarisi ve Yazmaçlar

- **Veri Yolu:** 8-Bit ($0$ – $255$)
- **Adres Yolu:** 16-Bit (Tam **64 KB** adresleme uzayı: `0x0000` – `0xFFFF`)
- **Yazmaçlar (Registers):**
  - **`T` (Toplaç / Akümülatör):** Aritmetik, mantık ve veri transferlerinin ana merkezi (8-bit)
  - **`X` (1. İndeks):** Sayaç, dizi indeksleme ve `KOPYALA`/`DOLDUR` hedef/uzunluk yazmacı (8-bit)
  - **`Y` (2. İndeks):** İkinci indeks, dolaylı tablo (`[[a] + Y]`) ve `KOPYALA` uzunluk yazmacı (8-bit)
  - **`YG` (Yığın Göstergesi / Stack Pointer):** `0x0100 - 0x01FF` donanım yığınını yönetir (8-bit)
  - **`PS` (Program Sayacı / PC):** Sıradaki komutun 16-bit bellek adresi
  - **`DURUM` (Durum Bayrakları):** `E` (Elde), `S` (Sıfır), `K` (Kesme Engeli), `N` (Negatif), `T` (İşaretli Taşma)

---

## 🗺️ 64 KB Bellek Haritası

| Adres Aralığı | Bölge Adı | Açıklama |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | **Sıfır Sayfa (Zero Page)** | Hızlı erişimli 256 baytlık sistem ve kullanıcı çalışma alanı |
| `0x0100 - 0x01FF` | **Donanım Yığını (Stack)** | `YG` ile yönetilen 256 baytlık LIFO yığını |
| `0x0200 - 0x7FFF` | **Kullanıcı Belleği (RAM)** | Programlar, BASIC yorumlayıcısı ve kaynak tamponu (31.5 KB) |
| `0x8000 - 0x83E7` | **VRAM Ekran Belleği** | 40 sütun $\times$ 25 satır (1000 karakter) yeşil fosforlu CRT ekranı |
| `0xA000 - 0xA0FF` | **Giriş / Çıkış (MMIO)** | 16 baytlık klavye FIFO, 50 Hz zamanlayıcı, ses, RNG, DMA disk (`0xA010–0xA017`) |
| `0xC000 - 0xFFFF` | **Sistem ROM / BIOS** | 16 KB salt okunur BIOS, Kabuk, Monitör ve Dahili Assembler |
| `0xFFFA - 0xFFFB` | **Sistem Çağrısı Vektörü** | `<n> SİSTEM` (BIOS API giriş noktası) |
| `0xFFFC - 0xFFFD` | **Sıfırlama Vektörü (RESET)**| İşlemcinin açılışta zıplayacağı BIOS başlangıç adresi |
| `0xFFFE - 0xFFFF` | **Kesme Vektörü (IRQ)** | 50 Hz donanım zamanlayıcı kesmesi vektörü |

---

## 🛠️ Hızlı Başlangıç (Derleme ve Çalıştırma)

### 1. Derleme ve Disk İmajını Oluşturma
```bash
make
```
Bu komut `turk8` emülatörünü derler, `roms/bios.rom` dosyasını üretir ve `MERHABA`, `TOPLAM`, `PONG`, `KABUK`, `BASIC` programlarını içeren 64 KB'lık `disk.t8` sanal diskini oluşturur.

### 2. Bilgisayarı Doğrudan Başlatma (Önerilen)
```bash
./turk8
```
Bilgisayar doğrudan BIOS ekranıyla açılır ve `> ` komut istemine düşer. Deneyebileceğiniz komutlar:
```text
> YARDIM                ; Tüm yerleşik komutları listeler
> LİSTE                 ; disk.t8 içindeki dosyaları ve boyutlarını gösterir
> PONG ÇALIŞTIR         ; Pong oyununu diskten yükleyip başlatır (W/S: Raket, Q: Kabuğa dön)
> BASIC                 ; Türkçe BASIC v1.0 yorumlayıcısını başlatır (Çıkış: ÇIK)
> 0300 KODLA            ; 0x0300 adresinden itibaren satır içi Türkçe assembly kodlar
> DÜZENLE               ; Etiketli Türkçe assembly kaynak düzenleyicisini açar
```

### 3. Otomatik Test Paketini Çalıştırma (52+ Test)
```bash
make test
```

---

## 🚀 Türkçe BASIC v1.0 Örneği

`> BASIC` yazarak BASIC ortamına (`] ` istemi) girdiğinizde hem anlık hesaplama yapabilir hem de numaralı satırlarla program yazabilirsiniz:

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

## 🌐 Platform Desteği (macOS, Linux, Windows)

TÜRK-8, tamamen platform bağımsız (cross-platform) C11 ve Python 3 ile geliştirilmiştir:

- **🍎 macOS:** `clang` ve yerel POSIX `termios` ile doğrudan çalışır (`make && ./turk8`).
- **🐧 Linux (Ubuntu, Debian, Fedora, Arch vb.):** `gcc` veya `clang` ile ek paket gerektirmeden derlenir (`make && ./turk8`).
- **🪟 Windows (10 / 11):**
  - **WSL & Git Bash:** Linux ile birebir aynı şekilde çalışır.
  - **Yerel Windows (CMD / PowerShell):** `#ifdef _WIN32` katmanı (`<windows.h>`, `<conio.h>`, `_kbhit()`, `_getch()`) sayesinde MinGW (`gcc`) veya MSVC ile doğrudan `turk8.exe` olarak derlenip çalışır.
