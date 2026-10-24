; =============================================================================
; TÜRK-8 SİSTEM BIOS ROM (v1.0)
; Adres Aralığı : 0xC000 - 0xFFFF (16 KB Kalıcı Sistem Belleği)
;
; Vektör Tablosu (ROM Sonu):
;   0xFFFA (VEKTOR_SISTEM)  -> bios_sistem_giris  (<n> SİSTEM çağrıları)
;   0xFFFC (VEKTOR_SIFIRLA) -> bios_sifirla       (Açılış / Reset giriş noktası)
;   0xFFFE (VEKTOR_KESME)   -> bios_kesme_giris   (50 Hz donanım zamanlayıcı kesmesi)
;
; BIOS Servisleri (<n> SİSTEM):
;   0 : BIOS_EKRAN_TEMIZLE  — 40x25 ekranı boşlukla siler, imleci (0,0) yapar
;   1 : BIOS_KARAKTER_YAZ   — T yazmacındaki karakteri imlece yazar ve ilerletir
;                             ('\n'=10 alt satır, 8/127 geri silme, 25. satırda kaydırma)
;   2 : BIOS_METIN_YAZ      — X (alt), Y (üst) adresindeki sıfır sonlu metni yazar
;   3 : BIOS_TUS_OKU        — Beklemesiz klavye okur: tuş varsa T=tuş, yoksa T=0
;   4 : BIOS_TUS_BEKLE      — Tuş basılana kadar KARE BEKLE ile bekler, T=tuş döner
;   5 : BIOS_SATIR_OKU      — Ekranda imleçle satır okur (0x0080 tamponuna yazar),
;                             Enter ile biter, X=okunan karakter uzunluğu döner
;   6 : BIOS_EKRAN_KAYDIR   — Ekranı 1 satır (40 bayt) yukarı kaydırır, son satırı siler
;   7 : BIOS_SES_CAL        — X=frekans, Y=süre (20ms birim) ile ses üretir
;   8 : BIOS_SURE_OKU       — 50 Hz çalışma süresi sayacını okur (T=alt, X=üst bayt)
; =============================================================================

; --- Sıfır Sayfave Donanım Sabitleri ---
.TANIM BLOK_KAYNAK_ALT  0x0000
.TANIM BLOK_KAYNAK_UST  0x0001
.TANIM BLOK_HEDEF_ALT   0x0002
.TANIM BLOK_HEDEF_UST   0x0003
.TANIM BLOK_UZUNLUK_ALT 0x0004
.TANIM BLOK_UZUNLUK_UST 0x0005

.TANIM SATIR_TAMPONU    0x0080  ; 64 baytlık standart satır girdi tamponu (0x0080-0x00BF)
.TANIM SATIR_MAKS_UZUN  36      ; Bir satırda okunabilecek azami karakter sayısı

; BIOS Sıfır Sayfa Değişkenleri (0x00E0 - 0x00EF)
.TANIM IMLEC_SUTUN      0x00E0  ; 0..39 arası imleç sütunu
.TANIM IMLEC_SATIR      0x00E1  ; 0..24 arası imleç satırı
.TANIM IMLEC_ADRES_ALT  0x00E2  ; VRAM imleç adresi alt baytı
.TANIM IMLEC_ADRES_UST  0x00E3  ; VRAM imleç adresi üst baytı
.TANIM METIN_ISARET_ALT 0x00E4  ; BIOS_METIN_YAZ geçici işaretçisi (alt)
.TANIM METIN_ISARET_UST 0x00E5  ; BIOS_METIN_YAZ geçici işaretçisi (üst)
.TANIM GECICI_KARAKTER  0x00E6  ; Yazdırılacak karakterin geçici kopyası
.TANIM GECICI_SAYAC     0x00E7  ; Döngü / satır okuma sayacı
.TANIM SURE_ALT         0x00E8  ; 50 Hz kesme sayacı (alt bayt)
.TANIM SURE_UST         0x00E9  ; 50 Hz kesme sayacı (üst bayt)
.TANIM BELLEK_TEST_ALT  0x00EA  ; POST bellek testi işaretçisi (alt)
.TANIM BELLEK_TEST_UST  0x00EB  ; POST bellek testi işaretçisi (üst)
.TANIM SERVIS_ATLA_ALT  0x00EC  ; Dolaylı servis çağrısı adresi (alt)
.TANIM SERVIS_ATLA_UST  0x00ED  ; Dolaylı servis çağrısı adresi (üst)
.TANIM KAYITLI_T        0x00EE  ; Sistem çağrısında T yazmacı kopyası
.TANIM KAYITLI_X        0x00EF  ; Sistem çağrısında X yazmacı kopyası

.TANIM SISTEM_NO_ADRES  0x00FA  ; <n> SİSTEM komutunun servis numarasını yazdığı adres

; Donanım Portları
.TANIM PORT_KLAVYE_VERI  0xA000
.TANIM PORT_KLAVYE_DURUM 0xA001
.TANIM PORT_ZAMANLAYICI  0xA002
.TANIM PORT_TERMINAL     0xA003
.TANIM PORT_SES_FREKANS  0xA004
.TANIM PORT_SES_SURE     0xA005

.BAŞLANGIÇ 0xC000

; =============================================================================
; 1. AÇILIŞ (RESET) VE BELLEK TESTİ (POST)
; =============================================================================
bios_sifirla:
    KESME KAPAT
    0xFF T YÜKLE
    T YG AKTAR

    ; BIOS sıfır sayfa çalışma alanını (0x00E0 - 0x00EF) sıfırla
    0 T YÜKLE
    0 X YÜKLE
bios_zp_temizle:
    T [0x00E0 + X] SAKLA
    X ARTIR
    16 X KARŞILAŞTIR
    bios_zp_temizle FARKLIYSA ATLA

    ; Kullanıcı RAM vektörlerini (0x00FC - 0x00FF) sıfırla ki ROM vektörleri çalışsın
    0 T YÜKLE
    T [0x00FC] SAKLA
    T [0x00FD] SAKLA
    T [0x00FE] SAKLA
    T [0x00FF] SAKLA

    ; --- POST: Kullanıcı RAM Testi (0x0200 - 0x7FFF = 31 KB) ---
    ; Her 256 baytlık sayfanın ilk baytını 0x5A / 0xA5 deseniyle sına ve sıfırla
    0x00 T YÜKLE
    T [BELLEK_TEST_ALT] SAKLA
    0x02 T YÜKLE
    T [BELLEK_TEST_UST] SAKLA

post_dongusu:
    0x5A T YÜKLE
    T [[BELLEK_TEST_ALT]] SAKLA
    [[BELLEK_TEST_ALT]] T YÜKLE
    0x5A KARŞILAŞTIR
    post_hatasi FARKLIYSA ATLA

    0xA5 T YÜKLE
    T [[BELLEK_TEST_ALT]] SAKLA
    [[BELLEK_TEST_ALT]] T YÜKLE
    0xA5 KARŞILAŞTIR
    post_hatasi FARKLIYSA ATLA

    0x00 T YÜKLE
    T [[BELLEK_TEST_ALT]] SAKLA

    [BELLEK_TEST_UST] ARTIR
    [BELLEK_TEST_UST] T YÜKLE
    0x80 KARŞILAŞTIR
    post_dongusu FARKLIYSA ATLA

    ; Ekranı temizle (BIOS servis 0)
    0 SİSTEM

    ; Açılış başlığını ekrana yaz (BIOS servis 2)
    <acilis_metni X YÜKLE
    >acilis_metni Y YÜKLE
    2 SİSTEM

    ; Açılış onay bip sesi (BIOS servis 7: frekans=80, süre=2 kare)
    80 X YÜKLE
    2 Y YÜKLE
    7 SİSTEM

    ; Donanım kesmelerini aç (50 Hz süre sayacı başlasın)
    KESME AÇ

    ; Etkileşimli BIOS komut istemi döngüsüne gir
    bios_komut_dongusu ATLA

post_hatasi:
    ; Bellek hatası durumunda işlemciyi durdur
    DUR

; =============================================================================
; 2. AÇILIŞ KOMUT İSTEMİ DÖNGÜSÜ (> _)
; =============================================================================
bios_komut_dongusu:
    ; İstem karakterlerini yaz: "> "
    '>' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

    ; Kullanıcıdan bir satır oku (0x0080 tamponuna)
    5 SİSTEM

    ; Bir sonraki satırda tekrar istem göster
    bios_komut_dongusu ATLA

; =============================================================================
; 3. YAZILIM KESMESİ (<n> SİSTEM) GİRİŞ NOKTASI
; =============================================================================
bios_sistem_giris:
    T [KAYITLI_T] SAKLA
    X [KAYITLI_X] SAKLA

    ; Servis numarası geçerli mi? (0..8)
    [SISTEM_NO_ADRES] T YÜKLE
    9 KARŞILAŞTIR
    bios_sistem_gecersiz BÜYÜK VEYA EŞİTSE ATLA

    ; Tablo ofseti = servis_no * 2
    T SOLA KAYDIR
    T X AKTAR
    [bios_servis_tablosu + X] T YÜKLE
    T [SERVIS_ATLA_ALT] SAKLA
    X ARTIR
    [bios_servis_tablosu + X] T YÜKLE
    T [SERVIS_ATLA_UST] SAKLA

    ; Çağrı öncesi T ve X değerlerini geri yükle ve servise dolaylı çağrı yap
    [KAYITLI_T] T YÜKLE
    [KAYITLI_X] X YÜKLE
    [SERVIS_ATLA_ALT] ÇAĞIR
    KESMEDEN DÖN

bios_sistem_gecersiz:
    [KAYITLI_T] T YÜKLE
    [KAYITLI_X] X YÜKLE
    KESMEDEN DÖN

bios_servis_tablosu:
    .KELİME servis_ekran_temizle   ; 0
    .KELİME servis_karakter_yaz    ; 1
    .KELİME servis_metin_yaz       ; 2
    .KELİME servis_tus_oku         ; 3
    .KELİME servis_tus_bekle       ; 4
    .KELİME servis_satir_oku       ; 5
    .KELİME servis_ekran_kaydir    ; 6
    .KELİME servis_ses_cal         ; 7
    .KELİME servis_sure_oku        ; 8

; =============================================================================
; 4. BIOS SERVİS ALT PROGRAMLARI
; =============================================================================

; -----------------------------------------------------------------------------
; İmleç VRAM adresini (0x8000 + satir * 40 + sutun) hesaplar.
; IMLEC_ADRES_ALT ve IMLEC_ADRES_UST güncellenir. T yazmacını korur.
; -----------------------------------------------------------------------------
imlec_adresi_hesapla:
    T İT
    0x80 T YÜKLE
    T [IMLEC_ADRES_UST] SAKLA

    ; satir * 8 (0..192, tek bayta sığar)
    [IMLEC_SATIR] T YÜKLE
    T SOLA KAYDIR
    T SOLA KAYDIR
    T SOLA KAYDIR
    T [IMLEC_ADRES_ALT] SAKLA

    ; 16-bit olarak (satir * 8) değerini 2 kez sola kaydır -> satir * 32
    T SOLA KAYDIR
    T [IMLEC_ADRES_ALT] SAKLA
    [IMLEC_ADRES_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [IMLEC_ADRES_UST] SAKLA

    [IMLEC_ADRES_ALT] T YÜKLE
    T SOLA KAYDIR
    T [IMLEC_ADRES_ALT] SAKLA
    [IMLEC_ADRES_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [IMLEC_ADRES_UST] SAKLA

    ; + (satir * 8) ekle -> satir * 40
    [IMLEC_SATIR] T YÜKLE
    T SOLA KAYDIR
    T SOLA KAYDIR
    T SOLA KAYDIR
    [IMLEC_ADRES_ALT] TOPLA
    T [IMLEC_ADRES_ALT] SAKLA
    [IMLEC_ADRES_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [IMLEC_ADRES_UST] SAKLA

    ; + IMLEC_SUTUN ekle
    [IMLEC_ADRES_ALT] T YÜKLE
    [IMLEC_SUTUN] TOPLA
    T [IMLEC_ADRES_ALT] SAKLA
    [IMLEC_ADRES_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [IMLEC_ADRES_UST] SAKLA

    T ÇEK
    DÖN

; -----------------------------------------------------------------------------
; Servis 0: BIOS_EKRAN_TEMIZLE
; 40x25 VRAM alanını (1000 bayt = 0x03E8) boşluk (' ') ile doldurur,
; imleci (0, 0) konumuna alır.
; -----------------------------------------------------------------------------
servis_ekran_temizle:
    T İT
    0x00 T YÜKLE
    T [BLOK_HEDEF_ALT] SAKLA
    0x80 T YÜKLE
    T [BLOK_HEDEF_UST] SAKLA
    0xE8 T YÜKLE
    T [BLOK_UZUNLUK_ALT] SAKLA
    0x03 T YÜKLE
    T [BLOK_UZUNLUK_UST] SAKLA
    ' ' T YÜKLE
    DOLDUR

    0 T YÜKLE
    T [IMLEC_SUTUN] SAKLA
    T [IMLEC_SATIR] SAKLA
    imlec_adresi_hesapla ÇAĞIR
    T ÇEK
    DÖN

; -----------------------------------------------------------------------------
; Servis 6: BIOS_EKRAN_KAYDIR
; VRAM'i 1 satır yukarı kaydırır (0x8028 -> 0x8000, 960 = 0x03C0 bayt)
; ve son satırı (0x83C0, 40 bayt) boşlukla temizler.
; -----------------------------------------------------------------------------
servis_ekran_kaydir:
    T İT
    0x28 T YÜKLE
    T [BLOK_KAYNAK_ALT] SAKLA
    0x80 T YÜKLE
    T [BLOK_KAYNAK_UST] SAKLA

    0x00 T YÜKLE
    T [BLOK_HEDEF_ALT] SAKLA
    0x80 T YÜKLE
    T [BLOK_HEDEF_UST] SAKLA

    0xC0 T YÜKLE
    T [BLOK_UZUNLUK_ALT] SAKLA
    0x03 T YÜKLE
    T [BLOK_UZUNLUK_UST] SAKLA
    KOPYALA

    ; Son satırı (satır 24: 0x83C0..0x83E7, 40 bayt) boşlukla doldur
    0xC0 T YÜKLE
    T [BLOK_HEDEF_ALT] SAKLA
    0x83 T YÜKLE
    T [BLOK_HEDEF_UST] SAKLA
    40 T YÜKLE
    T [BLOK_UZUNLUK_ALT] SAKLA
    0 T YÜKLE
    T [BLOK_UZUNLUK_UST] SAKLA
    ' ' T YÜKLE
    DOLDUR

    imlec_adresi_hesapla ÇAĞIR
    T ÇEK
    DÖN

; -----------------------------------------------------------------------------
; Servis 1: BIOS_KARAKTER_YAZ
; Girdi: T = yazdırılacak karakter (ISO-8859-9 / ASCII)
; '\n' (10) -> yeni satır, 8 veya 127 -> geri silme (Backspace).
; -----------------------------------------------------------------------------
servis_karakter_yaz:
    T [GECICI_KARAKTER] SAKLA

    ; Yeni satır mı? ('\n' = 10 veya '\r' = 13)
    10 KARŞILAŞTIR
    karakter_yeni_satir EŞİTSE ATLA
    13 KARŞILAŞTIR
    karakter_yeni_satir EŞİTSE ATLA

    ; Geri silme (Backspace: 8 veya 127) mi?
    8 KARŞILAŞTIR
    karakter_geri_sil EŞİTSE ATLA
    127 KARŞILAŞTIR
    karakter_geri_sil EŞİTSE ATLA

    ; Normal karakter: mevcut imleç konumuna yaz
    imlec_adresi_hesapla ÇAĞIR
    [GECICI_KARAKTER] T YÜKLE
    T [[IMLEC_ADRES_ALT]] SAKLA

    ; Sütunu ilerlet
    [IMLEC_SUTUN] ARTIR
    [IMLEC_SUTUN] T YÜKLE
    40 KARŞILAŞTIR
    karakter_yaz_bitti KÜÇÜKSE ATLA

karakter_yeni_satir:
    0 T YÜKLE
    T [IMLEC_SUTUN] SAKLA
    [IMLEC_SATIR] ARTIR
    [IMLEC_SATIR] T YÜKLE
    25 KARŞILAŞTIR
    karakter_yaz_bitti KÜÇÜKSE ATLA

    ; 25. satıra ulaşıldı: ekranı 1 satır yukarı kaydır, imleci 24. satırda tut
    24 T YÜKLE
    T [IMLEC_SATIR] SAKLA
    servis_ekran_kaydir ÇAĞIR
    [GECICI_KARAKTER] T YÜKLE
    DÖN

karakter_geri_sil:
    [IMLEC_SUTUN] T YÜKLE
    0 KARŞILAŞTIR
    karakter_yaz_bitti EŞİTSE ATLA
    [IMLEC_SUTUN] AZALT
    imlec_adresi_hesapla ÇAĞIR
    ' ' T YÜKLE
    T [[IMLEC_ADRES_ALT]] SAKLA

karakter_yaz_bitti:
    imlec_adresi_hesapla ÇAĞIR
    [GECICI_KARAKTER] T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; Servis 2: BIOS_METIN_YAZ
; Girdi: X = metin adresi alt baytı, Y = metin adresi üst baytı
; Sıfır (0) baytına kadar tüm karakterleri ekrana yazar.
; -----------------------------------------------------------------------------
servis_metin_yaz:
    X [METIN_ISARET_ALT] SAKLA
    Y [METIN_ISARET_UST] SAKLA
    Y İT
    0 Y YÜKLE

metin_yaz_dongu:
    [[METIN_ISARET_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    metin_yaz_bitti EŞİTSE ATLA

    Y İT
    servis_karakter_yaz ÇAĞIR
    Y ÇEK

    Y ARTIR
    0 Y KARŞILAŞTIR
    metin_yaz_dongu FARKLIYSA ATLA
    [METIN_ISARET_UST] ARTIR
    metin_yaz_dongu ATLA

metin_yaz_bitti:
    Y ÇEK
    DÖN

; -----------------------------------------------------------------------------
; Servis 3: BIOS_TUS_OKU (Beklemesiz)
; Çıktı: Tuş varsa T = tuş kodu (Sıfır bayrağı=0), yoksa T = 0 (Sıfır bayrağı=1)
; -----------------------------------------------------------------------------
servis_tus_oku:
    [PORT_KLAVYE_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    tus_oku_yok EŞİTSE ATLA
    [PORT_KLAVYE_VERI] T YÜKLE
    DÖN
tus_oku_yok:
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; Servis 4: BIOS_TUS_BEKLE (Bloklamalı, KARE BEKLE ile uyur)
; Çıktı: T = basılan tuş kodu
; -----------------------------------------------------------------------------
servis_tus_bekle:
    [PORT_KLAVYE_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    tus_bekle_geldi FARKLIYSA ATLA
    KARE BEKLE
    servis_tus_bekle ATLA
tus_bekle_geldi:
    [PORT_KLAVYE_VERI] T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; Servis 5: BIOS_SATIR_OKU
; İmleç konumunda '_' göstererek kullanıcıdan Enter'a kadar bir satır okur.
; Girilen karakterleri 0x0080 (SATIR_TAMPONU) adresine sıfır sonlandırmalı yazar.
; Çıktı: X = satır uzunluğu (0..SATIR_MAKS_UZUN), T = son tuş (10)
; -----------------------------------------------------------------------------
servis_satir_oku:
    0 T YÜKLE
    T [GECICI_SAYAC] SAKLA

satir_oku_dongu:
    ; İmleç konumuna '_' çiz
    imlec_adresi_hesapla ÇAĞIR
    '_' T YÜKLE
    T [[IMLEC_ADRES_ALT]] SAKLA

    ; Tuş bekle
    servis_tus_bekle ÇAĞIR

    ; Enter (10 veya 13) mi?
    10 KARŞILAŞTIR
    satir_oku_enter EŞİTSE ATLA
    13 KARŞILAŞTIR
    satir_oku_enter EŞİTSE ATLA

    ; Backspace (8 veya 127) mi?
    8 KARŞILAŞTIR
    satir_oku_sil EŞİTSE ATLA
    127 KARŞILAŞTIR
    satir_oku_sil EŞİTSE ATLA

    ; Kontrol karakterlerini (< 32) yoksay
    32 KARŞILAŞTIR
    satir_oku_dongu KÜÇÜKSE ATLA

    ; Tampon dolu mu?
    [GECICI_SAYAC] X YÜKLE
    SATIR_MAKS_UZUN X KARŞILAŞTIR
    satir_oku_dongu BÜYÜK VEYA EŞİTSE ATLA

    ; Karakteri tampona kaydet ve ekrana bas
    T [SATIR_TAMPONU + X] SAKLA
    [GECICI_SAYAC] ARTIR
    servis_karakter_yaz ÇAĞIR
    satir_oku_dongu ATLA

satir_oku_sil:
    [GECICI_SAYAC] T YÜKLE
    0 KARŞILAŞTIR
    satir_oku_dongu EŞİTSE ATLA

    ; Önce mevcut '_' imleç izini temizle
    imlec_adresi_hesapla ÇAĞIR
    ' ' T YÜKLE
    T [[IMLEC_ADRES_ALT]] SAKLA

    ; Tampondan 1 karakter sil ve imleci geri al
    [GECICI_SAYAC] AZALT
    8 T YÜKLE
    servis_karakter_yaz ÇAĞIR
    satir_oku_dongu ATLA

satir_oku_enter:
    ; İmleç '_' karakterini boşlukla sil
    imlec_adresi_hesapla ÇAĞIR
    ' ' T YÜKLE
    T [[IMLEC_ADRES_ALT]] SAKLA

    ; Tamponun sonuna 0 (null terminator) koy
    [GECICI_SAYAC] X YÜKLE
    0 T YÜKLE
    T [SATIR_TAMPONU + X] SAKLA

    ; Alt satıra geç
    10 T YÜKLE
    servis_karakter_yaz ÇAĞIR

    [GECICI_SAYAC] X YÜKLE
    10 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; Servis 7: BIOS_SES_CAL
; Girdi: X = frekans (1-255), Y = süre (20ms kare sayısı)
; -----------------------------------------------------------------------------
servis_ses_cal:
    X [PORT_SES_FREKANS] SAKLA
    Y [PORT_SES_SURE] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; Servis 8: BIOS_SURE_OKU
; Çıktı: T = 50 Hz çalışma sayacı alt baytı, X = üst baytı
; -----------------------------------------------------------------------------
servis_sure_oku:
    [SURE_ALT] T YÜKLE
    [SURE_UST] X YÜKLE
    DÖN

; =============================================================================
; 5. DONANIM KESMESİ (50 Hz ZAMANLAYICI) HİZMET RUTİNİ
; =============================================================================
bios_kesme_giris:
    T İT
    [SURE_ALT] ARTIR
    bios_kesme_cik FARKLIYSA ATLA
    [SURE_UST] ARTIR
bios_kesme_cik:
    T ÇEK
    KESMEDEN DÖN

; =============================================================================
; 6. SABİT METİNLER VE TABLOLAR
; =============================================================================
acilis_metni:
    .METİN "========================================"
    .METİN "      TÜRK-8 KİŞİSEL BİLGİSAYAR         "
    .METİN "     BIOS v1.0 - 31 KB SERBEST RAM      "
    .METİN "========================================"
    .METİN "HAZIR.\n"
    .BAYT 0

; =============================================================================
; 7. İŞLEMCİ VEKTÖR TABLOSU (0xFFFA - 0xFFFF)
; =============================================================================
.BAŞLANGIÇ 0xFFFA
    .KELİME bios_sistem_giris   ; 0xFFFA: VEKTOR_SISTEM (<n> SİSTEM)
    .KELİME bios_sifirla        ; 0xFFFC: VEKTOR_SIFIRLA (Reset / Açılış)
    .KELİME bios_kesme_giris    ; 0xFFFE: VEKTOR_KESME (Donanım IRQ)
