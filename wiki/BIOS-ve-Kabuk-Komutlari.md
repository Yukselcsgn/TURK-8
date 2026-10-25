# 🖥️ BIOS ROM (`0xC000`) ve Yerleşik Kabuk Komutları

> 🌍 **English Version:** [BIOS ROM & Built-in Shell Commands](BIOS-and-Shell-Commands)

## 1. Açılış Süreci (POST & Reset)

İşlemci sıfırlandığında `0xFFFC` Sıfırlama Vektöründen `bios_sifirlama` (`0xC000`) adresine zıplar:
1. Yığın göstergesi `YG = 0xFF` yapılır, sıfır sayfa çalışma alanı (`0x00D0–0x00FF`) temizlenir.
2. **Tahribatsız RAM Testi (POST):** `0x0200` ile `0x7FFF` arasındaki 31 KB RAM, her sayfanın mevcut baytı korunarak `0x55` ve `0xAA` desenleriyle sınanır.
3. Ekran temizlenir, başlangıç melodisi çalınır, 50 Hz kesmeler (`KESME AÇ`) etkinleştirilir ve `> ` komut istemi ekrana basılır.

---

## 2. BIOS Sistem Çağrıları (`<n> SİSTEM` — `0xFFFA`)

Kullanıcı programları donanımla doğrudan uğraşmak yerine `<n> SİSTEM` komutuyla BIOS servislerini çağırabilir:

| Servis No | Kullanım | Girdi | Çıktı / Açıklama |
| :---: | :--- | :--- | :--- |
| **`0`** | `0 SİSTEM` | — | Ekranı temizler, imleci sol üste `(0, 0)` taşır. |
| **`1`** | `1 SİSTEM` | `T` = Karakter | `T`'deki karakteri imleç konumuna yazar (`\n`, `\b` ve otomatik kaydırma destekli). |
| **`2`** | `2 SİSTEM` | `X` = Alt, `Y` = Üst adres | `Y:X` adresindeki sıfır (`0`) sonlandırmalı metni ekrana basar. |
| **`3`** | `3 SİSTEM` | — | Beklemesiz klavye okuma: tuş varsa `T` = tuş (`S=0`), yoksa `T=0` (`S=1`). |
| **`4`** | `4 SİSTEM` | — | Beklemeli klavye okuma: tuş basılana kadar bekler ve `T` içinde döndürür. |
| **`5`** | `5 SİSTEM` | — | Klavyeden `Enter`'a kadar satır okur (`0x0080` tamponuna yazar, `T` = uzunluk). |
| **`6`** | `6 SİSTEM` | — | VRAM ekranını 1 satır yukarı kaydırır. |
| **`7`** | `7 SİSTEM` | `X` = Frekans, `Y` = Süre | Belirtilen frekans ve sürede ses çalar. |
| **`8`** | `8 SİSTEM` | — | 24-bit 50 Hz çalışma süresi sayacını döndürür (`T` = alt, `X` = orta, `Y` = üst bayt). |

---

## 3. Yerleşik Kabuk Komutları (`> `)

Kabuk komutları büyük/küçük harf ve Türkçe karakter duyarsızdır (`ÇALIŞTIR` ile `calistir` aynıdır) ve hem **doğal Türkçe SOV** (`PONG ÇALIŞTIR`) hem de **klasik SVO** (`ÇALIŞTIR PONG`) sırasını destekler:

- **`YARDIM`**: Tüm kabuk komutlarını listeler.
- **`TEMİZLE`**: Ekranı temizler.
- **`BİLGİ`**: Sistem donanım ve bellek bilgisini görüntüler.
- **`SÜRE`**: 50 Hz çalışma süresi sayacını 24-bit onaltılık olarak basar.
- **`[adres] BELLEK`**: Belirtilen adresten (varsayılan `0x0200`) itibaren 64 baytı hex ve ASCII olarak döker.
- **`<AD | adres> ÇALIŞTIR`**: Diskteki programı yükleyip çalıştırır veya verilen hex adrese `ÇAĞIR` ile dallanır.
- **`BASIC`**: Türkçe BASIC v1.0 yorumlayıcısını diskten yükleyip başlatır.
