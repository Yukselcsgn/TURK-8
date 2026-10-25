; =============================================================================
; TÜRK-8 TÜRKÇE BASIC YORUMLAYICISI (v1.0)
; Başlangıç Adresi : 0x0200 (Sanal Diskten "BASIC" veya "BASIC ÇALIŞTIR" ile açılır)
; Program Alanı    : 0x1800 - 0x6FFF (~22 KB Kullanıcı BASIC Program Belleği)
;
; Desteklenen Komutlar (Hem Doğal Türkçe SOV Hem Klasik BASIC Düzeni):
;   - Satır Girişi : 10 "MERHABA" YAZ  veya  SATIR 10 YAZ "MERHABA"
;   - Satır Silme  : 10 (yalnızca satır numarası yazılıp Enter'a basılır)
;   - YAZ          : "METİN", A, B + 1 YAZ   |   YAZ "METİN", A
;   - GİRDİ        : T GİRDİ                 |   GİRDİ T
;   - Atama        : A = 5, A = B + RASTGELE % 10
;   - EĞER ... İSE : EĞER A = 5 İSE 100 GİT  |   EĞER A < 10 İSE "KÜÇÜK" YAZ
;   - GİT          : 100 GİT                 |   GİT 100
;   - ÇAĞIR / DÖN  : 500 ÇAĞIR ... DÖN       |   ÇAĞIR 500 ... DÖN
;   - DÖNGÜ/SONRAKİ: DÖNGÜ I = 1 BİTİŞ 10 ... I SONRAKİ (veya SONRAKİ I)
;   - SES          : 80, 5 SES               |   SES 80, 5
;   - TEMİZLE      : Ekranı siler (0 SİSTEM)
;   - BİTİR / DUR  : Program çalışmasını sonlandırır
;   - LİSTELE      : Bellekteki BASIC programını satır sırasıyla listeler
;   - ÇALIŞTIR     : Programı ilk satırdan itibaren çalıştırır
;   - YENİ         : Bellekteki BASIC programını ve değişkenleri sıfırlar
;   - KAYDET       : <AD> KAYDET  |  KAYDET <AD>  (Programı disk.t8'e kaydeder)
;   - YÜKLE        : <AD> YÜKLE   |  YÜKLE <AD>   (Programı disk.t8'den yükler)
;   - ÇIK          : BASIC'ten çıkıp BIOS komut istemine (> ) döner
; =============================================================================

; --- Sıfır Sayfa Donanım ve Blok Yazmaçları ---
.TANIM BLOK_KAYNAK_ALT  0x0000
.TANIM BLOK_KAYNAK_UST  0x0001
.TANIM BLOK_HEDEF_ALT   0x0002
.TANIM BLOK_HEDEF_UST   0x0003
.TANIM BLOK_UZUNLUK_ALT 0x0004
.TANIM BLOK_UZUNLUK_UST 0x0005

; --- BASIC Sıfır Sayfa Değişkenleri (0x0020 - 0x004F) ---
.TANIM BAS_OKU_INDEKS   0x0020  ; BAS_AKTIF_SATIR içindeki okuma indeksi
.TANIM BAS_CALIS_MODU   0x0021  ; 0 = etkileşimli istem (]), 1 = program çalışıyor
.TANIM BAS_PC_ALT       0x0022  ; Çalışan satır kaydının adresi (alt)
.TANIM BAS_PC_UST       0x0023  ; Çalışan satır kaydının adresi (üst)
.TANIM BAS_SON_ALT      0x0024  ; Program sonundaki (0x00,0x00) işaretçisi (alt)
.TANIM BAS_SON_UST      0x0025  ; Program sonundaki (0x00,0x00) işaretçisi (üst)
.TANIM BAS_GEC_ALT      0x0026  ; Genel amaçlı 16-bit işaretçi 1 (alt)
.TANIM BAS_GEC_UST      0x0027  ; Genel amaçlı 16-bit işaretçi 1 (üst)
.TANIM BAS_GEC2_ALT     0x0028  ; Genel amaçlı 16-bit işaretçi 2 (alt)
.TANIM BAS_GEC2_UST     0x0029  ; Genel amaçlı 16-bit işaretçi 2 (üst)
.TANIM BAS_SATIR_NO_ALT 0x002A  ; Çözümlenen 16-bit satır numarası (alt)
.TANIM BAS_SATIR_NO_UST 0x002B  ; Çözümlenen 16-bit satır numarası (üst)
.TANIM BAS_SOL_DEGER    0x002C  ; İfade sol işlenen değeri
.TANIM BAS_SAG_DEGER    0x002D  ; İfade sağ işlenen değeri
.TANIM BAS_ISLEC        0x002E  ; Aritmetik işleç ('+', '-', '*', '/', '%')
.TANIM BAS_DEGISKEN_ID  0x002F  ; Değişken indeksi (0..25 -> A..Z)
.TANIM BAS_DONGU_DEG    0x0030  ; Aktif DÖNGÜ değişkeni (0..25, 0xFF = yok)
.TANIM BAS_DONGU_BITIS  0x0031  ; Aktif DÖNGÜ bitiş sınırı
.TANIM BAS_DONGU_PC_ALT 0x0032  ; DÖNGÜ gövdesi başlangıç satırı adresi (alt)
.TANIM BAS_DONGU_PC_UST 0x0033  ; DÖNGÜ gövdesi başlangıç satırı adresi (üst)
.TANIM BAS_CAGIR_SP     0x0034  ; ÇAĞIR/DÖN yığın indeksi (0..14)
.TANIM BAS_ATLA_VAR     0x0035  ; 1 = GİT/ÇAĞIR/SONRAKİ PC'yi değiştirdi
.TANIM BAS_KAYIT_BOYUT  0x0036  ; Satır kaydı toplam uzunluğu (3 + metin + 1)
.TANIM BAS_KARSILASTIR  0x0037  ; EĞER karşılaştırma kodu (1..6)
.TANIM BAS_SABLON_ALT   0x0038  ; Komut şablonu adresi (alt)
.TANIM BAS_SABLON_UST   0x0039  ; Komut şablonu adresi (üst)
.TANIM BAS_GECICI_BAYT  0x003A  ; Geçici karşılaştırma/aritmetik baytı
.TANIM BAS_CARP_SAYAC   0x003B  ; Çarpma/bölme döngü sayacı
.TANIM BAS_KALAN        0x003C  ; Bölme kalanı / mod sonucu
.TANIM BAS_SON_KELIME   0x003D  ; Satırdaki son kelimenin başlangıç indeksi
.TANIM BAS_TIRNAK       0x003E  ; Tırnak durumu (0 = dışarıda, 34 = " içinde)
.TANIM BAS_DIZIN_OFSET  0x003F  ; Disk dizin arama ofseti
.TANIM BAS_BOS_GIRIS    0x0040  ; Disk ilk boş dizin girişi
.TANIM BAS_SON_SEKTOR   0x0041  ; Disk ilk boş veri sektörü
.TANIM BAS_SEKTOR_SAYI  0x0042  ; Disk sektör sayısı
.TANIM BAS_ONLUK_BAS    0x0043  ; 16-bit onluk yazdırma sıfır bastırma bayrağı

; --- Sabit Bellek Tamponları ---
.TANIM SATIR_TAMPONU    0x0080  ; BIOS Servis 5 satır okuma tamponu (0x0080-0x00BF)
.TANIM DOSYA_AD_TAMPON  0x00C0  ; 8 baytlık dosya adı tamponu (0x00C0-0x00C7)
.TANIM BAS_AKTIF_SATIR  0x0140  ; Çalıştırılan satırın çalışma kopyası (0x0140-0x017F)
.TANIM BAS_DEGISKENLER  0x0180  ; 26 adet 8-bit değişken: A..Z (0x0180-0x0199)
.TANIM BAS_CAGIR_YIGIN  0x01A0  ; 8 seviyeli ÇAĞIR/DÖN yığını (0x01A0-0x01AF)
.TANIM BAS_PROG_TABAN   0x1800  ; BASIC program satırları başlangıç adresi
.TANIM BAS_PROG_TABAN_1 0x1801  ; BASIC program sonu nöbetçi üst baytı
.TANIM DIZIN_TAMPONU    0x7F00  ; Disk dizin sektörü tamponu (0x7F00-0x7FFF)

; --- Donanım Portları ---
.TANIM PORT_KLAVYE_VERI  0xA000
.TANIM PORT_KLAVYE_DURUM 0xA001
.TANIM PORT_DISK_KOMUT   0xA010
.TANIM PORT_DISK_DURUM   0xA011
.TANIM PORT_DISK_SEKTOR  0xA012
.TANIM PORT_DISK_ADR_ALT 0xA013
.TANIM PORT_DISK_ADR_UST 0xA014
.TANIM PORT_DISK_SAYI    0xA015

.BAŞLANGIÇ 0x0200

; =============================================================================
; 1. BAŞLATMA VE ANA ETKİLEŞİMLİ DÖNGÜ (REPL)
; =============================================================================
basic_giris:
    ; Program alanını ve değişkenleri sıfırla
    bas_yeni_program ÇAĞIR

    ; Açılış başlığını yazdır
    <metin_bas_acilis X YÜKLE
    >metin_bas_acilis Y YÜKLE
    2 SİSTEM

bas_istem_dongusu:
    0 T YÜKLE
    T [BAS_CALIS_MODU] SAKLA

    ; İstem: "] "
    ']' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

    ; Kullanıcıdan bir satır oku (SATIR_TAMPONU = 0x0080)
    5 SİSTEM

    ; SATIR_TAMPONU -> BAS_AKTIF_SATIR kopyala, normalize et ve yorumları temizle
    bas_satir_hazirla ÇAĞIR

    ; Boş satır mı?
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_istem_dongusu EŞİTSE ATLA

    ; İsteğe bağlı "SATIR <no> ..." öneki var mı?
    <kmt_satir_oneki X YÜKLE
    >kmt_satir_oneki Y YÜKLE
    bas_onek_eslesir_mi ÇAĞIR

    ; Satır bir rakamla ('0'..'9') mı başlıyor?
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '0' KARŞILAŞTIR
    bas_dogrudan_komut KÜÇÜKSE ATLA
    ':' KARŞILAŞTIR
    bas_numarali_satir KÜÇÜKSE ATLA

bas_dogrudan_komut:
    ; ÇIK komutu mu? (BIOS kabuğuna dön)
    <kmt_cik X YÜKLE
    >kmt_cik Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_bios_don EŞİTSE ATLA

    ; Doğrudan komutu çalıştır
    bas_komut_calistir ÇAĞIR
    [BAS_CALIS_MODU] T YÜKLE
    1 KARŞILAŞTIR
    bas_program_dongusu EŞİTSE ATLA
    bas_istem_dongusu ATLA

bas_bios_don:
    DÖN

; =============================================================================
; 2. NUMARALI PROGRAM SATIRI EKLEME / GÜNCELLEME / SİLME
; =============================================================================
bas_numarali_satir:
    ; Eğer "25 + 17 YAZ", "25+17 YAZ", "80, 5 SES" veya "42 YAZ" gibi doğrudan
    ; ifade/komut girildiyse satır numarası değil anlık komut olarak çalıştır!
    [BAS_OKU_INDEKS] T YÜKLE
    T İT
    bas_onluk_kelime_oku ÇAĞIR
    0 KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA

    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '+' KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA
    '-' KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA
    '*' KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA
    '/' KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA
    '%' KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA
    ',' KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA

    ; Sayıdan sonra yalnızca tek başına "YAZ" varsa (örn. "42 YAZ"), anlık komuttur
    <kmt_yaz X YÜKLE
    >kmt_yaz Y YÜKLE
    bas_onek_eslesir_mi ÇAĞIR
    0 KARŞILAŞTIR
    bas_numarali_onay EŞİTSE ATLA
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_numarali_degil EŞİTSE ATLA

    ; "10 YAZ ..." gibi klasik numaralı satırdı: "YAZ" kelimesinin başına geri al
    T ÇEK
    T [BAS_OKU_INDEKS] SAKLA
    bas_onluk_kelime_oku ÇAĞIR
    bas_bosluk_atla ÇAĞIR
    bas_numarali_devam ATLA

bas_numarali_degil:
    T ÇEK
    T [BAS_OKU_INDEKS] SAKLA
    bas_dogrudan_komut ATLA

bas_numarali_onay:
    T ÇEK

bas_numarali_devam:
    ; Satır numarası 0 olamaz
    [BAS_SATIR_NO_ALT] T YÜKLE
    [BAS_SATIR_NO_UST] VEYA
    0 KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    bas_bosluk_atla ÇAĞIR

    ; Bu satır numarasını program alanında ara -> BAS_GEC, T=1 ise mevcut
    bas_satir_ara ÇAĞIR
    1 KARŞILAŞTIR
    bas_eski_satiri_sil EŞİTSE ATLA
    bas_yeni_satir_kontrol ATLA

bas_eski_satiri_sil:
    ; [[BAS_GEC] + 2] = eski kaydın uzunluğu
    2 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    T [BAS_KAYIT_BOYUT] SAKLA

    ; BLOK_HEDEF = BAS_GEC
    [BAS_GEC_ALT] T YÜKLE
    T [BLOK_HEDEF_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    T [BLOK_HEDEF_UST] SAKLA

    ; BLOK_KAYNAK = BAS_GEC + BAS_KAYIT_BOYUT
    [BAS_GEC_ALT] T YÜKLE
    [BAS_KAYIT_BOYUT] TOPLA
    T [BLOK_KAYNAK_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BLOK_KAYNAK_UST] SAKLA

    ; BLOK_UZUNLUK = (BAS_SON + 2) - BLOK_KAYNAK
    [BAS_SON_ALT] T YÜKLE
    2 TOPLA
    T [BAS_GEC2_ALT] SAKLA
    [BAS_SON_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_GEC2_UST] SAKLA

    [BAS_GEC2_ALT] T YÜKLE
    [BLOK_KAYNAK_ALT] ÇIKAR
    T [BLOK_UZUNLUK_ALT] SAKLA
    [BAS_GEC2_UST] T YÜKLE
    bas_sil_borc_yok ELDE VARSA ATLA
    [BLOK_KAYNAK_UST] ÇIKAR
    T AZALT
    bas_sil_kopyala ATLA
bas_sil_borc_yok:
    [BLOK_KAYNAK_UST] ÇIKAR
bas_sil_kopyala:
    T [BLOK_UZUNLUK_UST] SAKLA
    KOPYALA

    ; BAS_SON = BAS_SON - BAS_KAYIT_BOYUT
    [BAS_SON_ALT] T YÜKLE
    [BAS_KAYIT_BOYUT] ÇIKAR
    T [BAS_SON_ALT] SAKLA
    bas_sil_son_tamam ELDE VARSA ATLA
    [BAS_SON_UST] AZALT
bas_sil_son_tamam:

bas_yeni_satir_kontrol:
    ; Satır numarasından sonra metin yoksa yalnızca silme yapılmıştır
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_istem_dongusu EŞİTSE ATLA

    ; Metin uzunluğunu ölç -> Y
    0 Y YÜKLE
bas_boyut_olc:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_boyut_tamam EŞİTSE ATLA
    X ARTIR
    Y ARTIR
    bas_boyut_olc ATLA

bas_boyut_tamam:
    ; Kayıt boyutu = 3 (başlık) + Y (metin) + 1 ('\0') = Y + 4
    Y T AKTAR
    4 TOPLA
    T [BAS_KAYIT_BOYUT] SAKLA

    ; Kuyruğu BAS_KAYIT_BOYUT kadar ileri kaydır:
    ; BLOK_KAYNAK = BAS_GEC
    [BAS_GEC_ALT] T YÜKLE
    T [BLOK_KAYNAK_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    T [BLOK_KAYNAK_UST] SAKLA

    ; BLOK_HEDEF = BAS_GEC + BAS_KAYIT_BOYUT
    [BAS_GEC_ALT] T YÜKLE
    [BAS_KAYIT_BOYUT] TOPLA
    T [BLOK_HEDEF_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BLOK_HEDEF_UST] SAKLA

    ; BLOK_UZUNLUK = (BAS_SON + 2) - BAS_GEC
    [BAS_SON_ALT] T YÜKLE
    2 TOPLA
    T [BAS_GEC2_ALT] SAKLA
    [BAS_SON_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_GEC2_UST] SAKLA

    [BAS_GEC2_ALT] T YÜKLE
    [BAS_GEC_ALT] ÇIKAR
    T [BLOK_UZUNLUK_ALT] SAKLA
    [BAS_GEC2_UST] T YÜKLE
    bas_ekle_borc_yok ELDE VARSA ATLA
    [BAS_GEC_UST] ÇIKAR
    T AZALT
    bas_ekle_kopyala ATLA
bas_ekle_borc_yok:
    [BAS_GEC_UST] ÇIKAR
bas_ekle_kopyala:
    T [BLOK_UZUNLUK_UST] SAKLA
    KOPYALA

    ; BAS_SON = BAS_SON + BAS_KAYIT_BOYUT
    [BAS_SON_ALT] T YÜKLE
    [BAS_KAYIT_BOYUT] TOPLA
    T [BAS_SON_ALT] SAKLA
    [BAS_SON_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_SON_UST] SAKLA

    ; Yeni kaydın başlığını (satir_no_alt, satir_no_ust, kayit_boyut) yaz
    0 Y YÜKLE
    [BAS_SATIR_NO_ALT] T YÜKLE
    T [[BAS_GEC_ALT] + Y] SAKLA
    1 Y YÜKLE
    [BAS_SATIR_NO_UST] T YÜKLE
    T [[BAS_GEC_ALT] + Y] SAKLA
    2 Y YÜKLE
    [BAS_KAYIT_BOYUT] T YÜKLE
    T [[BAS_GEC_ALT] + Y] SAKLA

    ; Metni [BAS_GEC + 3..] içine kopyala
    3 Y YÜKLE
    [BAS_OKU_INDEKS] X YÜKLE
bas_metin_yaz_dongu:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    T [[BAS_GEC_ALT] + Y] SAKLA
    0 KARŞILAŞTIR
    bas_istem_dongusu EŞİTSE ATLA
    X ARTIR
    Y ARTIR
    bas_metin_yaz_dongu ATLA

; -----------------------------------------------------------------------------
; bas_satir_ara:
; BAS_PROG_TABAN (0x1800) başından itibaren BAS_SATIR_NO numaralı satırı arar.
; Çıktı:
;   BAS_GEC_ALT/UST = bulunan veya eklenecek kayıt adresi
;   T = 1 (tam eşleşme bulundu), T = 0 (bulunamadı, BAS_GEC ekleme noktasında)
; -----------------------------------------------------------------------------
bas_satir_ara:
    <BAS_PROG_TABAN T YÜKLE
    T [BAS_GEC_ALT] SAKLA
    >BAS_PROG_TABAN T YÜKLE
    T [BAS_GEC_UST] SAKLA

bas_ara_dongu:
    ; Kayıt satır numarası 0x0000 ise program sonuna geldik
    0 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    T [BAS_GECICI_BAYT] SAKLA
    1 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    [BAS_GECICI_BAYT] VEYA
    0 KARŞILAŞTIR
    bas_ara_yok EŞİTSE ATLA

    ; Üst baytı karşılaştır: [[BAS_GEC]+1] ile [BAS_SATIR_NO_UST]
    1 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    [BAS_SATIR_NO_UST] KARŞILAŞTIR
    bas_ara_ilerle KÜÇÜKSE ATLA
    bas_ara_yok BÜYÜKSE ATLA

    ; Üst baytlar eşit; alt baytı karşılaştır: [[BAS_GEC]+0] ile [BAS_SATIR_NO_ALT]
    0 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    [BAS_SATIR_NO_ALT] KARŞILAŞTIR
    bas_ara_bulundu EŞİTSE ATLA
    bas_ara_yok BÜYÜKSE ATLA

bas_ara_ilerle:
    2 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    [BAS_GEC_ALT] TOPLA
    T [BAS_GEC_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_GEC_UST] SAKLA
    bas_ara_dongu ATLA

bas_ara_bulundu:
    1 T YÜKLE
    DÖN

bas_ara_yok:
    0 T YÜKLE
    DÖN

; =============================================================================
; 3. PROGRAM ÇALIŞTIRMA DÖNGÜSÜ (ÇALIŞTIR)
; =============================================================================
bas_kmt_calistir:
    <BAS_PROG_TABAN T YÜKLE
    T [BAS_PC_ALT] SAKLA
    >BAS_PROG_TABAN T YÜKLE
    T [BAS_PC_UST] SAKLA
    0 T YÜKLE
    T [BAS_CAGIR_SP] SAKLA
    0xFF T YÜKLE
    T [BAS_DONGU_DEG] SAKLA
    1 T YÜKLE
    T [BAS_CALIS_MODU] SAKLA
    T [BAS_ATLA_VAR] SAKLA
    DÖN

bas_program_dongusu:
    ; BAS_PC kaydındaki satır numarası 0x0000 mı? (Program bitti)
    0 Y YÜKLE
    [[BAS_PC_ALT] + Y] T YÜKLE
    T [BAS_GECICI_BAYT] SAKLA
    1 Y YÜKLE
    [[BAS_PC_ALT] + Y] T YÜKLE
    [BAS_GECICI_BAYT] VEYA
    0 KARŞILAŞTIR
    bas_program_bitti EŞİTSE ATLA

    ; Kayıttaki metni ([BAS_PC + 3..]) BAS_AKTIF_SATIR içine kopyala
    3 Y YÜKLE
    0 X YÜKLE
bas_prog_satir_kopyala:
    [[BAS_PC_ALT] + Y] T YÜKLE
    T [BAS_AKTIF_SATIR + X] SAKLA
    0 KARŞILAŞTIR
    bas_prog_satir_hazir EŞİTSE ATLA
    X ARTIR
    Y ARTIR
    bas_prog_satir_kopyala ATLA

bas_prog_satir_hazir:
    0 T YÜKLE
    T [BAS_OKU_INDEKS] SAKLA
    T [BAS_ATLA_VAR] SAKLA

    ; Satırı çalıştır
    bas_komut_calistir ÇAĞIR

    ; Program durduruldu mu? (BİTİR / DUR veya hata)
    [BAS_CALIS_MODU] T YÜKLE
    0 KARŞILAŞTIR
    bas_istem_dongusu EŞİTSE ATLA

    ; GİT / ÇAĞIR / SONRAKİ BAS_PC'yi zaten değiştirdi mi?
    [BAS_ATLA_VAR] T YÜKLE
    1 KARŞILAŞTIR
    bas_program_dongusu EŞİTSE ATLA

    ; Sıradaki satıra ilerle: BAS_PC = BAS_PC + [[BAS_PC] + 2]
    2 Y YÜKLE
    [[BAS_PC_ALT] + Y] T YÜKLE
    [BAS_PC_ALT] TOPLA
    T [BAS_PC_ALT] SAKLA
    [BAS_PC_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_PC_UST] SAKLA
    bas_program_dongusu ATLA

bas_program_bitti:
    0 T YÜKLE
    T [BAS_CALIS_MODU] SAKLA
    bas_istem_dongusu ATLA

; =============================================================================
; 4. TEK SATIR KOMUT AYRIŞTIRICI VE YÜRÜTÜCÜ (bas_komut_calistir)
; =============================================================================
bas_komut_calistir:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_komut_cik EŞİTSE ATLA

    ; Yorum satırı mı? ('REM' veya ';')
    ';' KARŞILAŞTIR
    bas_komut_cik EŞİTSE ATLA
    <kmt_rem X YÜKLE
    >kmt_rem Y YÜKLE
    bas_onek_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_komut_cik EŞİTSE ATLA

    ; --- 1) EĞER <koşul> İSE <komut> ---
    <kmt_eger X YÜKLE
    >kmt_eger Y YÜKLE
    bas_onek_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_eger EŞİTSE ATLA

    ; --- 2) DÖNGÜ I = <baş> BİTİŞ <son> ---
    <kmt_dongu X YÜKLE
    >kmt_dongu Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_dongu EŞİTSE ATLA

    ; --- 3) SONRAKİ [I] ---
    <kmt_sonraki X YÜKLE
    >kmt_sonraki Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_sonraki EŞİTSE ATLA

    ; --- 4) YAZ <ifade/metin> [, ...] ---
    <kmt_yaz X YÜKLE
    >kmt_yaz Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_yaz EŞİTSE ATLA

    ; --- 5) GİRDİ <değişken> ---
    <kmt_girdi X YÜKLE
    >kmt_girdi Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_girdi EŞİTSE ATLA

    ; --- 6) GİT <satır_no> ---
    <kmt_git X YÜKLE
    >kmt_git Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_git EŞİTSE ATLA

    ; --- 7) ÇAĞIR <satır_no> ---
    <kmt_cagir X YÜKLE
    >kmt_cagir Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_cagir EŞİTSE ATLA

    ; --- 8) DÖN ---
    <kmt_don X YÜKLE
    >kmt_don Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_don EŞİTSE ATLA

    ; --- 9) SES <frekans>, <süre> ---
    <kmt_ses X YÜKLE
    >kmt_ses Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_ses EŞİTSE ATLA

    ; --- 10) TEMİZLE ---
    <kmt_temizle X YÜKLE
    >kmt_temizle Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_temizle EŞİTSE ATLA

    ; --- 11) BİTİR / DUR ---
    <kmt_bitir X YÜKLE
    >kmt_bitir Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_bitir EŞİTSE ATLA

    <kmt_dur X YÜKLE
    >kmt_dur Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_bitir EŞİTSE ATLA

    ; --- 12) LİSTELE / LİSTE ---
    <kmt_listele X YÜKLE
    >kmt_listele Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_listele EŞİTSE ATLA

    <kmt_liste X YÜKLE
    >kmt_liste Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_listele EŞİTSE ATLA

    ; --- 13) ÇALIŞTIR ---
    <kmt_calistir X YÜKLE
    >kmt_calistir Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_calistir EŞİTSE ATLA

    ; --- 14) YENİ ---
    <kmt_yeni X YÜKLE
    >kmt_yeni Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_yeni EŞİTSE ATLA

    ; --- 15) KAYDET <ad> ---
    <kmt_kaydet X YÜKLE
    >kmt_kaydet Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_kaydet EŞİTSE ATLA

    ; --- 16) YÜKLE <ad> ---
    <kmt_yukle X YÜKLE
    >kmt_yukle Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_kmt_yukle EŞİTSE ATLA

    ; --- 17) Değişken Ataması: <A..Z> = <ifade> ---
    ; İsteğe bağlı "OLSUN" kelimesini atla
    <kmt_olsun X YÜKLE
    >kmt_olsun Y YÜKLE
    bas_komut_eslesir_mi ÇAĞIR

    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    'A' KARŞILAŞTIR
    bas_soz_dizimi_hatasi KÜÇÜKSE ATLA
    '[' KARŞILAŞTIR
    bas_soz_dizimi_hatasi BÜYÜK VEYA EŞİTSE ATLA

    'A' ÇIKAR
    T [BAS_DEGISKEN_ID] SAKLA
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '=' KARŞILAŞTIR
    bas_soz_dizimi_hatasi FARKLIYSA ATLA
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA

    bas_ifade_hesapla ÇAĞIR
    [BAS_DEGISKEN_ID] X YÜKLE
    T [BAS_DEGISKENLER + X] SAKLA
bas_komut_cik:
    DÖN

bas_soz_dizimi_hatasi:
    <metin_bas_hata X YÜKLE
    >metin_bas_hata Y YÜKLE
    2 SİSTEM
    0 T YÜKLE
    T [BAS_CALIS_MODU] SAKLA
    DÖN

; =============================================================================
; 5. BASIC KOMUT İŞLEYİCİLERİ
; =============================================================================

; -----------------------------------------------------------------------------
; YAZ: Metin ("...") ve/veya sayısal ifadeleri ekrana basar.
; -----------------------------------------------------------------------------
bas_kmt_yaz:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_yaz_alt_satir EŞİTSE ATLA

bas_yaz_oge_dongu:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_yaz_alt_satir EŞİTSE ATLA

    ; Çift tırnaklı metin mi?
    34 KARŞILAŞTIR          ; '"'
    bas_yaz_metin EŞİTSE ATLA

    ; Sayısal ifade hesapla ve onluk tabanda yazdır
    bas_ifade_hesapla ÇAĞIR
    bas_onluk_bayt_yaz ÇAĞIR
    bas_yaz_ayirici_kontrol ATLA

bas_yaz_metin:
    X ARTIR
bas_yaz_metin_ic:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_yaz_metin_son EŞİTSE ATLA
    34 KARŞILAŞTIR
    bas_yaz_metin_kapat EŞİTSE ATLA
    X İT
    1 SİSTEM
    X ÇEK
    X ARTIR
    bas_yaz_metin_ic ATLA

bas_yaz_metin_kapat:
    X ARTIR
bas_yaz_metin_son:
    X [BAS_OKU_INDEKS] SAKLA

bas_yaz_ayirici_kontrol:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    ',' KARŞILAŞTIR
    bas_yaz_virgul EŞİTSE ATLA
    ';' KARŞILAŞTIR
    bas_yaz_noktali_virgul EŞİTSE ATLA
    bas_yaz_alt_satir ATLA

bas_yaz_virgul:
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA
    bas_yaz_oge_dongu ATLA

bas_yaz_noktali_virgul:
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_yaz_cik EŞİTSE ATLA
    bas_yaz_oge_dongu ATLA

bas_yaz_alt_satir:
    10 T YÜKLE
    1 SİSTEM
bas_yaz_cik:
    DÖN

; -----------------------------------------------------------------------------
; GİRDİ: Kullanıcıdan sayı okur ve belirtilen A..Z değişkenine yazar.
; -----------------------------------------------------------------------------
bas_kmt_girdi:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    'A' KARŞILAŞTIR
    bas_soz_dizimi_hatasi KÜÇÜKSE ATLA
    '[' KARŞILAŞTIR
    bas_soz_dizimi_hatasi BÜYÜK VEYA EŞİTSE ATLA
    'A' ÇIKAR
    T [BAS_DEGISKEN_ID] SAKLA

    ; "? " istemi bas ve SATIR_TAMPONU'na (0x0080) satır oku
    '?' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM
    5 SİSTEM

    ; SATIR_TAMPONU içindeki onluk sayıyı çöz -> T
    0 X YÜKLE
bas_girdi_bosluk:
    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    bas_girdi_rakam_basla FARKLIYSA ATLA
    X ARTIR
    bas_girdi_bosluk ATLA

bas_girdi_rakam_basla:
    0 T YÜKLE
    T [BAS_SOL_DEGER] SAKLA
bas_girdi_rakam_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    '0' KARŞILAŞTIR
    bas_girdi_tamam KÜÇÜKSE ATLA
    ':' KARŞILAŞTIR
    bas_girdi_tamam BÜYÜK VEYA EŞİTSE ATLA
    '0' ÇIKAR
    T [BAS_GECICI_BAYT] SAKLA

    ; BAS_SOL_DEGER = BAS_SOL_DEGER * 10 + rakam
    [BAS_SOL_DEGER] T YÜKLE
    T SOLA KAYDIR
    T [BAS_SAG_DEGER] SAKLA     ; * 2
    T SOLA KAYDIR
    T SOLA KAYDIR               ; * 8
    [BAS_SAG_DEGER] TOPLA       ; * 10
    [BAS_GECICI_BAYT] TOPLA
    T [BAS_SOL_DEGER] SAKLA
    X ARTIR
    bas_girdi_rakam_dongu ATLA

bas_girdi_tamam:
    [BAS_DEGISKEN_ID] X YÜKLE
    [BAS_SOL_DEGER] T YÜKLE
    T [BAS_DEGISKENLER + X] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; GİT <satır_no>: Belirtilen satır numarasına atlar.
; -----------------------------------------------------------------------------
bas_kmt_git:
    bas_bosluk_atla ÇAĞIR
    bas_onluk_kelime_oku ÇAĞIR
    0 KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    bas_satir_ara ÇAĞIR
    0 KARŞILAŞTIR
    bas_satir_yok_hatasi EŞİTSE ATLA

    [BAS_GEC_ALT] T YÜKLE
    T [BAS_PC_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    T [BAS_PC_UST] SAKLA
    1 T YÜKLE
    T [BAS_ATLA_VAR] SAKLA
    T [BAS_CALIS_MODU] SAKLA
    DÖN

bas_satir_yok_hatasi:
    <metin_bas_satir_yok X YÜKLE
    >metin_bas_satir_yok Y YÜKLE
    2 SİSTEM
    0 T YÜKLE
    T [BAS_CALIS_MODU] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; ÇAĞIR <satır_no> ve DÖN: Alt program çağrısı ve dönüşü.
; -----------------------------------------------------------------------------
bas_kmt_cagir:
    [BAS_CAGIR_SP] T YÜKLE
    16 KARŞILAŞTIR
    bas_soz_dizimi_hatasi BÜYÜK VEYA EŞİTSE ATLA

    ; Dönüş adresini (BAS_PC + kayit_boyutu) yığına kaydet
    2 Y YÜKLE
    [[BAS_PC_ALT] + Y] T YÜKLE
    [BAS_PC_ALT] TOPLA
    [BAS_CAGIR_SP] X YÜKLE
    T [BAS_CAGIR_YIGIN + X] SAKLA
    X ARTIR
    [BAS_PC_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_CAGIR_YIGIN + X] SAKLA
    X ARTIR
    X [BAS_CAGIR_SP] SAKLA

    bas_kmt_git ATLA

bas_kmt_don:
    [BAS_CAGIR_SP] T YÜKLE
    0 KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    [BAS_CAGIR_SP] X YÜKLE
    X AZALT
    [BAS_CAGIR_YIGIN + X] T YÜKLE
    T [BAS_PC_UST] SAKLA
    X AZALT
    [BAS_CAGIR_YIGIN + X] T YÜKLE
    T [BAS_PC_ALT] SAKLA
    X [BAS_CAGIR_SP] SAKLA

    1 T YÜKLE
    T [BAS_ATLA_VAR] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; EĞER <sol> <op> <sağ> İSE <komut>: Koşullu yürütme.
; -----------------------------------------------------------------------------
bas_kmt_eger:
    bas_ifade_hesapla ÇAĞIR
    T [BAS_SOL_DEGER] SAKLA

    ; Karşılaştırma operatörünü oku: =, <>, !=, <=, >=, <, >
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '=' KARŞILAŞTIR
    bas_op_esit EŞİTSE ATLA
    '!' KARŞILAŞTIR
    bas_op_unlem EŞİTSE ATLA
    '<' KARŞILAŞTIR
    bas_op_kucuk EŞİTSE ATLA
    '>' KARŞILAŞTIR
    bas_op_buyuk EŞİTSE ATLA
    bas_soz_dizimi_hatasi ATLA

bas_op_esit:
    X ARTIR
    1 T YÜKLE               ; 1: =
    bas_op_kaydet ATLA

bas_op_unlem:
    X ARTIR
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '=' KARŞILAŞTIR
    bas_soz_dizimi_hatasi FARKLIYSA ATLA
    X ARTIR
    2 T YÜKLE               ; 2: !=
    bas_op_kaydet ATLA

bas_op_kucuk:
    X ARTIR
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '>' KARŞILAŞTIR
    bas_op_farkli EŞİTSE ATLA
    '=' KARŞILAŞTIR
    bas_op_kucuk_esit EŞİTSE ATLA
    3 T YÜKLE               ; 3: <
    bas_op_kaydet ATLA
bas_op_farkli:
    X ARTIR
    2 T YÜKLE               ; 2: <>
    bas_op_kaydet ATLA
bas_op_kucuk_esit:
    X ARTIR
    5 T YÜKLE               ; 5: <=
    bas_op_kaydet ATLA

bas_op_buyuk:
    X ARTIR
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '=' KARŞILAŞTIR
    bas_op_buyuk_esit EŞİTSE ATLA
    4 T YÜKLE               ; 4: >
    bas_op_kaydet ATLA
bas_op_buyuk_esit:
    X ARTIR
    6 T YÜKLE               ; 6: >=

bas_op_kaydet:
    T [BAS_KARSILASTIR] SAKLA
    X [BAS_OKU_INDEKS] SAKLA

    ; Sağ ifadeyi hesapla
    bas_ifade_hesapla ÇAĞIR
    T [BAS_SAG_DEGER] SAKLA

    ; "İSE" ("ISE") anahtar kelimesini geç
    <kmt_ise X YÜKLE
    >kmt_ise Y YÜKLE
    bas_onek_eslesir_mi ÇAĞIR
    0 KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    ; BAS_SOL_DEGER ile BAS_SAG_DEGER'i kıyasla
    [BAS_KARSILASTIR] T YÜKLE
    1 KARŞILAŞTIR
    bas_kiyas_esit EŞİTSE ATLA
    2 KARŞILAŞTIR
    bas_kiyas_farkli EŞİTSE ATLA
    3 KARŞILAŞTIR
    bas_kiyas_kucuk EŞİTSE ATLA
    4 KARŞILAŞTIR
    bas_kiyas_buyuk EŞİTSE ATLA
    5 KARŞILAŞTIR
    bas_kiyas_kucuk_esit EŞİTSE ATLA

    ; 6: >=
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] KARŞILAŞTIR
    bas_eger_dogru BÜYÜK VEYA EŞİTSE ATLA
    DÖN

bas_kiyas_esit:
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] KARŞILAŞTIR
    bas_eger_dogru EŞİTSE ATLA
    DÖN

bas_kiyas_farkli:
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] KARŞILAŞTIR
    bas_eger_dogru FARKLIYSA ATLA
    DÖN

bas_kiyas_kucuk:
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] KARŞILAŞTIR
    bas_eger_dogru KÜÇÜKSE ATLA
    DÖN

bas_kiyas_buyuk:
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] KARŞILAŞTIR
    bas_eger_dogru BÜYÜKSE ATLA
    DÖN

bas_kiyas_kucuk_esit:
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] KARŞILAŞTIR
    bas_eger_dogru KÜÇÜK VEYA EŞİTSE ATLA
    DÖN

bas_eger_dogru:
    ; Koşul doğru: İSE'den sonraki komutu çalıştır!
    bas_komut_calistir ATLA

; -----------------------------------------------------------------------------
; DÖNGÜ I = <baş> BİTİŞ <son> ve SONRAKİ [I]
; -----------------------------------------------------------------------------
bas_kmt_dongu:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    'A' KARŞILAŞTIR
    bas_soz_dizimi_hatasi KÜÇÜKSE ATLA
    '[' KARŞILAŞTIR
    bas_soz_dizimi_hatasi BÜYÜK VEYA EŞİTSE ATLA
    'A' ÇIKAR
    T [BAS_DONGU_DEG] SAKLA

    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '=' KARŞILAŞTIR
    bas_soz_dizimi_hatasi FARKLIYSA ATLA
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA

    bas_ifade_hesapla ÇAĞIR
    [BAS_DONGU_DEG] X YÜKLE
    T [BAS_DEGISKENLER + X] SAKLA

    ; "BİTİŞ" ("BITIS") kelimesini geç
    <kmt_bitis X YÜKLE
    >kmt_bitis Y YÜKLE
    bas_onek_eslesir_mi ÇAĞIR
    0 KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    bas_ifade_hesapla ÇAĞIR
    T [BAS_DONGU_BITIS] SAKLA

    ; Döngü gövdesi başlangıç adresini (BAS_PC + kayit_boyutu) kaydet
    2 Y YÜKLE
    [[BAS_PC_ALT] + Y] T YÜKLE
    [BAS_PC_ALT] TOPLA
    T [BAS_DONGU_PC_ALT] SAKLA
    [BAS_PC_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_DONGU_PC_UST] SAKLA
    DÖN

bas_kmt_sonraki:
    [BAS_DONGU_DEG] X YÜKLE
    0xFF X KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    [BAS_DEGISKENLER + X] T YÜKLE
    [BAS_DONGU_BITIS] KARŞILAŞTIR
    bas_dongu_bitti BÜYÜK VEYA EŞİTSE ATLA

    T ARTIR
    T [BAS_DEGISKENLER + X] SAKLA
    [BAS_DONGU_PC_ALT] T YÜKLE
    T [BAS_PC_ALT] SAKLA
    [BAS_DONGU_PC_UST] T YÜKLE
    T [BAS_PC_UST] SAKLA
    1 T YÜKLE
    T [BAS_ATLA_VAR] SAKLA
    DÖN

bas_dongu_bitti:
    0xFF T YÜKLE
    T [BAS_DONGU_DEG] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; SES <frekans>, <süre> / TEMİZLE / BİTİR / YENİ / LİSTELE
; -----------------------------------------------------------------------------
bas_kmt_ses:
    bas_ifade_hesapla ÇAĞIR
    T İT
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE
    ',' KARŞILAŞTIR
    bas_ses_ikinci FARKLIYSA ATLA
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA
bas_ses_ikinci:
    bas_ifade_hesapla ÇAĞIR
    T Y AKTAR
    T ÇEK
    T X AKTAR
    7 SİSTEM
    DÖN

bas_kmt_temizle:
    0 SİSTEM
    DÖN

bas_kmt_bitir:
    0 T YÜKLE
    T [BAS_CALIS_MODU] SAKLA
    1 T YÜKLE
    T [BAS_ATLA_VAR] SAKLA
    DÖN

bas_kmt_yeni:
    bas_yeni_program ÇAĞIR
    DÖN

bas_yeni_program:
    <BAS_PROG_TABAN T YÜKLE
    T [BAS_SON_ALT] SAKLA
    >BAS_PROG_TABAN T YÜKLE
    T [BAS_SON_UST] SAKLA
    0 T YÜKLE
    T [BAS_PROG_TABAN] SAKLA
    T [BAS_PROG_TABAN_1] SAKLA
    T [BAS_CALIS_MODU] SAKLA
    T [BAS_CAGIR_SP] SAKLA
    0xFF T YÜKLE
    T [BAS_DONGU_DEG] SAKLA

    ; A..Z değişkenlerini (26 bayt) sıfırla
    0 T YÜKLE
    0 X YÜKLE
bas_deg_sifirla:
    T [BAS_DEGISKENLER + X] SAKLA
    X ARTIR
    26 X KARŞILAŞTIR
    bas_deg_sifirla FARKLIYSA ATLA
    DÖN

bas_kmt_listele:
    <BAS_PROG_TABAN T YÜKLE
    T [BAS_GEC_ALT] SAKLA
    >BAS_PROG_TABAN T YÜKLE
    T [BAS_GEC_UST] SAKLA

bas_listele_dongu:
    0 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    T [BAS_SATIR_NO_ALT] SAKLA
    1 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    T [BAS_SATIR_NO_UST] SAKLA
    [BAS_SATIR_NO_ALT] VEYA
    0 KARŞILAŞTIR
    bas_listele_cik EŞİTSE ATLA

    ; Satır numarasını onluk tabanda yazdır
    bas_onluk_kelime_yaz ÇAĞIR
    ' ' T YÜKLE
    1 SİSTEM

    ; Satır metnini ([BAS_GEC + 3..]) yazdır
    3 Y YÜKLE
bas_listele_metin:
    [[BAS_GEC_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    bas_listele_satir_sonu EŞİTSE ATLA
    Y İT
    1 SİSTEM
    Y ÇEK
    Y ARTIR
    bas_listele_metin ATLA

bas_listele_satir_sonu:
    10 T YÜKLE
    1 SİSTEM

    2 Y YÜKLE
    [[BAS_GEC_ALT] + Y] T YÜKLE
    [BAS_GEC_ALT] TOPLA
    T [BAS_GEC_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_GEC_UST] SAKLA
    bas_listele_dongu ATLA

bas_listele_cik:
    DÖN

; =============================================================================
; 6. SANAL DİSK KAYDET / YÜKLE (BAS_PROG_TABAN = 0x1800)
; =============================================================================
bas_kmt_kaydet:
    bas_dosya_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    ; Dizin sektörünü (sektör 0) 0x7F00'e oku
    0 T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    T [PORT_DISK_ADR_ALT] SAKLA
    0x7F T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    1 T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    T [PORT_DISK_KOMUT] SAKLA
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    bas_disk_hata_mesaj FARKLIYSA ATLA

    ; Aynı isimde dosya varsa sil (0xE5)
    bas_dizinde_ara ÇAĞIR
    0 KARŞILAŞTIR
    bas_kaydet_yer_bul EŞİTSE ATLA
    [BAS_DIZIN_OFSET] X YÜKLE
    0xE5 T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA

bas_kaydet_yer_bul:
    0xFF T YÜKLE
    T [BAS_BOS_GIRIS] SAKLA
    1 T YÜKLE
    T [BAS_SON_SEKTOR] SAKLA
    0 T YÜKLE
    T [BAS_DIZIN_OFSET] SAKLA

bas_kaydet_tara:
    [BAS_DIZIN_OFSET] X YÜKLE
    [DIZIN_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_kaydet_bos_aday EŞİTSE ATLA
    0xE5 KARŞILAŞTIR
    bas_kaydet_bos_aday EŞİTSE ATLA

    [BAS_DIZIN_OFSET] T YÜKLE
    8 TOPLA
    T X AKTAR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [BAS_GECICI_BAYT] SAKLA
    X ARTIR
    [DIZIN_TAMPONU + X] T YÜKLE
    [BAS_GECICI_BAYT] TOPLA
    [BAS_SON_SEKTOR] KARŞILAŞTIR
    bas_kaydet_tara_sonraki KÜÇÜK VEYA EŞİTSE ATLA
    T [BAS_SON_SEKTOR] SAKLA
    bas_kaydet_tara_sonraki ATLA

bas_kaydet_bos_aday:
    [BAS_BOS_GIRIS] T YÜKLE
    0xFF KARŞILAŞTIR
    bas_kaydet_tara_sonraki FARKLIYSA ATLA
    [BAS_DIZIN_OFSET] T YÜKLE
    T [BAS_BOS_GIRIS] SAKLA

bas_kaydet_tara_sonraki:
    [BAS_DIZIN_OFSET] T YÜKLE
    16 TOPLA
    T [BAS_DIZIN_OFSET] SAKLA
    0 KARŞILAŞTIR
    bas_kaydet_tara FARKLIYSA ATLA

    [BAS_BOS_GIRIS] T YÜKLE
    0xFF KARŞILAŞTIR
    bas_disk_hata_mesaj EŞİTSE ATLA

    ; Boyut = (BAS_SON + 2) - 0x1800
    [BAS_SON_ALT] T YÜKLE
    2 TOPLA
    T [BAS_GEC2_ALT] SAKLA
    [BAS_SON_UST] T YÜKLE
    0 ELDEYLE TOPLA
    0x18 ÇIKAR
    T [BAS_GEC2_UST] SAKLA

    ; Sektör sayısı = BAS_GEC2_UST + (BAS_GEC2_ALT > 0 ? 1 : 0)
    T [BAS_SEKTOR_SAYI] SAKLA
    [BAS_GEC2_ALT] T YÜKLE
    0 KARŞILAŞTIR
    bas_sektor_kontrol EŞİTSE ATLA
    [BAS_SEKTOR_SAYI] ARTIR
bas_sektor_kontrol:
    [BAS_SEKTOR_SAYI] T YÜKLE
    0 KARŞILAŞTIR
    bas_veri_yaz FARKLIYSA ATLA
    1 T YÜKLE
    T [BAS_SEKTOR_SAYI] SAKLA

bas_veri_yaz:
    [BAS_SON_SEKTOR] T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    <BAS_PROG_TABAN T YÜKLE
    T [PORT_DISK_ADR_ALT] SAKLA
    >BAS_PROG_TABAN T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    [BAS_SEKTOR_SAYI] T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    2 T YÜKLE
    T [PORT_DISK_KOMUT] SAKLA
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    bas_disk_hata_mesaj FARKLIYSA ATLA

    ; Dizin girişini yaz
    [BAS_BOS_GIRIS] X YÜKLE
    0 Y YÜKLE
bas_isim_yaz:
    [DOSYA_AD_TAMPON + Y] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    Y ARTIR
    8 Y KARŞILAŞTIR
    bas_isim_yaz FARKLIYSA ATLA

    [BAS_SON_SEKTOR] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [BAS_SEKTOR_SAYI] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    <BAS_PROG_TABAN T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    >BAS_PROG_TABAN T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [BAS_GEC2_ALT] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [BAS_GEC2_UST] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    2 T YÜKLE                   ; Tip 2 = BASIC programı
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    0 T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA

    ; Dizin sektörünü diske geri yaz
    0 T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    T [PORT_DISK_ADR_ALT] SAKLA
    0x7F T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    1 T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    2 T YÜKLE
    T [PORT_DISK_KOMUT] SAKLA

    <metin_bas_kaydedildi X YÜKLE
    >metin_bas_kaydedildi Y YÜKLE
    2 SİSTEM
    DÖN

bas_kmt_yukle:
    bas_dosya_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    bas_soz_dizimi_hatasi EŞİTSE ATLA

    0 T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    T [PORT_DISK_ADR_ALT] SAKLA
    0x7F T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    1 T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    T [PORT_DISK_KOMUT] SAKLA
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    bas_disk_hata_mesaj FARKLIYSA ATLA

    bas_dizinde_ara ÇAĞIR
    0 KARŞILAŞTIR
    bas_dosya_yok_mesaj EŞİTSE ATLA

    [BAS_DIZIN_OFSET] T YÜKLE
    8 TOPLA
    T X AKTAR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    X ARTIR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    <BAS_PROG_TABAN T YÜKLE
    T [PORT_DISK_ADR_ALT] SAKLA
    >BAS_PROG_TABAN T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    1 T YÜKLE
    T [PORT_DISK_KOMUT] SAKLA
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    bas_disk_hata_mesaj FARKLIYSA ATLA

    ; Yüklenen programın sonunu (0x0000) bularak BAS_SON işaretçisini güncelle
    0xFF T YÜKLE
    T [BAS_SATIR_NO_ALT] SAKLA
    T [BAS_SATIR_NO_UST] SAKLA
    bas_satir_ara ÇAĞIR
    [BAS_GEC_ALT] T YÜKLE
    T [BAS_SON_ALT] SAKLA
    [BAS_GEC_UST] T YÜKLE
    T [BAS_SON_UST] SAKLA

    <metin_bas_yuklendi X YÜKLE
    >metin_bas_yuklendi Y YÜKLE
    2 SİSTEM
    DÖN

bas_dosya_yok_mesaj:
    <metin_bas_dosya_yok X YÜKLE
    >metin_bas_dosya_yok Y YÜKLE
    2 SİSTEM
    DÖN

bas_disk_hata_mesaj:
    <metin_bas_disk_hata X YÜKLE
    >metin_bas_disk_hata Y YÜKLE
    2 SİSTEM
    DÖN

bas_dosya_adi_oku:
    bas_bosluk_atla ÇAĞIR
    ' ' T YÜKLE
    0 Y YÜKLE
bas_ad_temizle:
    T [DOSYA_AD_TAMPON + Y] SAKLA
    Y ARTIR
    8 Y KARŞILAŞTIR
    bas_ad_temizle FARKLIYSA ATLA

    [BAS_OKU_INDEKS] X YÜKLE
    0 Y YÜKLE
bas_ad_dongu:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_ad_bitti EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    bas_ad_bitti EŞİTSE ATLA
    8 Y KARŞILAŞTIR
    bas_ad_hata BÜYÜK VEYA EŞİTSE ATLA
    T [DOSYA_AD_TAMPON + Y] SAKLA
    X ARTIR
    Y ARTIR
    bas_ad_dongu ATLA
bas_ad_bitti:
    0 Y KARŞILAŞTIR
    bas_ad_hata EŞİTSE ATLA
    X [BAS_OKU_INDEKS] SAKLA
    1 T YÜKLE
    DÖN
bas_ad_hata:
    0 T YÜKLE
    DÖN

bas_dizinde_ara:
    0 T YÜKLE
    T [BAS_DIZIN_OFSET] SAKLA
bas_dizin_dongu:
    [BAS_DIZIN_OFSET] X YÜKLE
    [DIZIN_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_dizin_sonraki EŞİTSE ATLA
    0xE5 KARŞILAŞTIR
    bas_dizin_sonraki EŞİTSE ATLA
    0 Y YÜKLE
bas_dizin_isim:
    [DOSYA_AD_TAMPON + Y] T YÜKLE
    T [BAS_GECICI_BAYT] SAKLA
    [DIZIN_TAMPONU + X] T YÜKLE
    [BAS_GECICI_BAYT] KARŞILAŞTIR
    bas_dizin_sonraki FARKLIYSA ATLA
    X ARTIR
    Y ARTIR
    8 Y KARŞILAŞTIR
    bas_dizin_isim FARKLIYSA ATLA
    1 T YÜKLE
    DÖN
bas_dizin_sonraki:
    [BAS_DIZIN_OFSET] T YÜKLE
    16 TOPLA
    T [BAS_DIZIN_OFSET] SAKLA
    0 KARŞILAŞTIR
    bas_dizin_dongu FARKLIYSA ATLA
    0 T YÜKLE
    DÖN

; =============================================================================
; 7. ARİTMETİK İFADE HESAPLAYICI (+, -, *, /, %, RASTGELE, A..Z, 0..255)
; =============================================================================
bas_ifade_hesapla:
    bas_terim_oku ÇAĞIR
    T İT                    ; Sol birikimli sonucu yığında tut

bas_ifade_dongu:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE

    '+' KARŞILAŞTIR
    bas_ifade_islec EŞİTSE ATLA
    '-' KARŞILAŞTIR
    bas_ifade_islec EŞİTSE ATLA
    '*' KARŞILAŞTIR
    bas_ifade_islec EŞİTSE ATLA
    '/' KARŞILAŞTIR
    bas_ifade_islec EŞİTSE ATLA
    '%' KARŞILAŞTIR
    bas_ifade_islec EŞİTSE ATLA

    ; Başka aritmetik işleç yok: sonucu yığından çekip dön
    T ÇEK
    DÖN

bas_ifade_islec:
    T [BAS_ISLEC] SAKLA
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA

    ; İşleci yığına koru ve sağ terimi oku
    [BAS_ISLEC] T YÜKLE
    T İT
    bas_terim_oku ÇAĞIR
    T [BAS_SAG_DEGER] SAKLA

    ; İşleci ve sol değeri yığından çek
    T ÇEK
    T [BAS_ISLEC] SAKLA
    T ÇEK
    T [BAS_SOL_DEGER] SAKLA

    [BAS_ISLEC] T YÜKLE
    '+' KARŞILAŞTIR
    bas_islem_topla EŞİTSE ATLA
    '-' KARŞILAŞTIR
    bas_islem_cikar EŞİTSE ATLA
    '*' KARŞILAŞTIR
    bas_islem_carp EŞİTSE ATLA
    '/' KARŞILAŞTIR
    bas_islem_bol EŞİTSE ATLA

    ; '%': Modulo (bölme kalanı)
    bas_bolme_yap ÇAĞIR
    [BAS_KALAN] T YÜKLE
    T İT
    bas_ifade_dongu ATLA

bas_islem_topla:
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] TOPLA
    T İT
    bas_ifade_dongu ATLA

bas_islem_cikar:
    [BAS_SOL_DEGER] T YÜKLE
    [BAS_SAG_DEGER] ÇIKAR
    T İT
    bas_ifade_dongu ATLA

bas_islem_carp:
    0 T YÜKLE
    [BAS_SAG_DEGER] Y YÜKLE
    0 Y KARŞILAŞTIR
    bas_carp_bitti EŞİTSE ATLA
bas_carp_dongu:
    [BAS_SOL_DEGER] TOPLA
    Y AZALT
    bas_carp_dongu FARKLIYSA ATLA
bas_carp_bitti:
    T İT
    bas_ifade_dongu ATLA

bas_islem_bol:
    bas_bolme_yap ÇAĞIR
    T İT
    bas_ifade_dongu ATLA

; -----------------------------------------------------------------------------
; bas_bolme_yap:
; BAS_SOL_DEGER / BAS_SAG_DEGER işlemini yapar.
; Çıktı: T = bölüm, BAS_KALAN = kalan
; -----------------------------------------------------------------------------
bas_bolme_yap:
    [BAS_SOL_DEGER] T YÜKLE
    T [BAS_KALAN] SAKLA
    0 Y YÜKLE               ; Y = bölüm
    [BAS_SAG_DEGER] T YÜKLE
    0 KARŞILAŞTIR
    bas_bol_sifir EŞİTSE ATLA

bas_bol_dongu:
    [BAS_KALAN] T YÜKLE
    [BAS_SAG_DEGER] KARŞILAŞTIR
    bas_bol_tamam KÜÇÜKSE ATLA
    [BAS_SAG_DEGER] ÇIKAR
    T [BAS_KALAN] SAKLA
    Y ARTIR
    bas_bol_dongu ATLA

bas_bol_tamam:
    Y T AKTAR
    DÖN

bas_bol_sifir:
    0 T YÜKLE
    T [BAS_KALAN] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; bas_terim_oku:
; RASTGELE, A..Z değişkeni veya sayısal sabiti (onluk 0..255) okur -> T.
; -----------------------------------------------------------------------------
bas_terim_oku:
    bas_bosluk_atla ÇAĞIR

    ; "RASTGELE" anahtar kelimesi mi?
    <kmt_rastgele X YÜKLE
    >kmt_rastgele Y YÜKLE
    bas_onek_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_terim_rastgele EŞİTSE ATLA

    [BAS_OKU_INDEKS] X YÜKLE
    [BAS_AKTIF_SATIR + X] T YÜKLE

    ; Tek harfli değişken ('A'..'Z') mi?
    'A' KARŞILAŞTIR
    bas_terim_sayi KÜÇÜKSE ATLA
    '[' KARŞILAŞTIR
    bas_terim_sayi BÜYÜK VEYA EŞİTSE ATLA

    'A' ÇIKAR
    T Y AKTAR
    X ARTIR
    X [BAS_OKU_INDEKS] SAKLA
    [BAS_DEGISKENLER + Y] T YÜKLE
    DÖN

bas_terim_rastgele:
    RASTGELE
    DÖN

bas_terim_sayi:
    bas_onluk_kelime_oku ÇAĞIR
    [BAS_SATIR_NO_ALT] T YÜKLE
    DÖN

; =============================================================================
; 8. YARDIMCI ALT PROGRAMLAR (SATIR HAZIRLAMA, EŞLEŞTİRME, ONLUK OKUMA/YAZMA)
; =============================================================================

; -----------------------------------------------------------------------------
; bas_satir_hazirla:
; SATIR_TAMPONU (0x0080) içeriğini BAS_AKTIF_SATIR (0x0140) tamponuna kopyalar,
; tırnak dışındaki küçük harfleri ve Türkçe karakterleri büyük ASCII'ye çevirir.
; -----------------------------------------------------------------------------
bas_satir_hazirla:
    0 X YÜKLE
    0 Y YÜKLE               ; Y = tırnak durumu (0 veya 34)

bas_norm_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_norm_bitti EŞİTSE ATLA

    0 Y KARŞILAŞTIR
    bas_norm_tirnak_disi EŞİTSE ATLA

    34 KARŞILAŞTIR
    bas_norm_yaz FARKLIYSA ATLA
    0 Y YÜKLE
    bas_norm_yaz ATLA

bas_norm_tirnak_disi:
    34 KARŞILAŞTIR
    bas_norm_tirnak_ac EŞİTSE ATLA

    ; Küçük 'a'..'z' -> 'A'..'Z'
    'a' KARŞILAŞTIR
    bas_norm_tr KÜÇÜKSE ATLA
    123 KARŞILAŞTIR
    bas_norm_tr BÜYÜK VEYA EŞİTSE ATLA
    32 ÇIKAR
    bas_norm_yaz ATLA

bas_norm_tirnak_ac:
    34 Y YÜKLE
    bas_norm_yaz ATLA

bas_norm_tr:
    0xC7 KARŞILAŞTIR
    bas_tr_c EŞİTSE ATLA
    0xE7 KARŞILAŞTIR
    bas_tr_c EŞİTSE ATLA
    0xD0 KARŞILAŞTIR
    bas_tr_g EŞİTSE ATLA
    0xF0 KARŞILAŞTIR
    bas_tr_g EŞİTSE ATLA
    0xDD KARŞILAŞTIR
    bas_tr_i EŞİTSE ATLA
    0xFD KARŞILAŞTIR
    bas_tr_i EŞİTSE ATLA
    0xD6 KARŞILAŞTIR
    bas_tr_o EŞİTSE ATLA
    0xF6 KARŞILAŞTIR
    bas_tr_o EŞİTSE ATLA
    0xDE KARŞILAŞTIR
    bas_tr_s EŞİTSE ATLA
    0xFE KARŞILAŞTIR
    bas_tr_s EŞİTSE ATLA
    0xDC KARŞILAŞTIR
    bas_tr_u EŞİTSE ATLA
    0xFC KARŞILAŞTIR
    bas_tr_u EŞİTSE ATLA
    bas_norm_yaz ATLA

bas_tr_c:
    'C' T YÜKLE
    bas_norm_yaz ATLA
bas_tr_g:
    'G' T YÜKLE
    bas_norm_yaz ATLA
bas_tr_i:
    'I' T YÜKLE
    bas_norm_yaz ATLA
bas_tr_o:
    'O' T YÜKLE
    bas_norm_yaz ATLA
bas_tr_s:
    'S' T YÜKLE
    bas_norm_yaz ATLA
bas_tr_u:
    'U' T YÜKLE

bas_norm_yaz:
    T [BAS_AKTIF_SATIR + X] SAKLA
    X ARTIR
    bas_norm_dongu ATLA

bas_norm_bitti:
    0 T YÜKLE
    T [BAS_AKTIF_SATIR + X] SAKLA
    T [BAS_OKU_INDEKS] SAKLA
    bas_bosluk_atla ÇAĞIR
    DÖN

bas_bosluk_atla:
    [BAS_OKU_INDEKS] X YÜKLE
bas_bosluk_dongu:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    ' ' KARŞILAŞTIR
    bas_bosluk_cik FARKLIYSA ATLA
    X ARTIR
    bas_bosluk_dongu ATLA
bas_bosluk_cik:
    X [BAS_OKU_INDEKS] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; bas_onek_eslesir_mi:
; BAS_AKTIF_SATIR[BAS_OKU_INDEKS..] başında X/Y şablonunu arar.
; Eşleşirse BAS_OKU_INDEKS şablondan sonraki boşlukların sonuna ilerler ve T=1 döner.
; -----------------------------------------------------------------------------
bas_onek_eslesir_mi:
    X [BAS_SABLON_ALT] SAKLA
    Y [BAS_SABLON_UST] SAKLA
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    0 Y YÜKLE

bas_onek_dongu:
    [[BAS_SABLON_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    bas_onek_son_kontrol EŞİTSE ATLA
    T [BAS_GECICI_BAYT] SAKLA
    [BAS_AKTIF_SATIR + X] T YÜKLE
    [BAS_GECICI_BAYT] KARŞILAŞTIR
    bas_onek_yok FARKLIYSA ATLA
    X ARTIR
    Y ARTIR
    bas_onek_dongu ATLA

bas_onek_son_kontrol:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_onek_tamam EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    bas_onek_tamam EŞİTSE ATLA

bas_onek_yok:
    0 T YÜKLE
    DÖN

bas_onek_tamam:
    X [BAS_OKU_INDEKS] SAKLA
    bas_bosluk_atla ÇAĞIR
    1 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; bas_komut_eslesir_mi:
; Hem önde komut ("YAZ 5", "GİT 10") hem sonda yüklem ("5 YAZ", "10 GİT")
; düzenini tırnak-duyarlı olarak kontrol eder.
; -----------------------------------------------------------------------------
bas_komut_eslesir_mi:
    bas_onek_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    bas_komut_eslesti_cik EŞİTSE ATLA

    ; Başta eşleşmedi: satırın sonundaki kelimeyi kontrol et (tırnak içinde değilse)
    [BAS_OKU_INDEKS] X YÜKLE
    0 T YÜKLE
    T [BAS_TIRNAK] SAKLA
bas_sona_git:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_sonda_budama EŞİTSE ATLA
    34 KARŞILAŞTIR
    bas_sona_ilerle FARKLIYSA ATLA
    [BAS_TIRNAK] T YÜKLE
    1 ÖZELVEYA
    T [BAS_TIRNAK] SAKLA
bas_sona_ilerle:
    X ARTIR
    bas_sona_git ATLA

bas_sonda_budama:
    [BAS_OKU_INDEKS] T YÜKLE
    T [BAS_GECICI_BAYT] SAKLA
    X T AKTAR
    [BAS_GECICI_BAYT] KARŞILAŞTIR
    bas_komut_yok EŞİTSE ATLA
    X AZALT
    [BAS_AKTIF_SATIR + X] T YÜKLE
    ' ' KARŞILAŞTIR
    bas_sonda_ifade_sil EŞİTSE ATLA
    34 KARŞILAŞTIR          ; Son karakter '"' ise sonda komut yoktur
    bas_komut_yok EŞİTSE ATLA
    X ARTIR
    bas_son_kelime_bul ATLA

bas_sonda_ifade_sil:
    0 T YÜKLE
    T [BAS_AKTIF_SATIR + X] SAKLA
    bas_sonda_budama ATLA

bas_son_kelime_bul:
    X AZALT
    [BAS_OKU_INDEKS] T YÜKLE
    T [BAS_GECICI_BAYT] SAKLA
    X T AKTAR
    [BAS_GECICI_BAYT] KARŞILAŞTIR
    bas_komut_yok EŞİTSE ATLA
    [BAS_AKTIF_SATIR + X] T YÜKLE
    ' ' KARŞILAŞTIR
    bas_son_kelime_bul FARKLIYSA ATLA

    X ARTIR
    X [BAS_SON_KELIME] SAKLA
    0 Y YÜKLE

bas_sonda_kiyas:
    [[BAS_SABLON_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    bas_sonda_sablon_bitti EŞİTSE ATLA
    T [BAS_GECICI_BAYT] SAKLA
    [BAS_AKTIF_SATIR + X] T YÜKLE
    [BAS_GECICI_BAYT] KARŞILAŞTIR
    bas_komut_yok FARKLIYSA ATLA
    X ARTIR
    Y ARTIR
    bas_sonda_kiyas ATLA

bas_sonda_sablon_bitti:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    0 KARŞILAŞTIR
    bas_komut_yok FARKLIYSA ATLA

    ; Eşleşti! Son kelimeden önceki boşluğu '\0' yap
    [BAS_SON_KELIME] X YÜKLE
    X AZALT
    0 T YÜKLE
    T [BAS_AKTIF_SATIR + X] SAKLA
    1 T YÜKLE
    DÖN

bas_komut_yok:
    0 T YÜKLE
    DÖN

bas_komut_eslesti_cik:
    1 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; bas_onluk_kelime_oku:
; BAS_AKTIF_SATIR[BAS_OKU_INDEKS..] konumundan 16-bit onluk sayı okur -> BAS_SATIR_NO.
; Başarılıysa T = 1, rakam yoksa T = 0 döner.
; -----------------------------------------------------------------------------
bas_onluk_kelime_oku:
    bas_bosluk_atla ÇAĞIR
    [BAS_OKU_INDEKS] X YÜKLE
    0 T YÜKLE
    T [BAS_SATIR_NO_ALT] SAKLA
    T [BAS_SATIR_NO_UST] SAKLA
    T [BAS_CARP_SAYAC] SAKLA    ; Okunan hane sayısı

bas_onluk_oku_dongu:
    [BAS_AKTIF_SATIR + X] T YÜKLE
    '0' KARŞILAŞTIR
    bas_onluk_oku_bitti KÜÇÜKSE ATLA
    ':' KARŞILAŞTIR
    bas_onluk_oku_bitti BÜYÜK VEYA EŞİTSE ATLA

    '0' ÇIKAR
    T [BAS_GECICI_BAYT] SAKLA

    ; BAS_SATIR_NO = BAS_SATIR_NO * 10 + rakam
    ; Önce * 2 değerini BAS_GEC2'ye kaydet
    [BAS_SATIR_NO_ALT] T YÜKLE
    T SOLA KAYDIR
    T [BAS_GEC2_ALT] SAKLA
    [BAS_SATIR_NO_UST] T YÜKLE
    T SOLA DÖNDÜR
    T [BAS_GEC2_UST] SAKLA

    ; * 2 değerini 2 kez daha sola kaydırarak * 8 yap
    [BAS_GEC2_ALT] T YÜKLE
    T SOLA KAYDIR
    T [BAS_SATIR_NO_ALT] SAKLA
    [BAS_GEC2_UST] T YÜKLE
    T SOLA DÖNDÜR
    T [BAS_SATIR_NO_UST] SAKLA

    [BAS_SATIR_NO_ALT] T YÜKLE
    T SOLA KAYDIR
    T [BAS_SATIR_NO_ALT] SAKLA
    [BAS_SATIR_NO_UST] T YÜKLE
    T SOLA DÖNDÜR
    T [BAS_SATIR_NO_UST] SAKLA

    ; (* 8) + (* 2) = * 10
    [BAS_SATIR_NO_ALT] T YÜKLE
    [BAS_GEC2_ALT] TOPLA
    T [BAS_SATIR_NO_ALT] SAKLA
    [BAS_SATIR_NO_UST] T YÜKLE
    0 ELDEYLE TOPLA
    [BAS_GEC2_UST] TOPLA
    T [BAS_SATIR_NO_UST] SAKLA

    ; Yeni rakamı ekle
    [BAS_SATIR_NO_ALT] T YÜKLE
    [BAS_GECICI_BAYT] TOPLA
    T [BAS_SATIR_NO_ALT] SAKLA
    [BAS_SATIR_NO_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [BAS_SATIR_NO_UST] SAKLA

    [BAS_CARP_SAYAC] ARTIR
    X ARTIR
    bas_onluk_oku_dongu ATLA

bas_onluk_oku_bitti:
    [BAS_CARP_SAYAC] T YÜKLE
    0 KARŞILAŞTIR
    bas_onluk_oku_hata EŞİTSE ATLA
    X [BAS_OKU_INDEKS] SAKLA
    1 T YÜKLE
    DÖN

bas_onluk_oku_hata:
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; bas_onluk_bayt_yaz:
; T yazmacındaki 8-bit sayıyı (0..255) baştaki sıfırları bastırarak onluk yazdırır.
; -----------------------------------------------------------------------------
bas_onluk_bayt_yaz:
    T RAKAMLARA AYIR        ; Y = yüzler, X = onlar, T = birler (ASCII)
    T İT                    ; Birler basamağını koru
    X İT                    ; Onlar basamağını koru

    '0' Y KARŞILAŞTIR
    bas_onluk_onlar_kontrol EŞİTSE ATLA

    ; Yüzler > '0': yüzleri ve onları doğrudan bas
    Y T AKTAR
    1 SİSTEM
    T ÇEK
    1 SİSTEM
    bas_onluk_birler_bas ATLA

bas_onluk_onlar_kontrol:
    T ÇEK                   ; Onlar basamağı
    '0' KARŞILAŞTIR
    bas_onluk_birler_bas EŞİTSE ATLA
    1 SİSTEM

bas_onluk_birler_bas:
    T ÇEK                   ; Birler basamağı
    1 SİSTEM
    DÖN

; -----------------------------------------------------------------------------
; bas_onluk_kelime_yaz:
; BAS_SATIR_NO_ALT/UST içindeki 16-bit satır numarasını onluk olarak yazdırır.
; -----------------------------------------------------------------------------
bas_onluk_kelime_yaz:
    ; Üst bayt 0 ise (< 256) doğrudan hızlı 8-bit yazdırıcıyı kullan
    [BAS_SATIR_NO_UST] T YÜKLE
    0 KARŞILAŞTIR
    bas_kelime_buyuk FARKLIYSA ATLA
    [BAS_SATIR_NO_ALT] T YÜKLE
    bas_onluk_bayt_yaz ATLA

bas_kelime_buyuk:
    ; 10000, 1000, 100, 10 basamaklarını ardışık çıkarma ile yazdır
    0 T YÜKLE
    T [BAS_ONLUK_BAS] SAKLA
    [BAS_SATIR_NO_ALT] T YÜKLE
    T [BAS_GEC2_ALT] SAKLA
    [BAS_SATIR_NO_UST] T YÜKLE
    T [BAS_GEC2_UST] SAKLA

    ; 1000 (0x03E8)
    0xE8 X YÜKLE
    0x03 Y YÜKLE
    bas_basamak_cikar ÇAĞIR

    ; 100 (0x0064)
    0x64 X YÜKLE
    0x00 Y YÜKLE
    bas_basamak_cikar ÇAĞIR

    ; Kalan (0..99)
    [BAS_GEC2_ALT] T YÜKLE
    T RAKAMLARA AYIR
    T İT
    X T AKTAR
    1 SİSTEM
    T ÇEK
    1 SİSTEM
    DÖN

bas_basamak_cikar:
    '0' T YÜKLE
    T [BAS_GECICI_BAYT] SAKLA
bas_basamak_dongu:
    [BAS_GEC2_UST] T YÜKLE
    Y T AKTAR
    T [BAS_KALAN] SAKLA
    [BAS_GEC2_UST] T YÜKLE
    [BAS_KALAN] KARŞILAŞTIR
    bas_basamak_bitti KÜÇÜKSE ATLA
    bas_basamak_cikar_yap BÜYÜKSE ATLA

    X T AKTAR
    T [BAS_KALAN] SAKLA
    [BAS_GEC2_ALT] T YÜKLE
    [BAS_KALAN] KARŞILAŞTIR
    bas_basamak_bitti KÜÇÜKSE ATLA

bas_basamak_cikar_yap:
    X T AKTAR
    T [BAS_KALAN] SAKLA
    [BAS_GEC2_ALT] T YÜKLE
    [BAS_KALAN] ÇIKAR
    T [BAS_GEC2_ALT] SAKLA
    Y T AKTAR
    T [BAS_KALAN] SAKLA
    [BAS_GEC2_UST] T YÜKLE
    bas_basamak_borc_yok ELDE VARSA ATLA
    [BAS_KALAN] ÇIKAR
    T AZALT
    bas_basamak_sakla ATLA
bas_basamak_borc_yok:
    [BAS_KALAN] ÇIKAR
bas_basamak_sakla:
    T [BAS_GEC2_UST] SAKLA
    [BAS_GECICI_BAYT] ARTIR
    bas_basamak_dongu ATLA

bas_basamak_bitti:
    [BAS_GECICI_BAYT] T YÜKLE
    '0' KARŞILAŞTIR
    bas_basamak_yaz FARKLIYSA ATLA
    [BAS_ONLUK_BAS] T YÜKLE
    0 KARŞILAŞTIR
    bas_basamak_cik EŞİTSE ATLA
    '0' T YÜKLE
bas_basamak_yaz:
    1 SİSTEM
    1 T YÜKLE
    T [BAS_ONLUK_BAS] SAKLA
bas_basamak_cik:
    DÖN

; =============================================================================
; 9. SABİT METİNLER VE ANAHTAR KELİME ŞABLONLARI
; =============================================================================
metin_bas_acilis:
    .METİN "TÜRK-8 BASIC v1.0 (22 KB SERBEST)\n"
    .METİN "HAZIR.\n"
    .BAYT 0

metin_bas_hata:
    .METİN "SÖZ DİZİMİ HATASI!\n"
    .BAYT 0

metin_bas_satir_yok:
    .METİN "SATIR BULUNAMADI!\n"
    .BAYT 0

metin_bas_kaydedildi:
    .METİN "DİSKE KAYDEDİLDİ.\n"
    .BAYT 0

metin_bas_yuklendi:
    .METİN "YÜKLENDİ.\n"
    .BAYT 0

metin_bas_dosya_yok:
    .METİN "DOSYA BULUNAMADI!\n"
    .BAYT 0

metin_bas_disk_hata:
    .METİN "DİSK HATASI!\n"
    .BAYT 0

kmt_satir_oneki:
    .METİN "SATIR"
    .BAYT 0
kmt_rem:
    .METİN "REM"
    .BAYT 0
kmt_eger:
    .METİN "EGER"
    .BAYT 0
kmt_ise:
    .METİN "ISE"
    .BAYT 0
kmt_dongu:
    .METİN "DONGU"
    .BAYT 0
kmt_bitis:
    .METİN "BITIS"
    .BAYT 0
kmt_sonraki:
    .METİN "SONRAKI"
    .BAYT 0
kmt_yaz:
    .METİN "YAZ"
    .BAYT 0
kmt_girdi:
    .METİN "GIRDI"
    .BAYT 0
kmt_git:
    .METİN "GIT"
    .BAYT 0
kmt_cagir:
    .METİN "CAGIR"
    .BAYT 0
kmt_don:
    .METİN "DON"
    .BAYT 0
kmt_ses:
    .METİN "SES"
    .BAYT 0
kmt_temizle:
    .METİN "TEMIZLE"
    .BAYT 0
kmt_bitir:
    .METİN "BITIR"
    .BAYT 0
kmt_dur:
    .METİN "DUR"
    .BAYT 0
kmt_listele:
    .METİN "LISTELE"
    .BAYT 0
kmt_liste:
    .METİN "LISTE"
    .BAYT 0
kmt_calistir:
    .METİN "CALISTIR"
    .BAYT 0
kmt_yeni:
    .METİN "YENI"
    .BAYT 0
kmt_kaydet:
    .METİN "KAYDET"
    .BAYT 0
kmt_yukle:
    .METİN "YUKLE"
    .BAYT 0
kmt_cik:
    .METİN "CIK"
    .BAYT 0
kmt_olsun:
    .METİN "OLSUN"
    .BAYT 0
kmt_rastgele:
    .METİN "RASTGELE"
    .BAYT 0
