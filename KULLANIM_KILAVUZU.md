# 🇹🇷 TÜRK-8 PROGRAMLAMA VE KULLANIM KILAVUZU
### *8-Bit Türkçe Mikrobilgisayar Mimarisi Tam Referansı*

> 🌍 **English Version:** For the English user manual and instruction set reference, see [USER_MANUAL.md](USER_MANUAL.md).  
> 🏠 **Proje Özeti:** [OKUBENI.md](OKUBENI.md) veya [README.md](README.md) belgelerine göz atabilirsiniz.

---

## 📑 İÇİNDEKİLER
1. [Giriş ve Türkçe Söz Dizimi Mantığı](#1-giriş-ve-türkçe-söz-dizimi-mantığı)
2. [İşlemci Mimarisi ve Yazmaçlar (Registers)](#2-işlemci-mimarisi-ve-yazmaçlar)
3. [64 KB Bellek Haritası ve Donanım Adresleri](#3-64-kb-bellek-haritası)
4. [Eksiksiz Komut Seti Referansı (46 Komut)](#4-eksiksiz-komut-seti-referansı)
5. [Adım Adım Kod Yazma Rehberi (Dersler)](#5-adım-adım-kod-yazma-rehberi)
6. [Derleme, Çalıştırma ve Hata Ayıklama](#6-derleme-çalıştırma-ve-hata-ayıklama)
7. [Çoklu Platform Desteği (macOS, Linux, Windows)](#7-çoklu-platform-desteği-macos-linux-windows)

---

## 1. Giriş ve Türkçe Söz Dizimi Mantığı

TÜRK-8, Türkçenin dilbilgisi kurallarına uygun olarak geliştirilmiştir.
Klasik İngilizce assembly dillerinde eylem (fiil) başta gelirken (`LOAD 5`, `JUMP loop`); 
**TÜRK-8'de eylem (yüklem) her zaman cümlenin en sonundadır:**

```
[İşlenen Değerler / Kaynak / Hedef]  ----->  [EYLEM (FİİL)]
```

### Örnek Karşılaştırma:
| Amaç | Klasik Assembly (İngilizce) | TÜRK-8 (Türkçe Söz Dizimi) |
| :--- | :--- | :--- |
| 5 sayısını Toplaca koy | `LDA #5` | **`5 T YÜKLE`** |
| Toplaca 10 ekle | `ADD #10` | **`10 TOPLA`** |
| Değeri ekrana yaz | `STA $8000` | **`T [0x8000] SAKLA`** |
| X sayacını bir artır | `INX` | **`X ARTIR`** |
| Döngüye geri atla | `JMP dongu` | **`dongu ATLA`** |
| Eşitlik varsa atla | `BEQ bitti` | **`bitti EŞİTSE ATLA`** |

---

## 2. İşlemci Mimarisi ve Yazmaçlar

İşlemcimizin içinde verileri anlık olarak tutan 8-bitlik ve 16-bitlik kutucuklar (yazmaçlar) bulunur:

| Yazmaç | Adı | Genişlik | Açıklama |
| :---: | :--- | :---: | :--- |
| **`T`** | **Toplaç (Akümülatör)** | 8 Bit (0-255) | Tüm matematik, mantık ve veri transferlerinin ana merkezidir. |
| **`X`** | **1. İndeks Yazmacı** | 8 Bit (0-255) | Sayaçlar, döngüler ve dizi indisleri için kullanılır. |
| **`Y`** | **2. İndeks Yazmacı** | 8 Bit (0-255) | İkinci sayaç veya iç içe döngüler için kullanılır. |
| **`YG`** | **Yığın Göstergesi (SP)** | 8 Bit (0-255) | Donanım yığınının (`0x0100 - 0x01FF`) tepe adresini tutar. |
| **`PS`** | **Program Sayacı (PC)** | 16 Bit (0-65535)| Sıradaki çalıştırılacak komutun bellek adresini tutar. |
| **`DURUM`**| **Durum Bayrakları** | 8 Bit | Yapılan son işlemin sonucunu bildirir: |

### Durum Bayrakları (DURUM):
- **`E` (Elde / Carry):** Toplamada 255'ten taşma olduysa veya çıkarmada borç yoksa `1` olur.
- **`S` (Sıfır / Zero):** Yapılan son işlemin sonucu `0` çıktıysa `1` olur.
- **`N` (Negatif):** Sonucun en yüksek biti (7. bit) `1` ise (yani sayı negatifse) `1` olur.
- **`K` (Kesme Engeli):** Donanım kesmelerini açıp kapatır.
- **`T` (Taşma / Overflow):** İşaretli sayılarda sınır aşımı olduğunda `1` olur.

---

## 3. 64 KB Bellek Haritası

İşlemcimiz toplam 65.536 baytlık (64 KB) tek bir bellek uzayını görür:

```
0x0000 ┌──────────────────────────────────────────┐
       │ Hızlı Sıfır Sayfa (Zero Page) - 256 Bayt  │
0x00FF ├──────────────────────────────────────────┤
0x0100 │ Donanım Yığını (Hardware Stack) - 256 Bayt│ (YG ile yönetilir)
0x01FF ├──────────────────────────────────────────┤
0x0200 │                                          │
       │ Kullanıcı Programı ve Değişkenler (RAM)  │ (Kodlarımız buraya yüklenir)
       │                                          │
0x7FFF ├──────────────────────────────────────────┤
0x8000 │                                          │
       │ VRAM: CRT Ekran Belleği (40x25 Karakter) │ (Buraya yazılan ekranda çıkar!)
0x83E7 │                                          │
0x83E8 ├──────────────────────────────────────────┤
       │ Boş Genişleme Alanı                      │
0x9FFF ├──────────────────────────────────────────┤
0xA000 │ Giriş / Çıkış Portları (MMIO)            │ (Klavye, Zamanlayıcı, Seri Çıkış)
0xA0FF ├──────────────────────────────────────────┤
0xC000 │                                          │
       │ Sistem ROM / BIOS Alanı (16 KB)          │ (Salt okunur kalıcı sistem)
0xFFFF └──────────────────────────────────────────┘
```

### Önemli Donanım Adresleri:
- **`0x8000` - `0x83E7` (VRAM):** 40 sütun x 25 satır ekran alanı.
  - Formül: `0x8000 + (Satır * 40) + Sütun` adresine bir ASCII bayt yazarsanız ekranda görünür!
- **`0xA000` (Klavye Veri):** Klavyeden basılan son tuşun ASCII kodunu verir.
- **`0xA001` (Klavye Durumu):** Yeni tuşa basıldıysa `1`, okunmadıysa `0` döner.
- **`0xA002` (Zamanlayıcı):** Milisaniye sayacı.
- **`0xA003` (Terminal Çıkış):** Buraya yazılan bayt doğrudan terminal konsoluna basılır.

---

## 4. Eksiksiz Komut Seti Referansı

### A) Veri Yükleme, Saklama ve Aktarma
| Komut | Örnek Yazım | Açıklama |
| :--- | :--- | :--- |
| **`<sayı> T YÜKLE`** | `5 T YÜKLE` | Sabit sayıyı doğrudan Toplaca (`T`) koyar. |
| **`[adres] T YÜKLE`** | `[0x0250] T YÜKLE` | Bellekteki adresten 1 bayt okuyup `T`'ye yükler. |
| **`[adres + X] T YÜKLE`**| `[mesaj + X] T YÜKLE`| Tablonun X. elemanını `T`'ye yükler (Dizi okuma). |
| **`<sayı> X YÜKLE`** | `0 X YÜKLE` | Sabit sayıyı X indeks yazmacına koyar. |
| **`<sayı> Y YÜKLE`** | `10 Y YÜKLE` | Sabit sayıyı Y indeks yazmacına koyar. |
| **`T [adres] SAKLA`** | `T [0x8000] SAKLA` | `T`'deki değeri belirtilen bellek adresine yazar. |
| **`T [adres + X] SAKLA`**| `T [0x8000 + X] SAKLA`| `T`'deki değeri X indeksli adrese yazar. |
| **`X [adres] SAKLA`** | `X [0x0220] SAKLA` | X yazmacını belleğe kaydeder. |
| **`Y [adres] SAKLA`** | `Y [0x0221] SAKLA` | Y yazmacını belleğe kaydeder. |
| **`X T AKTAR`** | `X T AKTAR` | X'teki değeri Toplaca kopyalar (`T = X`). |
| **`T X AKTAR`** | `T X AKTAR` | Toplaçtaki değeri X'e kopyalar (`X = T`). |
| **`Y T AKTAR`** | `Y T AKTAR` | Y'deki değeri Toplaca kopyalar (`T = Y`). |
| **`T Y AKTAR`** | `T Y AKTAR` | Toplaçtaki değeri Y'ye kopyalar (`Y = T`). |

---

### B) Aritmetik ve Karşılaştırma
| Komut | Örnek Yazım | Açıklama |
| :--- | :--- | :--- |
| **`<sayı> TOPLA`** | `10 TOPLA` | `T = T + 10` (Taşma olursa Elde bayrağı 1 olur). |
| **`[adres] TOPLA`** | `[sayi] TOPLA` | Adresteki değeri Toplaca ekler. |
| **`<sayı> ELDEYLE TOPLA`**| `0 ELDEYLE TOPLA` | `T = T + sayı + Elde` (Çok baytlı toplama için). |
| **`<sayı> ÇIKAR`** | `5 ÇIKAR` | `T = T - 5`. |
| **`[adres] ÇIKAR`** | `[fiyat] ÇIKAR` | Adresteki değeri Toplaçtan çıkarır. |
| **`T ARTIR`** | `T ARTIR` | Toplacı 1 artırır (`T++`). |
| **`X ARTIR`** | `X ARTIR` | X sayacını 1 artırır (`X++`). |
| **`Y ARTIR`** | `Y ARTIR` | Y sayacını 1 artırır (`Y++`). |
| **`T AZALT`** | `T AZALT` | Toplacı 1 azaltır (`T--`). |
| **`X AZALT`** | `X AZALT` | X sayacını 1 azaltır (`X--`). |
| **`Y AZALT`** | `Y AZALT` | Y sayacını 1 azaltır (`Y--`). |
| **`<sayı> KARŞILAŞTIR`**| `0 KARŞILAŞTIR` | `T` ile sayıyı kıyaslar; `S` (Sıfır/Eşit) bayrağını günceller. |
| **`<sayı> X KARŞILAŞTIR`**| `10 X KARŞILAŞTIR` | X ile sayıyı kıyaslar (Döngü sonu testi için). |

---

### C) Mantık ve Bit İşlemleri
| Komut | Örnek Yazım | Açıklama |
| :--- | :--- | :--- |
| **`<sayı> VE`** | `0x0F VE` | Mantıksal AND (İstenen bitleri maskeler). |
| **`<sayı> VEYA`** | `0x80 VEYA` | Mantıksal OR (İstenen bitleri 1 yapar). |
| **`<sayı> ÖZELVEYA`** | `0xFF ÖZELVEYA` | Mantıksal XOR (Bitleri tersler veya sıfırlar). |
| **`T DEĞİLLE`** | `T DEĞİLLE` | Toplaçtaki tüm bitleri tersler (`NOT`). |
| **`T SOLA KAYDIR`** | `T SOLA KAYDIR` | Sayıyı 2 ile çarpar (Bitleri sola kaydırır). |
| **`T SAĞA KAYDIR`** | `T SAĞA KAYDIR` | Sayıyı 2'ye böler (Bitleri sağa kaydırır). |

---

### D) Akış Kontrolü ve Atlamalar
| Komut | Örnek Yazım | Açıklama |
| :--- | :--- | :--- |
| **`<hedef> ATLA`** | `dongu ATLA` | Şartsız olarak etikete/adrese atlar (`JMP`). |
| **`<hedef> EŞİTSE ATLA`**| `bitti EŞİTSE ATLA` | Son işlem sonucu sıfır veya eşitse atlar (`BEQ`). |
| **`<hedef> FARKLIYSA ATLA`**| `dongu FARKLIYSA ATLA`| Son işlem eşit değilse/sıfır değilse atlar (`BNE`). |
| **`<hedef> BÜYÜKSE ATLA`**| `etiket BÜYÜKSE ATLA` | Karşılaştırma sonucu büyükse atlar. |
| **`<hedef> KÜÇÜKSE ATLA`**| `etiket KÜÇÜKSE ATLA` | Karşılaştırma sonucu küçükse atlar. |
| **`<hedef> ELDE VARSA ATLA`**| `tasma ELDE VARSA ATLA`| 255'ten taşma olduysa atlar (`BCS`). |

---

### E) Alt Programlar (Fonksiyonlar) ve Yığın
| Komut | Örnek Yazım | Açıklama |
| :--- | :--- | :--- |
| **`<hedef> ÇAĞIR`** | `ekrana_yaz ÇAĞIR` | Dönüş adresini yığına saklar ve fonksiyona gider (`CALL`). |
| **`DÖN`** | `DÖN` | Fonksiyon bitince çağrıldığı yere geri döner (`RET`). |
| **`T İT`** | `T İT` | `T` yazmacını yığına fırlatır (`PUSH`). |
| **`T ÇEK`** | `T ÇEK` | Yığından veriyi alıp `T`'ye koyar (`POP`). |
| **`DURUM İT`** | `DURUM İT` | Durum bayraklarını yığına saklar. |
| **`DURUM ÇEK`** | `DURUM ÇEK` | Bayrakları yığından geri yükler. |

---

### F) Sistem ve I/O Komutları
| Komut | Örnek Yazım | Açıklama |
| :--- | :--- | :--- |
| **`BOŞ`** | `BOŞ` | 1 saat çevrimi bekler (`NOP`). |
| **`DUR`** | `DUR` | İşlemciyi durdurur (`HALT`). |
| **`<port> GİRİŞ`** | `0 GİRİŞ` | Belirtilen I/O portundan veri okur (`IN`). |
| **`<port> ÇIKIŞ`** | `3 ÇIKIŞ` | `T`'deki veriyi I/O portuna gönderir (`OUT`). |

---

## 5. Adım Adım Kod Yazma Rehberi

### Ders 1: İki Sayıyı Toplayıp Belleğe Saklama
```assembly
.BAŞLANGIÇ 0x0200

    15 T YÜKLE          ; Toplaca 15 koy
    25 TOPLA            ; 25 ekle (T = 40)
    T [sonuc] SAKLA     ; 40 sayısını 'sonuc' etiketine yaz
    DUR                 ; İşlemciyi durdur

sonuc:
    .BAYT 0             ; Değişken için 1 bayt yer ayır
```

---

### Ders 2: Ekrana (VRAM) Tek Bir Harf Basma
```assembly
.BAŞLANGIÇ 0x0200

    ; 'A' harfinin ASCII kodu 65'tir
    65 T YÜKLE
    ; Ekranın ilk hücresine (Sol-Üst: 0x8000) yaz
    T [0x8000] SAKLA
    DUR
```

---

### Ders 3: Döngü (Loop) Kurma (10'dan Geriye Sayma)
```assembly
.BAŞLANGIÇ 0x0200

    10 X YÜKLE          ; X sayacı = 10

dongu:
    ; Burada bir işlem yapılır...
    X AZALT             ; X = X - 1
    0 X KARŞILAŞTIR     ; X sıfır oldu mu?
    dongu FARKLIYSA ATLA; Sıfır değilse döngüye devam et

    DUR                 ; Sıfır olunca bitir
```

---

### Ders 4: Ekrana Metin (String) Yazdırma
```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    0 X YÜKLE                  ; Karakter indisi = 0

dongu:
    [mesaj + X] T YÜKLE        ; mesajın X. baytını oku
    0 KARŞILAŞTIR              ; Metin sonu (0) mu?
    bitti EŞİTSE ATLA          ; Eşitse bitir

    T [0x8000 + X] SAKLA       ; Harfi ekrana yaz
    X ARTIR                    ; Sıradaki harfe geç
    dongu ATLA                 ; Döngüye devam et

bitti:
    DUR

mesaj:
    .METİN "MERHABA TURK-8!"
    .BAYT 0                    ; Metin sonlandırıcı sıfır
```

---

### Ders 5: Fonksiyon (Alt Program) Kullanma
```assembly
.BAŞLANGIÇ 0x0200

ana_program:
    65 T YÜKLE                 ; 'A' harfi
    harf_yaz ÇAĞIR             ; Fonksiyonu çağır

    66 T YÜKLE                 ; 'B' harfi
    harf_yaz ÇAĞIR             ; Fonksiyonu tekrar çağır

    DUR                        ; Program bitti

; --- Alt Program (Fonksiyon) ---
harf_yaz:
    T [0x8000 + X] SAKLA       ; Harfi ekrana yaz
    X ARTIR                    ; İndeksi ilerlet
    DÖN                        ; Çağrılan yere geri dön
```

---

## 6. Derleme, Çalıştırma ve Hata Ayıklama

### 1. Yeni Kodunuzu Kaydedin
`programlar/` klasörü altına dosyanızı kaydedin (Örn: `programlar/ornek.asm`).

### 2. Türkçe Derleyici ile Çevirin
```bash
python3 araclar/derleyici.py programlar/ornek.asm programlar/ornek.rom
```

### 3. Çalıştırın
```bash
# A) Gerçek Zamanlı Canlı İnteraktif Ekran (Önerilen)
./turk8 -c programlar/ornek.rom

# B) Programı çalıştırıp sonucunu ve yazmaçları görmek için
./turk8 -e -y programlar/ornek.rom

# C) Adım Adım (Debug) Modunda İncelemek İçin
./turk8 -m programlar/ornek.rom
```

---

## 7. Çoklu Platform Desteği (macOS, Linux, Windows)

TÜRK-8, tamamen platform bağımsız C11 ve Python 3 ile tasarlanmıştır.

### 🍎 macOS
- `clang` ile `make` yazarak doğrudan derlenir.
- Terminal raw modu POSIX `termios` üzerinden yerel çalışır.

### 🐧 Linux (Ubuntu / Debian / Fedora / Arch)
- `gcc` veya `clang` ile hiçbir ek paket kurmadan derlenir:
  ```bash
  make
  ./turk8 -c programlar/kabuk.rom
  ```
- Terminal renkleri ve anlık klavye yakalama yerel olarak desteklenir.

### 🪟 Windows (10 / 11)
- **WSL veya Git Bash:** Linux ile birebir aynı şekilde `make` ve `./turk8` ile çalışır.
- **Yerel CMD / PowerShell (MinGW GCC veya MSVC):**
  - Kod tabanı içindeki `#ifdef _WIN32` katmanı sayesinde Windows konsol API'leri (`<windows.h>`, `<conio.h>`, `_kbhit()`, `_getch()`, `Sleep()`) devreye girer.
  - Windows Terminal'in modern ANSI desteği ile yeşil retro CRT ekranı yerel olarak çizilir.

---

TÜRK-8 ile kodlama yaparken iyi eğlenceler! 🇹🇷💻


