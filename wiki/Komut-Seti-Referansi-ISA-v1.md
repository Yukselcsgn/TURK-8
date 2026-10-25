# 🧠 Komut Seti Referansı — ISA v1.0 (91 Komut)

> 🌍 **English Version:** [Instruction Set Reference (ISA v1.0 — 91 Opcodes)](Instruction-Set-Reference-ISA-v1)

Bu sayfa doğrudan [`araclar/isa.py`](https://github.com/Yukselcsgn/TURK-8/blob/main/araclar/isa.py) içindeki tek kaynaklı komut tablosundan otomatik üretilmiştir.

- `{n}`: 8-bitlik sabit sayı veya port işleneni (1 bayt)
- `{a}`: 16-bitlik bellek adresi veya etiket (2 bayt, küçük uçlu / little-endian)

---

| Opkod | C Sabiti | Söz Dizimi Deseni | Boyut | Açıklama |
| :---: | :--- | :--- | :---: | :--- |
| `0x00` | `KMT_BOS` | `BOŞ` | 1 bayt | İşlem yapmadan 1 çevrim bekler (`NOP`). |
| `0x01` | `KMT_DUR` | `DUR` | 1 bayt | İşlemciyi durdurur (`HALT`). |
| `0x02` | `KMT_KESME_AC` | `KESME AÇ` | 1 bayt | Donanım kesmelerini etkinleştirir (`K = 0`). |
| `0x03` | `KMT_KESME_KAPAT` | `KESME KAPAT` | 1 bayt | Donanım kesmelerini devre dışı bırakır (`K = 1`). |
| `0x04` | `KMT_SIFIRLA` | `SIFIRLA` | 1 bayt | Yazmaçları ve durum bayraklarını sıfırlar. |
| `0x05` | `KMT_SISTEM` | `{n} SİSTEM` | 2 bayt | `{n}` numaralı BIOS sistem çağrısını (`0xFFFA`) tetikler. |
| `0x06` | `KMT_KARE_BEKLE` | `KARE BEKLE` | 1 bayt | Bir sonraki 50 Hz ekran karesine (frame) kadar bekler. |
| `0x07` | `KMT_RASTGELE` | `RASTGELE` | 1 bayt | Donanım LFSR üretecinden `T` yazmacına rastgele bayt (`0..255`) yükler. |
| `0x10` | `KMT_YUKLE_SABIT_T` | `{n} T YÜKLE` | 2 bayt | 8-bit sabit sayıyı `T` (Toplaç) yazmacına yükler. |
| `0x11` | `KMT_YUKLE_ADRES_T` | `[{a}] T YÜKLE` | 3 bayt | `{a}` bellek adresindeki baytı `T` yazmacına yükler. |
| `0x12` | `KMT_YUKLE_INDEKS_X_T` | `[{a} + X] T YÜKLE` | 3 bayt | `{a} + X` adresindeki baytı `T` yazmacına yükler. |
| `0x13` | `KMT_YUKLE_SABIT_X` | `{n} X YÜKLE` | 2 bayt | 8-bit sabit sayıyı `X` indeks yazmacına yükler. |
| `0x14` | `KMT_YUKLE_SABIT_Y` | `{n} Y YÜKLE` | 2 bayt | 8-bit sabit sayıyı `Y` indeks yazmacına yükler. |
| `0x15` | `KMT_SAKLA_T_ADRES` | `T [{a}] SAKLA` | 3 bayt | `T` yazmacındaki baytı `{a}` bellek adresine yazar. |
| `0x16` | `KMT_SAKLA_T_INDEKS_X` | `T [{a} + X] SAKLA` | 3 bayt | `T` yazmacındaki baytı `{a} + X` adresine yazar. |
| `0x17` | `KMT_SAKLA_X_ADRES` | `X [{a}] SAKLA` | 3 bayt | `X` yazmacındaki baytı `{a}` bellek adresine yazar. |
| `0x18` | `KMT_SAKLA_Y_ADRES` | `Y [{a}] SAKLA` | 3 bayt | `Y` yazmacındaki baytı `{a}` bellek adresine yazar. |
| `0x19` | `KMT_AKTAR_X_T` | `X T AKTAR` | 1 bayt | `X` değerini `T` yazmacına kopyalar (`T = X`). |
| `0x1A` | `KMT_AKTAR_T_X` | `T X AKTAR` | 1 bayt | `T` değerini `X` yazmacına kopyalar (`X = T`). |
| `0x1B` | `KMT_AKTAR_Y_T` | `Y T AKTAR` | 1 bayt | `Y` değerini `T` yazmacına kopyalar (`T = Y`). |
| `0x1C` | `KMT_AKTAR_T_Y` | `T Y AKTAR` | 1 bayt | `T` değerini `Y` yazmacına kopyalar (`Y = T`). |
| `0x1D` | `KMT_YUKLE_DOLAYLI_T` | `[[{a}]] T YÜKLE` | 3 bayt | `{a}` adresinde tutulan 16-bit işaretçinin gösterdiği baytı `T`'ye yükler. |
| `0x1E` | `KMT_SAKLA_T_DOLAYLI` | `T [[{a}]] SAKLA` | 3 bayt | `T` değerini `{a}` adresindeki 16-bit işaretçinin gösterdiği adrese yazar. |
| `0x20` | `KMT_YUKLE_ADRES_X` | `[{a}] X YÜKLE` | 3 bayt | `{a}` bellek adresindeki baytı `X` yazmacına yükler. |
| `0x21` | `KMT_YUKLE_ADRES_Y` | `[{a}] Y YÜKLE` | 3 bayt | `{a}` bellek adresindeki baytı `Y` yazmacına yükler. |
| `0x22` | `KMT_YUKLE_INDEKS_Y_T` | `[{a} + Y] T YÜKLE` | 3 bayt | `{a} + Y` adresindeki baytı `T` yazmacına yükler. |
| `0x23` | `KMT_SAKLA_T_INDEKS_Y` | `T [{a} + Y] SAKLA` | 3 bayt | `T` yazmacındaki baytı `{a} + Y` adresine yazar. |
| `0x24` | `KMT_YUKLE_DOLAYLI_Y_T` | `[[{a}] + Y] T YÜKLE` | 3 bayt | `({a} adresindeki 16-bit işaretçi) + Y` adresindeki baytı `T`'ye yükler. |
| `0x25` | `KMT_SAKLA_T_DOLAYLI_Y` | `T [[{a}] + Y] SAKLA` | 3 bayt | `T` değerini `({a} adresindeki 16-bit işaretçi) + Y` adresine yazar. |
| `0x26` | `KMT_AKTAR_YG_T` | `YG T AKTAR` | 1 bayt | Yığın göstergesini (`YG`) `T` yazmacına kopyalar. |
| `0x27` | `KMT_AKTAR_T_YG` | `T YG AKTAR` | 1 bayt | `T` değerini yığın göstergesine (`YG`) kopyalar. |
| `0x28` | `KMT_KOPYALA` | `KOPYALA` | 1 bayt | Sıfır sayfadaki kaynak (`[X..X+1]`), hedef (`[X+2..X+3]`) ve `Y` bayt uzunluğa göre blok kopyalar. |
| `0x29` | `KMT_DOLDUR` | `DOLDUR` | 1 bayt | Sıfır sayfadaki hedef (`[X..X+1]`) adresinden itibaren `Y` baytı `T` değeriyle doldurur. |
| `0x30` | `KMT_TOPLA_SABIT` | `{n} TOPLA` | 2 bayt | `T = T + {n}` (Elde, Sıfır, Negatif, Taşma bayraklarını günceller). |
| `0x31` | `KMT_TOPLA_ADRES` | `[{a}] TOPLA` | 3 bayt | `T = T + [{a}]` (Bellekteki baytı `T`'ye ekler). |
| `0x32` | `KMT_TOPLA_ELDEYLE` | `{n} ELDEYLE TOPLA` | 2 bayt | `T = T + {n} + E` (Elde bayrağıyla toplar — 16-bit toplama için). |
| `0x33` | `KMT_CIKAR_SABIT` | `{n} ÇIKAR` | 2 bayt | `T = T - {n}` (Sabit sayıyı `T`'den çıkarır). |
| `0x34` | `KMT_CIKAR_ADRES` | `[{a}] ÇIKAR` | 3 bayt | `T = T - [{a}]` (Bellekteki baytı `T`'den çıkarır). |
| `0x35` | `KMT_ARTIR_T` | `T ARTIR` | 1 bayt | `T` yazmacını 1 artırır (`T++`). |
| `0x36` | `KMT_ARTIR_X` | `X ARTIR` | 1 bayt | `X` yazmacını 1 artırır (`X++`). |
| `0x37` | `KMT_ARTIR_Y` | `Y ARTIR` | 1 bayt | `Y` yazmacını 1 artırır (`Y++`). |
| `0x38` | `KMT_AZALT_T` | `T AZALT` | 1 bayt | `T` yazmacını 1 azaltır (`T--`). |
| `0x39` | `KMT_AZALT_X` | `X AZALT` | 1 bayt | `X` yazmacını 1 azaltır (`X--`). |
| `0x3A` | `KMT_AZALT_Y` | `Y AZALT` | 1 bayt | `Y` yazmacını 1 azaltır (`Y--`). |
| `0x3B` | `KMT_KARSILASTIR_SABIT` | `{n} KARŞILAŞTIR` | 2 bayt | `T` ile `{n}` sabitini karşılaştırır (`T - {n}`, bayrakları günceller). |
| `0x3C` | `KMT_KARSILASTIR_X` | `{n} X KARŞILAŞTIR` | 2 bayt | `X` ile `{n}` sabitini karşılaştırır (`X - {n}`). |
| `0x3D` | `KMT_KARSILASTIR_Y` | `{n} Y KARŞILAŞTIR` | 2 bayt | `Y` ile `{n}` sabitini karşılaştırır (`Y - {n}`). |
| `0x3E` | `KMT_KARSILASTIR_ADRES` | `[{a}] KARŞILAŞTIR` | 3 bayt | `T` ile `[{a}]` bellekteki baytı karşılaştırır (`T - [{a}]`). |
| `0x3F` | `KMT_CIKAR_BORCLA` | `{n} BORÇLA ÇIKAR` | 2 bayt | `T = T - {n} - (1 - E)` (Borçla çıkarma — 16-bit çıkarma için). |
| `0x40` | `KMT_ELDE_KUR` | `ELDE KUR` | 1 bayt | Elde (`E`) bayrağını `1` yapar. |
| `0x41` | `KMT_ELDE_TEMIZLE` | `ELDE TEMİZLE` | 1 bayt | Elde (`E`) bayrağını `0` yapar. |
| `0x42` | `KMT_ARTIR_ADRES` | `[{a}] ARTIR` | 3 bayt | `{a}` bellek adresindeki baytı doğrudan 1 artırır (`[{a}]++`). |
| `0x43` | `KMT_AZALT_ADRES` | `[{a}] AZALT` | 3 bayt | `{a}` bellek adresindeki baytı doğrudan 1 azaltır (`[{a}]--`). |
| `0x44` | `KMT_RAKAMLARA_AYIR` | `T RAKAMLARA AYIR` | 1 bayt | `T` değerini yüzler (`Y`), onlar (`X`) ve birler (`T`) basamaklarına ayırır. |
| `0x50` | `KMT_VE_SABIT` | `{n} VE` | 2 bayt | `T = T & {n}` (Bit düzeyinde VE). |
| `0x51` | `KMT_VEYA_SABIT` | `{n} VEYA` | 2 bayt | `T = T | {n}` (Bit düzeyinde VEYA). |
| `0x52` | `KMT_OZELVEYA_SABIT` | `{n} ÖZELVEYA` | 2 bayt | `T = T ^ {n}` (Bit düzeyinde ÖZELVEYA / XOR). |
| `0x53` | `KMT_DEGILLE_T` | `T DEĞİLLE` | 1 bayt | `T = ~T` (Tüm bitleri tersler / NOT). |
| `0x54` | `KMT_KAYDIR_SOLA` | `T SOLA KAYDIR` | 1 bayt | `T` bitlerini 1 sola kaydırır (7. bit `E`'ye gider, 0. bit `0` olur). |
| `0x55` | `KMT_KAYDIR_SAGA` | `T SAĞA KAYDIR` | 1 bayt | `T` bitlerini 1 sağa kaydırır (0. bit `E`'ye gider, 7. bit `0` olur). |
| `0x56` | `KMT_DONDUR_SOLA` | `T SOLA DÖNDÜR` | 1 bayt | `T` bitlerini Elde (`E`) üzerinden 1 sola döndürür (`ROL`). |
| `0x57` | `KMT_DONDUR_SAGA` | `T SAĞA DÖNDÜR` | 1 bayt | `T` bitlerini Elde (`E`) üzerinden 1 sağa döndürür (`ROR`). |
| `0x58` | `KMT_BIT_SINA` | `{n} BİT SINA` | 2 bayt | `T & {n}` işlemini yapar; `T` değişmez, yalnızca `S` (Sıfır) bayrağı güncellenir. |
| `0x59` | `KMT_VE_ADRES` | `[{a}] VE` | 3 bayt | `T = T & [{a}]` (Bellekteki bayt ile VE). |
| `0x5A` | `KMT_VEYA_ADRES` | `[{a}] VEYA` | 3 bayt | `T = T | [{a}]` (Bellekteki bayt ile VEYA). |
| `0x70` | `KMT_ATLA` | `{a} ATLA` | 3 bayt | Koşulsuz olarak `{a}` adresine atlar (`PS = {a}`). |
| `0x71` | `KMT_ESITSE_ATLA` | `{a} EŞİTSE ATLA` | 3 bayt | Eşitse (`S == 1`) `{a}` adresine atlar. |
| `0x72` | `KMT_FARKLIYSA_ATLA` | `{a} FARKLIYSA ATLA` | 3 bayt | Farklıysa (`S == 0`) `{a}` adresine atlar. |
| `0x73` | `KMT_BUYUKSE_ATLA` | `{a} BÜYÜKSE ATLA` | 3 bayt | İşaretsiz karşılaştırmada büyükse (`E == 1` ve `S == 0`) `{a}` adresine atlar. |
| `0x74` | `KMT_KUCUKSE_ATLA` | `{a} KÜÇÜKSE ATLA` | 3 bayt | İşaretsiz karşılaştırmada küçükse (`E == 0`) `{a}` adresine atlar. |
| `0x75` | `KMT_ELDE_VARSA_ATLA` | `{a} ELDE VARSA ATLA` | 3 bayt | Elde varsa / büyük veya eşitse (`E == 1`) `{a}` adresine atlar. |
| `0x76` | `KMT_ELDE_YOKSA_ATLA` | `{a} ELDE YOKSA ATLA` | 3 bayt | Elde yoksa (`E == 0`) `{a}` adresine atlar. |
| `0x77` | `KMT_NEGATIFSE_ATLA` | `{a} NEGATİFSE ATLA` | 3 bayt | Sonuç negatifse (`N == 1`) `{a}` adresine atlar. |
| `0x78` | `KMT_POZITIFSE_ATLA` | `{a} POZİTİFSE ATLA` | 3 bayt | Sonuç pozitif veya sıfırsa (`N == 0`) `{a}` adresine atlar. |
| `0x79` | `KMT_TASMA_VARSA_ATLA` | `{a} TAŞMA VARSA ATLA` | 3 bayt | İşaretli taşma varsa (`T == 1`) `{a}` adresine atlar. |
| `0x7A` | `KMT_KUCUK_ESITSE_ATLA` | `{a} KÜÇÜK VEYA EŞİTSE ATLA` | 3 bayt | İşaretsiz karşılaştırmada küçük veya eşitse (`E == 0` veya `S == 1`) `{a}` adresine atlar. |
| `0x7B` | `KMT_ATLA_DOLAYLI` | `[{a}] ATLA` | 3 bayt | `{a}` adresinde kayıtlı 16-bit hedefe dolaylı atlar (`PS = [{a}]`). |
| `0x7C` | `KMT_CAGIR_DOLAYLI` | `[{a}] ÇAĞIR` | 3 bayt | `{a}` adresinde kayıtlı 16-bit alt programı dolaylı çağırır. |
| `0x90` | `KMT_CAGIR` | `{a} ÇAĞIR` | 3 bayt | Dönüş adresini yığına itip `{a}` alt programını çağırır (`CALL`). |
| `0x91` | `KMT_DON` | `DÖN` | 1 bayt | Yığından dönüş adresini çekip alt programdan döner (`RET`). |
| `0x92` | `KMT_KESMEDEN_DON` | `KESMEDEN DÖN` | 1 bayt | Yığından `DURUM` ve `PS` değerlerini çekip kesmeden döner (`RTI`). |
| `0x93` | `KMT_IT_T` | `T İT` | 1 bayt | `T` yazmacını donanım yığınına iter (`PUSH T`). |
| `0x94` | `KMT_CEK_T` | `T ÇEK` | 1 bayt | Donanım yığınından 1 bayt çekip `T` yazmacına yazar (`POP T`). |
| `0x95` | `KMT_IT_DURUM` | `DURUM İT` | 1 bayt | `DURUM` bayrak yazmacını yığına iter. |
| `0x96` | `KMT_CEK_DURUM` | `DURUM ÇEK` | 1 bayt | Yığından 1 bayt çekip `DURUM` bayrak yazmacına yazar. |
| `0x97` | `KMT_IT_X` | `X İT` | 1 bayt | `X` indeks yazmacını yığına iter (`PUSH X`). |
| `0x98` | `KMT_CEK_X` | `X ÇEK` | 1 bayt | Yığından 1 bayt çekip `X` indeks yazmacına yazar (`POP X`). |
| `0x99` | `KMT_IT_Y` | `Y İT` | 1 bayt | `Y` indeks yazmacını yığına iter (`PUSH Y`). |
| `0x9A` | `KMT_CEK_Y` | `Y ÇEK` | 1 bayt | Yığından 1 bayt çekip `Y` indeks yazmacına yazar (`POP Y`). |
| `0xB0` | `KMT_GIRIS` | `{n} GİRİŞ` | 2 bayt | `0xA000 + {n}` MMIO portundan 1 bayt okuyup `T` yazmacına yükler. |
| `0xB1` | `KMT_CIKIS` | `{n} ÇIKIŞ` | 2 bayt | `T` yazmacındaki baytı `0xA000 + {n}` MMIO portuna yazar. |
| `0x75` *(takma ad)* | `KMT_ELDE_VARSA_ATLA` | `{a} BÜYÜK VEYA EŞİTSE ATLA` | 3 bayt | `ELDE VARSA ATLA` ile aynı opkoda derlenir (işaretsiz $\ge$). |
