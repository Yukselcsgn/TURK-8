# 🏛️ İşlemci Mimarisi, 64 KB Bellek Haritası ve Donanım

> 🌍 **English Version:** [Architecture & 64 KB Memory Map](Architecture-and-Memory-Map)

## 1. Yazmaçlar (Registers)

| Yazmaç | Genişlik | Adı | Görevi |
| :---: | :---: | :--- | :--- |
| **`T`** | 8-Bit | **Toplaç (Akümülatör)** | Tüm aritmetik, mantık, karşılaştırma ve G/Ç işlemlerinin ana yazmacı. |
| **`X`** | 8-Bit | **1. İndeks Yazmacı** | Döngü sayacı, `[a + X]` indeksleme ve `KOPYALA`/`DOLDUR` sıfır sayfa taban indeksi. |
| **`Y`** | 8-Bit | **2. İndeks Yazmacı** | `[a + Y]`, `[[a] + Y]` dolaylı indeksleme ve blok işlem uzunluğu. |
| **`YG`** | 8-Bit | **Yığın Göstergesi (SP)** | `0x0100 - 0x01FF` donanım yığınında sıradaki boş adresi tutar (`0xFF`'ten aşağı büyür). |
| **`PS`** | 16-Bit | **Program Sayacı (PC)** | Sıradaki çalıştırılacak komutun 16-bit bellek adresi. |
| **`DURUM`** | 8-Bit | **Durum Bayrakları** | `E` (Elde/Bit 0), `S` (Sıfır/Bit 1), `K` (Kesme Engeli/Bit 2), `N` (Negatif/Bit 6), `T` (Taşma/Bit 7). |

---

## 2. 64 KB Bellek Haritası (`0x0000 - 0xFFFF`)

| Adres Aralığı | Boyut | Bölge | Açıklama |
| :--- | :---: | :--- | :--- |
| `0x0000 - 0x00CF` | 208 B | **Kullanıcı Sıfır Sayfa** | Hızlı erişimli işaretçi ve geçici değişken alanı (`0x0080–0x00BF`: satır tamponu). |
| `0x00D0 - 0x00FF` | 48 B | **BIOS Sıfır Sayfa** | İmleç, uptime sayacı, kabuk, monitör ve dahili derleyici durum değişkenleri. |
| `0x0100 - 0x01FF` | 256 B | **Donanım Yığını** | `İT`, `ÇEK`, `ÇAĞIR`, `DÖN` komutlarının kullandığı LIFO yığını. |
| `0x0200 - 0x17FF` | 5.5 KB | **Program RAM Alanı** | Diskten yüklenen ikili programlar (`MERHABA`, `PONG`, `BASIC` yorumlayıcısı) buraya yerleşir. |
| `0x1800 - 0x5FFF` | 18 KB | **BASIC / Genel RAM** | Türkçe BASIC kullanıcı programları (`0x1800–0x6FFF` arası toplam 22 KB) için serbest alan. |
| `0x6000 - 0x77FF` | 6 KB | **Kaynak Tamponu** | `DÜZENLE` ve `DERLE` komutlarının kullandığı metin kaynak tamponu. |
| `0x7800 - 0x7FFF` | 2 KB | **Sembol Tablosu** | 2 geçişli dahili `DERLE` assembler'ının etiket/sabit tablosu (64 sembol $\times$ 16 bayt). |
| `0x8000 - 0x83E7` | 1000 B | **VRAM Ekran Belleği** | 40 sütun $\times$ 25 satır yeşil fosforlu CRT ekran (`0x8000 + satır*40 + sütun`). |
| `0xA000 - 0xA0FF` | 256 B | **MMIO Donanım Portları** | Klavye FIFO, zamanlayıcı, ses, RNG, DMA disk ve test çıkış portları. |
| `0xC000 - 0xFFFF` | 16 KB | **Sistem ROM (BIOS)** | Yazma korumalı sistem yazılımı ve donanım vektörleri (`0xFFFA`, `0xFFFC`, `0xFFFE`). |

---

## 3. MMIO Donanım Portları (`0xA000 - 0xA0FF`)

| Adres | Port Adı | Yön | Açıklama |
| :---: | :--- | :---: | :--- |
| `0xA000` | `PORT_KLAVYE_VERI` | Oku | 16 baytlık klavye FIFO kuyruğundan sıradaki tuşu çeker (kuyruk boşsa `0`). |
| `0xA001` | `PORT_KLAVYE_DURUM` | Oku/Yaz | Bit 0: Tuş hazır (`1`), Bit 1: FIFO taşması (`1`). Yazıldığında taşma bayrağını temizler. |
| `0xA002` | `PORT_ZAMANLAYICI` | Oku | 50 Hz (her 20 ms'de +1) donanım zamanlayıcı sayacı. |
| `0xA003` | `PORT_SERI_CIKIS` | Yaz | Yazılan baytı doğrudan ana bilgisayar terminaline (`stdout`) gönderir. |
| `0xA004` | `PORT_SES_FREKANS` | Oku/Yaz | Ses üreteci frekans değeri (`1..255`). |
| `0xA005` | `PORT_SES_SURE` | Oku/Yaz | Ses süresi (tik); sıfırdan farklı bir değer yazıldığında sesi tetikler. |
| `0xA006` | `PORT_RASTGELE` | Oku/Yaz | 16-bit LFSR donanım rastgele sayı üreteci (yazıldığında tohum/seed güncellenir). |
| `0xA010` | `PORT_DISK_KOMUT` | Yaz | `1`: Sektör Oku, `2`: Sektör Yaz, `3`: Disk Bilgi. |
| `0xA011` | `PORT_DISK_DURUM` | Oku | `0x00`: Başarılı / Hazır, `0xFF`: Hata oluştu. |
| `0xA012` | `PORT_DISK_SEKTOR` | Oku/Yaz | Başlangıç sektör numarası (`0..255`). |
| `0xA013` | `PORT_DISK_ADRES_ALT` | Oku/Yaz | DMA RAM adresi alt baytı. |
| `0xA014` | `PORT_DISK_ADRES_UST` | Oku/Yaz | DMA RAM adresi üst baytı. |
| `0xA015` | `PORT_DISK_SAYI` | Oku/Yaz | Aktarılacak sektör sayısı (`1` sektör = 256 bayt). |
| `0xA016` | `PORT_DISK_HATA` | Oku | Hata kodu (`0`: Yok, `1`: Dosya yok, `2`: Sektör sınır dışı, `3`: RAM sınır dışı, `4`: G/Ç). |
| `0xA0FF` | `PORT_TEST_SONUC` | Yaz | Başsız (`--test`) kipte emülatörü sonlandırır (`1` = Başarılı, diğerleri = Hata). |

---

## 4. 8-Bit Tek Baytlık Türkçe Karakter Seti (ISO-8859-9)

| Harf | Hex | Onluk | Harf | Hex | Onluk |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **`Ç`** | `0xC7` | 199 | **`ç`** | `0xE7` | 231 |
| **`Ğ`** | `0xD0` | 208 | **`ğ`** | `0xF0` | 240 |
| **`İ`** | `0xDD` | 221 | **`ı`** | `0xFD` | 253 |
| **`Ö`** | `0xD6` | 214 | **`ö`** | `0xF6` | 246 |
| **`Ş`** | `0xDE` | 222 | **`ş`** | `0xFE` | 254 |
| **`Ü`** | `0xDC` | 220 | **`ü`** | `0xFC` | 252 |
