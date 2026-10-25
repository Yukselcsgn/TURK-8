# 💾 Sanal Disk Sistemi (`disk.t8`)

> 🌍 **English Version:** [Virtual Disk System (`disk.t8`)](Virtual-Disk-System)

TÜRK-8, programları ve BASIC kaynaklarını kalıcı olarak saklamak için **64 KB boyutunda, 256 sektörlü (`disk.t8`)** bir sanal disk kullanır.

---

## 1. Disk İmaj Formatı (`disk.t8`)

- **Toplam Boyut:** 65.536 bayt (256 sektör $\times$ 256 bayt)
- **Sektör 0 (`0x0000 - 0x00FF`):** 16 girişli kök dizin tablosu (her giriş 16 bayt).
- **Sektör 1..255:** Veri sektörleri.

### Dizin Girişi Yapısı (16 Bayt)
| Ofset | Uzunluk | Alan | Açıklama |
| :---: | :---: | :--- | :--- |
| `0x00` | 1 B | `durum` | `0x00` = Boş/Silinmiş, `0x01` = Kullanımda |
| `0x01..0x08` | 8 B | `ad` | Boşluk (`0x20`) dolgulu 8 karakterlik dosya adı (örn. `"PONG    "`) |
| `0x09` | 1 B | `bas_sektor` | Başlangıç sektörü (`1..255`) |
| `0x0A` | 1 B | `sektor_sayisi` | Ayrılan ardışık sektör sayısı |
| `0x0B..0x0C` | 2 B | `yukleme_adresi` | RAM'e yükleneceği 16-bit başlangıç adresi (küçük uçlu, örn. `0x0200`) |
| `0x0D..0x0E` | 2 B | `boyut` | Dosyanın gerçek bayt boyutu (küçük uçlu) |
| `0x0F` | 1 B | `tur` | `0x00` = Makine kodu (`.rom`), `0x01` = Veri / BASIC |

---

## 2. BIOS Kabuğundan Disk Kullanımı

```text
> LİSTE                         ; Diskteki dosyaları ve boyutlarını listeler
> MERHABA YÜKLE                 ; MERHABA dosyasını 0x0200 adresine yükler
> PONG ÇALIŞTIR                 ; PONG dosyasını yükleyip doğrudan çalıştırır
> ORNEK 0300 0020 KAYDET        ; 0x0300 adresinden 0x0020 (32) baytı ORNEK adıyla diske yazar
> ORNEK SİL                     ; ORNEK dosyasını diskten siler
```

---

## 3. Ana Bilgisayardan Disk Yönetimi (`araclar/disk.py`)

```bash
# Disk içeriğini görüntüle
python3 araclar/disk.py liste disk.t8

# Yeni bir .asm veya .rom dosyasını diske ekle
python3 araclar/disk.py ekle disk.t8 OYUN:programlar/pong.asm

# Diskten dosyayı dışarı çıkar
python3 araclar/disk.py cikar disk.t8 OYUN cikti.rom

# Diskten dosyayı sil
python3 araclar/disk.py sil disk.t8 OYUN
```
