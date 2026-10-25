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
.TANIM DOSYA_AD_TAMPON  0x00C0  ; 8 baytlık boşluk dolgulu dosya adı tamponu (0x00C0-0x00C7)
.TANIM KAYNAK_TAMPON    0x6000  ; 6 KB kaynak kod düzenleyici tamponu (0x6000-0x77FF)
.TANIM ETIKET_TABLOSU   0x7800  ; 64 girişlik (64x16=1024B) etiket/sembol tablosu (0x7800-0x7BFF)
.TANIM DIZIN_TAMPONU    0x7F00  ; Disk 0. sektör (dizin) RAM çalışma tamponu (0x7F00-0x7FFF)

; Faz 6c — Kaynak Düzenleyici (DÜZENLE) ve İki Geçişli Derleyici (DERLE) Değişkenleri (0x0060 - 0x007F)
.TANIM KAYNAK_SON_ALT   0x0060  ; KAYNAK_TAMPON sonundaki '\0' baytının adresi (alt)
.TANIM KAYNAK_SON_UST   0x0061  ; KAYNAK_TAMPON sonundaki '\0' baytının adresi (üst)
.TANIM KAYNAK_OKU_ALT   0x0062  ; DERLE / KAYNAK satır okuma işaretçisi (alt)
.TANIM KAYNAK_OKU_UST   0x0063  ; DERLE / KAYNAK satır okuma işaretçisi (üst)
.TANIM KAYNAK_SATIR_NO  0x0064  ; Düzenleyici / derleyici satır numarası (1..255)
.TANIM DERLE_GECIS      0x0065  ; 0 = etkileşimli KODLA, 1 = DERLE 1. geçiş, 2 = DERLE 2. geçiş
.TANIM DERLE_BAS_ALT    0x0066  ; Derlenen programın başlangıç adresi (alt)
.TANIM DERLE_BAS_UST    0x0067  ; Derlenen programın başlangıç adresi (üst)
.TANIM ETIKET_SAYISI    0x0068  ; Tablodaki kayıtlı etiket/sabit sayısı (0..64)
.TANIM ETIKET_PTR_ALT   0x0069  ; Etiket tablosu arama/yazma işaretçisi (alt)
.TANIM ETIKET_PTR_UST   0x006A  ; Etiket tablosu arama/yazma işaretçisi (üst)
.TANIM DERLE_ONEK       0x006B  ; İşlenen öneki: 0 = yok, '<' = alt bayt, '>' = üst bayt
.TANIM DERLE_KAYDET_VAR 0x006C  ; 1 ise DERLE sonrası otomatik diske kaydet
.TANIM DERLE_SON_X      0x006D  ; Okunan sembol adının bitiş indeksi
.TANIM DERLE_BOYUT_ALT  0x006E  ; Son derlenen programın boyutu (alt)
.TANIM DERLE_BOYUT_UST  0x006F  ; Son derlenen programın boyutu (üst)
.TANIM ETIKET_AD_TAMPON 0x0070  ; 14 baytlık geçici sembol adı tamponu (0x0070-0x007D)
.TANIM DERLE_BAYT_YAZILDI 0x007E ; Geçiş içinde henüz bayt üretildi mi? (0/1)
.TANIM DERLE_TIRNAK_DURUM 0x007F ; Yorum ayıklarken tırnak durumu (0, 34, 39)

; Kabuk (Shell) Sıfır Sayfa Değişkenleri (0x00D0 - 0x00DF)
.TANIM KABUK_SABLON_ALT 0x00D0  ; Komut şablonu işaretçisi (alt bayt)
.TANIM KABUK_SABLON_UST 0x00D1  ; Komut şablonu işaretçisi (üst bayt)
.TANIM KABUK_ARG_ALT    0x00D2  ; Çözümlenen 16-bit argüman adresi (alt bayt)
.TANIM KABUK_ARG_UST    0x00D3  ; Çözümlenen 16-bit argüman adresi (üst bayt)
.TANIM KABUK_INDEKS     0x00D4  ; Satır tamponu okuma indeksi
.TANIM KABUK_SAYAC      0x00D5  ; BELLEK/DİSK döngü sayacı
.TANIM KABUK_SUTUN      0x00D6  ; BELLEK/DİSK sütun/hane sayacı
.TANIM KABUK_HEX_GECICI 0x00D7  ; Hex çevrim geçici baytı
.TANIM KABUK_ARG2_ALT   0x00D8  ; KAYDET 2. argüman (boyut) alt baytı
.TANIM KABUK_ARG2_UST   0x00D9  ; KAYDET 2. argüman (boyut) üst baytı
.TANIM KABUK_DIZIN_OFSET 0x00DA ; Bulunan dizin girişinin (0, 16, ..., 240) ofseti
.TANIM KABUK_BOS_GIRIS  0x00DB  ; İlk boş dizin girişinin ofseti (0xFF = yok)
.TANIM KABUK_SON_SEKTOR 0x00DC  ; Diskteki ilk boş veri sektörü numarası
.TANIM KABUK_SON_KELIME 0x00DD  ; Satırdaki son kelimenin başlangıç ofseti
.TANIM KODLA_PC_ALT     0x00DE  ; Satır assembler (KODLA) yazma adresi alt baytı
.TANIM KODLA_PC_UST     0x00DF  ; Satır assembler (KODLA) yazma adresi üst baytı
.TANIM KODLA_OPKOD      0x00C8  ; Eşleşen komutun opkodu
.TANIM KODLA_TIP        0x00C9  ; Eşleşen komutun işlenen tipi (0=yok, 1=8-bit, 2=16-bit)
.TANIM KODLA_DEGER_ALT  0x00CA  ; Çözümlenen işlenen alt baytı
.TANIM KODLA_DEGER_UST  0x00CB  ; Çözümlenen işlenen üst baytı

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
.TANIM PORT_DISK_KOMUT   0xA010
.TANIM PORT_DISK_DURUM   0xA011
.TANIM PORT_DISK_SEKTOR  0xA012
.TANIM PORT_DISK_ADR_ALT 0xA013
.TANIM PORT_DISK_ADR_UST 0xA014
.TANIM PORT_DISK_SAYI    0xA015
.TANIM PORT_DISK_HATA    0xA016

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

    ; Faz 6c: Kaynak düzenleyici ve derleyici varsayılanlarını kur
    0 T YÜKLE
    T [KAYNAK_SON_ALT] SAKLA
    T [DERLE_GECIS] SAKLA
    T [DERLE_BAS_ALT] SAKLA
    T [DERLE_BOYUT_ALT] SAKLA
    0x60 T YÜKLE
    T [KAYNAK_SON_UST] SAKLA
    0x02 T YÜKLE
    T [DERLE_BAS_UST] SAKLA
    1 T YÜKLE
    T [KAYNAK_SATIR_NO] SAKLA
    T [DERLE_BOYUT_UST] SAKLA

    ; --- POST: Kullanıcı RAM Testi (0x0200 - 0x7FFF = 31 KB) ---
    ; Her 256 baytlık sayfanın ilk baytını 0x5A / 0xA5 deseniyle sına ve sıfırla
    0x00 T YÜKLE
    T [BELLEK_TEST_ALT] SAKLA
    0x02 T YÜKLE
    T [BELLEK_TEST_UST] SAKLA

post_dongusu:
    [[BELLEK_TEST_ALT]] T YÜKLE
    T [GECICI_KARAKTER] SAKLA

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

    [GECICI_KARAKTER] T YÜKLE
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
; 2. ROM KOMUT KABUĞU (YARDIM, TEMİZLE, BİLGİ, BELLEK, ÇALIŞTIR, SÜRE)
; =============================================================================
bios_komut_dongusu:
    ; İstem karakterlerini yaz: "> "
    '>' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

    ; Kullanıcıdan bir satır oku (0x0080 tamponuna)
    5 SİSTEM

    ; Satır başındaki boşlukları atla ve tamponu büyük harfe normalize et
    kabuk_satir_hazirla ÇAĞIR

    ; Boş satır mı?
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    ; --- 1) YARDIM ---
    <kmt_yardim X YÜKLE
    >kmt_yardim Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_yardim_calistir EŞİTSE ATLA

    ; --- 2) TEMİZLE (ASCII: TEMIZLE) ---
    <kmt_temizle X YÜKLE
    >kmt_temizle Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_temizle_calistir EŞİTSE ATLA

    ; --- 3) BİLGİ (ASCII: BILGI) ---
    <kmt_bilgi X YÜKLE
    >kmt_bilgi Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_bilgi_calistir EŞİTSE ATLA

    ; --- 4) SÜRE (ASCII: SURE) ---
    <kmt_sure X YÜKLE
    >kmt_sure Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_sure_calistir EŞİTSE ATLA

    ; --- 5) BELLEK [adres] ---
    <kmt_bellek X YÜKLE
    >kmt_bellek Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_bellek_calistir EŞİTSE ATLA

    ; --- 6) ÇALIŞTIR [adres | dosya_adı] (ASCII: CALISTIR) ---
    <kmt_calistir X YÜKLE
    >kmt_calistir Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_calistir_komutu EŞİTSE ATLA

    ; --- 7) LİSTE (ASCII: LISTE) ---
    <kmt_liste X YÜKLE
    >kmt_liste Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_liste_komutu EŞİTSE ATLA

    ; --- 8) YÜKLE <ad> (ASCII: YUKLE) ---
    <kmt_yukle X YÜKLE
    >kmt_yukle Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_yukle_komutu EŞİTSE ATLA

    ; --- 9) KAYDET <ad> [adres] [boyut] ---
    <kmt_kaydet X YÜKLE
    >kmt_kaydet Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_kaydet_komutu EŞİTSE ATLA

    ; --- 10) SİL <ad> (ASCII: SIL) ---
    <kmt_sil X YÜKLE
    >kmt_sil Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_sil_komutu EŞİTSE ATLA

    ; --- 11) [adres] KODLA (Satır Assembler) ---
    <kmt_kodla X YÜKLE
    >kmt_kodla Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_kodla_komutu EŞİTSE ATLA

    ; --- 12) [YENİ] DÜZENLE (Kaynak Kod Düzenleyici) ---
    <kmt_duzenle X YÜKLE
    >kmt_duzenle Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_duzenle_komutu EŞİTSE ATLA

    ; --- 13) KAYNAK (Kaynak Tamponunu Listele) ---
    <kmt_kaynak X YÜKLE
    >kmt_kaynak Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_kaynak_komutu EŞİTSE ATLA

    ; --- 14) [adres | dosya_adı] DERLE (İki Geçişli Etiketli Derleyici) ---
    <kmt_derle X YÜKLE
    >kmt_derle Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_derle_komutu EŞİTSE ATLA

    ; --- 15) Woz Tarzı Monitör Girişi: "AAAA: BB CC ..." ---
    kabuk_woz_kontrol_et ÇAĞIR
    1 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    ; Tanınmayan komut: hata mesajı yaz
    <metin_bilinmeyen X YÜKLE
    >metin_bilinmeyen Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

; --- Komut İşleyicileri ---

kabuk_yardim_calistir:
    <metin_yardim X YÜKLE
    >metin_yardim Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

kabuk_temizle_calistir:
    0 SİSTEM
    bios_komut_dongusu ATLA

kabuk_bilgi_calistir:
    <metin_bilgi X YÜKLE
    >metin_bilgi Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

kabuk_sure_calistir:
    <metin_sure_baslik X YÜKLE
    >metin_sure_baslik Y YÜKLE
    2 SİSTEM

    ; 8 SİSTEM -> T = alt bayt, X = üst bayt
    8 SİSTEM
    T [KABUK_ARG_ALT] SAKLA
    X [KABUK_ARG_UST] SAKLA

    ; Hex olarak 0xUUUU yazdır
    '0' T YÜKLE
    1 SİSTEM
    'x' T YÜKLE
    1 SİSTEM
    [KABUK_ARG_UST] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    [KABUK_ARG_ALT] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR

    ; Parantez içinde alt baytın 3 basamaklı onluk değerini yazdır
    ' ' T YÜKLE
    1 SİSTEM
    '(' T YÜKLE
    1 SİSTEM
    [KABUK_ARG_ALT] T YÜKLE
    T RAKAMLARA AYIR
    T İT
    X İT
    Y T AKTAR
    1 SİSTEM
    T ÇEK
    1 SİSTEM
    T ÇEK
    1 SİSTEM
    <metin_sure_son X YÜKLE
    >metin_sure_son Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

kabuk_bellek_calistir:
    ; Varsayılan adres: 0x0200
    0x00 T YÜKLE
    T [KABUK_ARG_ALT] SAKLA
    0x02 T YÜKLE
    T [KABUK_ARG_UST] SAKLA

    ; Argüman verilmiş mi kontrol et
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    bellek_dokum_basla EŞİTSE ATLA

    kabuk_hex_adres_oku ÇAĞIR
    1 KARŞILAŞTIR
    bellek_dokum_basla EŞİTSE ATLA
    kabuk_adres_hatasi ATLA

bellek_dokum_basla:
    ; 4 satır x 8 bayt = 32 bayt bellek dökümü
    4 T YÜKLE
    T [KABUK_SAYAC] SAKLA

bellek_satir_dongu:
    ; Satır başı adresi: AAAA:
    [KABUK_ARG_UST] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    [KABUK_ARG_ALT] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    ':' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

    8 T YÜKLE
    T [KABUK_SUTUN] SAKLA

bellek_bayt_dongu:
    [[KABUK_ARG_ALT]] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    ' ' T YÜKLE
    1 SİSTEM

    ; 16-bit adresi 1 artır
    [KABUK_ARG_ALT] ARTIR
    bellek_adres_artti FARKLIYSA ATLA
    [KABUK_ARG_UST] ARTIR
bellek_adres_artti:
    [KABUK_SUTUN] AZALT
    bellek_bayt_dongu FARKLIYSA ATLA

    10 T YÜKLE
    1 SİSTEM

    [KABUK_SAYAC] AZALT
    bellek_satir_dongu FARKLIYSA ATLA
    bios_komut_dongusu ATLA

kabuk_calistir_komutu:
    ; Varsayılan çalıştırma adresi: DERLE_BAS (açılışta 0x0200, DERLE sonrası derlenen adres)
    [DERLE_BAS_ALT] T YÜKLE
    T [KABUK_ARG_ALT] SAKLA
    [DERLE_BAS_UST] T YÜKLE
    T [KABUK_ARG_UST] SAKLA

    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    calistir_hedefe_git EŞİTSE ATLA

    ; Önce hex adres olarak çözümlemeyi dene (KABUK_INDEKS'i koru)
    [KABUK_INDEKS] T YÜKLE
    T İT
    kabuk_hex_adres_oku ÇAĞIR
    1 KARŞILAŞTIR
    calistir_hex_tamam EŞİTSE ATLA

    ; Hex adres değilse diskten dosya adı olarak yükle ve çalıştır
    T ÇEK
    T [KABUK_INDEKS] SAKLA
    kabuk_dosya_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_adres_hatasi EŞİTSE ATLA

    kabuk_diskten_dosya_yukle ÇAĞIR
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA
    calistir_hedefe_git ATLA

calistir_hex_tamam:
    T ÇEK

calistir_hedefe_git:
    ; Kullanıcı programı DÖN ile biterse yeniden kabuk döngüsüne dönsün
    [KABUK_ARG_ALT] ÇAĞIR
    bios_komut_dongusu ATLA

kabuk_adres_hatasi:
    <metin_hata_adres X YÜKLE
    >metin_hata_adres Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

; -----------------------------------------------------------------------------
; LİSTE Komutu: Diskin 0. sektöründeki dizin girişlerini listeler
; -----------------------------------------------------------------------------
kabuk_liste_komutu:
    kabuk_dizin_sektoru_oku ÇAĞIR
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    <metin_liste_baslik X YÜKLE
    >metin_liste_baslik Y YÜKLE
    2 SİSTEM

    0 T YÜKLE
    T [KABUK_DIZIN_OFSET] SAKLA
    T [KABUK_SAYAC] SAKLA       ; Bulunan dosya sayısı

liste_giris_dongu:
    [KABUK_DIZIN_OFSET] X YÜKLE
    [DIZIN_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    liste_sonraki_giris EŞİTSE ATLA
    0xE5 KARŞILAŞTIR
    liste_sonraki_giris EŞİTSE ATLA

    ; Geçerli dosya bulundu: sayacı artır
    [KABUK_SAYAC] ARTIR

    ; 1) 8 karakterlik dosya adını yazdır
    ' ' T YÜKLE
    1 SİSTEM
    8 T YÜKLE
    T [KABUK_SUTUN] SAKLA
    [KABUK_DIZIN_OFSET] X YÜKLE
liste_ad_dongu:
    [DIZIN_TAMPONU + X] T YÜKLE
    X İT
    1 SİSTEM
    X ÇEK
    X ARTIR
    [KABUK_SUTUN] AZALT
    liste_ad_dongu FARKLIYSA ATLA

    ' ' T YÜKLE
    1 SİSTEM
    '0' T YÜKLE
    1 SİSTEM
    'x' T YÜKLE
    1 SİSTEM

    ; 2) Yükleme adresini (ofset + 11 üst, ofset + 10 alt) hex yazdır
    [KABUK_DIZIN_OFSET] T YÜKLE
    11 TOPLA
    T X AKTAR
    [DIZIN_TAMPONU + X] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR

    [KABUK_DIZIN_OFSET] T YÜKLE
    10 TOPLA
    T X AKTAR
    [DIZIN_TAMPONU + X] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR

    ' ' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

    ; 3) Sektör sayısını (ofset + 9) 3 haneli onluk olarak yazdır
    [KABUK_DIZIN_OFSET] T YÜKLE
    9 TOPLA
    T X AKTAR
    [DIZIN_TAMPONU + X] T YÜKLE
    T RAKAMLARA AYIR
    T İT
    X İT
    Y T AKTAR
    1 SİSTEM
    T ÇEK
    1 SİSTEM
    T ÇEK
    1 SİSTEM

    <metin_sektor_eki X YÜKLE
    >metin_sektor_eki Y YÜKLE
    2 SİSTEM

liste_sonraki_giris:
    [KABUK_DIZIN_OFSET] T YÜKLE
    16 TOPLA
    T [KABUK_DIZIN_OFSET] SAKLA
    0 KARŞILAŞTIR
    liste_giris_dongu FARKLIYSA ATLA

    [KABUK_SAYAC] T YÜKLE
    0 KARŞILAŞTIR
    liste_bitti FARKLIYSA ATLA
    <metin_disk_bos X YÜKLE
    >metin_disk_bos Y YÜKLE
    2 SİSTEM
liste_bitti:
    bios_komut_dongusu ATLA

; -----------------------------------------------------------------------------
; YÜKLE <ad> Komutu: Dosyayı diskten belleğe yükler (çalıştırmaz)
; -----------------------------------------------------------------------------
kabuk_yukle_komutu:
    kabuk_dosya_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_dosya_adi_hatasi EŞİTSE ATLA

    kabuk_diskten_dosya_yukle ÇAĞIR
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    <metin_yuklendi X YÜKLE
    >metin_yuklendi Y YÜKLE
    2 SİSTEM
    [KABUK_ARG_UST] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    [KABUK_ARG_ALT] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    10 T YÜKLE
    1 SİSTEM
    bios_komut_dongusu ATLA

; -----------------------------------------------------------------------------
; KAYDET <ad> [adres] [boyut] Komutu:
; Bellekteki veriyi diske kaydeder (varsayılan adres=0x0200, boyut=0x0100=256B)
; -----------------------------------------------------------------------------
kabuk_kaydet_komutu:
    kabuk_dosya_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_dosya_adi_hatasi EŞİTSE ATLA

    ; Varsayılan başlangıç adresi = DERLE_BAS (0x0200), boyut = DERLE_BOYUT (0x0100)
    [DERLE_BAS_ALT] T YÜKLE
    T [KABUK_ARG_ALT] SAKLA
    [DERLE_BAS_UST] T YÜKLE
    T [KABUK_ARG_UST] SAKLA
    [DERLE_BOYUT_ALT] T YÜKLE
    T [KABUK_ARG2_ALT] SAKLA
    [DERLE_BOYUT_UST] T YÜKLE
    T [KABUK_ARG2_UST] SAKLA

    ; Opsiyonel 1. hex argüman (başlangıç adresi) var mı?
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kaydet_basla EŞİTSE ATLA

    kabuk_hex_adres_oku ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_adres_hatasi EŞİTSE ATLA

    ; Opsiyonel 2. hex argüman (boyut) var mı?
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kaydet_basla EŞİTSE ATLA

    ; İlk argümanı (başlangıç adresi) yığına koru, 2. argümanı oku
    [KABUK_ARG_ALT] T YÜKLE
    T İT
    [KABUK_ARG_UST] T YÜKLE
    T İT
    kabuk_hex_adres_oku ÇAĞIR
    0 KARŞILAŞTIR
    kaydet_arg2_hata EŞİTSE ATLA

    [KABUK_ARG_ALT] T YÜKLE
    T [KABUK_ARG2_ALT] SAKLA
    [KABUK_ARG_UST] T YÜKLE
    T [KABUK_ARG2_UST] SAKLA
    T ÇEK
    T [KABUK_ARG_UST] SAKLA
    T ÇEK
    T [KABUK_ARG_ALT] SAKLA
    kaydet_basla ATLA

kaydet_arg2_hata:
    T ÇEK
    T ÇEK
    kabuk_adres_hatasi ATLA

kaydet_basla:
    ; Dizin sektörünü oku
    kabuk_dizin_sektoru_oku ÇAĞIR
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    ; Aynı isimde dosya zaten varsa önce sil (üzerine yazma desteği)
    kabuk_dizinde_dosya_ara ÇAĞIR
    1 KARŞILAŞTIR
    kaydet_eskiyi_sil EŞİTSE ATLA
    kaydet_yer_bul ATLA

kaydet_eskiyi_sil:
    [KABUK_DIZIN_OFSET] X YÜKLE
    0xE5 T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA

kaydet_yer_bul:
    ; İlk boş dizin girişini (KABUK_BOS_GIRIS) ve boş veri sektörünü (KABUK_SON_SEKTOR) bul
    0xFF T YÜKLE
    T [KABUK_BOS_GIRIS] SAKLA
    1 T YÜKLE
    T [KABUK_SON_SEKTOR] SAKLA
    0 T YÜKLE
    T [KABUK_DIZIN_OFSET] SAKLA

kaydet_tara_dongu:
    [KABUK_DIZIN_OFSET] X YÜKLE
    [DIZIN_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kaydet_bos_aday EŞİTSE ATLA
    0xE5 KARŞILAŞTIR
    kaydet_bos_aday EŞİTSE ATLA

    ; Dolu giriş: bitiş sektörü = baslangic (ofset+8) + sayi (ofset+9)
    [KABUK_DIZIN_OFSET] T YÜKLE
    8 TOPLA
    T X AKTAR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [KABUK_HEX_GECICI] SAKLA
    X ARTIR
    [DIZIN_TAMPONU + X] T YÜKLE
    [KABUK_HEX_GECICI] TOPLA
    [KABUK_SON_SEKTOR] KARŞILAŞTIR
    kaydet_tara_sonraki KÜÇÜK VEYA EŞİTSE ATLA
    T [KABUK_SON_SEKTOR] SAKLA
    kaydet_tara_sonraki ATLA

kaydet_bos_aday:
    [KABUK_BOS_GIRIS] T YÜKLE
    0xFF KARŞILAŞTIR
    kaydet_tara_sonraki FARKLIYSA ATLA
    [KABUK_DIZIN_OFSET] T YÜKLE
    T [KABUK_BOS_GIRIS] SAKLA

kaydet_tara_sonraki:
    [KABUK_DIZIN_OFSET] T YÜKLE
    16 TOPLA
    T [KABUK_DIZIN_OFSET] SAKLA
    0 KARŞILAŞTIR
    kaydet_tara_dongu FARKLIYSA ATLA

    ; Boş dizin girişi bulundu mu?
    [KABUK_BOS_GIRIS] T YÜKLE
    0xFF KARŞILAŞTIR
    kabuk_disk_dolu_hatasi EŞİTSE ATLA

    ; Sektör sayısını hesapla: üst_bayt + (alt_bayt > 0 ? 1 : 0), en az 1
    [KABUK_ARG2_UST] T YÜKLE
    T [KABUK_SAYAC] SAKLA
    [KABUK_ARG2_ALT] T YÜKLE
    0 KARŞILAŞTIR
    kaydet_sektor_kontrol EŞİTSE ATLA
    [KABUK_SAYAC] ARTIR
kaydet_sektor_kontrol:
    [KABUK_SAYAC] T YÜKLE
    0 KARŞILAŞTIR
    kaydet_veri_yaz FARKLIYSA ATLA
    1 T YÜKLE
    T [KABUK_SAYAC] SAKLA
    T [KABUK_ARG2_UST] SAKLA

kaydet_veri_yaz:
    ; Veri sektörlerini diske yaz
    [KABUK_SON_SEKTOR] T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    [KABUK_ARG_ALT] T YÜKLE
    T [PORT_DISK_ADR_ALT] SAKLA
    [KABUK_ARG_UST] T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    [KABUK_SAYAC] T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    2 T YÜKLE
    T [PORT_DISK_KOMUT] SAKLA
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    kabuk_disk_hatasi FARKLIYSA ATLA

    ; Dizin girişini doldur (16 bayt)
    [KABUK_BOS_GIRIS] X YÜKLE
    0 Y YÜKLE
kaydet_isim_kopyala:
    [DOSYA_AD_TAMPON + Y] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    Y ARTIR
    8 Y KARŞILAŞTIR
    kaydet_isim_kopyala FARKLIYSA ATLA

    [KABUK_SON_SEKTOR] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [KABUK_SAYAC] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [KABUK_ARG_ALT] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [KABUK_ARG_UST] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [KABUK_ARG2_ALT] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    [KABUK_ARG2_UST] T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    1 T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA
    X ARTIR
    0 T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA

    ; Güncel dizin sektörünü (sektör 0) diske geri yaz
    kabuk_dizin_sektoru_yaz ÇAĞIR
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    <metin_kaydedildi X YÜKLE
    >metin_kaydedildi Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

; -----------------------------------------------------------------------------
; SİL <ad> Komutu: Dosyayı disk dizininden siler
; -----------------------------------------------------------------------------
kabuk_sil_komutu:
    kabuk_dosya_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_dosya_adi_hatasi EŞİTSE ATLA

    kabuk_dizin_sektoru_oku ÇAĞIR
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    kabuk_dizinde_dosya_ara ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_dosya_yok_hatasi EŞİTSE ATLA

    [KABUK_DIZIN_OFSET] X YÜKLE
    0xE5 T YÜKLE
    T [DIZIN_TAMPONU + X] SAKLA

    kabuk_dizin_sektoru_yaz ÇAĞIR
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    <metin_silindi X YÜKLE
    >metin_silindi Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

kabuk_dosya_adi_hatasi:
    <metin_hata_dosya_adi X YÜKLE
    >metin_hata_dosya_adi Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

kabuk_dosya_yok_hatasi:
    <metin_hata_dosya_yok X YÜKLE
    >metin_hata_dosya_yok Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

kabuk_disk_dolu_hatasi:
    <metin_hata_disk_dolu X YÜKLE
    >metin_hata_disk_dolu Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

kabuk_disk_hatasi:
    <metin_hata_disk X YÜKLE
    >metin_hata_disk Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

; =============================================================================
; 2B. FAZ 6a — WOZ TARZI BELLEK MONİTÖRÜ ("AAAA: BB CC ..." veya "AAAA:")
; =============================================================================
kabuk_woz_kontrol_et:
    ; Satır içinde ':' karakteri var mı ara
    [KABUK_INDEKS] X YÜKLE
woz_iki_nokta_ara:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    woz_degil EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    woz_degil EŞİTSE ATLA
    ':' KARŞILAŞTIR
    woz_iki_nokta_bulundu EŞİTSE ATLA
    X ARTIR
    woz_iki_nokta_ara ATLA

woz_degil:
    0 T YÜKLE
    DÖN

woz_iki_nokta_bulundu:
    ; ':' yerine geçici olarak ' ' koy ki kabuk_hex_adres_oku adresi temiz okusun
    ' ' T YÜKLE
    T [SATIR_TAMPONU + X] SAKLA
    X İT
    kabuk_hex_adres_oku ÇAĞIR
    X ÇEK
    1 KARŞILAŞTIR
    woz_adres_tamam EŞİTSE ATLA

    ; Geçerli hex adres değilse ':' karakterini geri koy ve 0 dön
    ':' T YÜKLE
    T [SATIR_TAMPONU + X] SAKLA
    0 T YÜKLE
    DÖN

woz_adres_tamam:
    ; ':' karakterinden sonraki konuma geç
    X ARTIR
    X [KABUK_INDEKS] SAKLA
    kabuk_bosluk_atla ÇAĞIR

    ; ':' sonrasında hiç bayt yazılmamışsa ("0300:"), o adresten 8 bayt döküm ver
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    woz_tek_satir_dokum EŞİTSE ATLA

    ; Ardışık hex baytları oku ve [[KABUK_ARG_ALT]] adresine yaz
    [KABUK_ARG_ALT] T YÜKLE
    T [KODLA_PC_ALT] SAKLA
    [KABUK_ARG_UST] T YÜKLE
    T [KODLA_PC_UST] SAKLA

woz_bayt_dongu:
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    woz_yazma_bitti EŞİTSE ATLA

    kabuk_hex_adres_oku ÇAĞIR
    0 KARŞILAŞTIR
    woz_veri_hatasi EŞİTSE ATLA

    ; Baytı hedef adrese yaz ve adresi 1 artır
    [KABUK_ARG_ALT] T YÜKLE
    T [[KODLA_PC_ALT]] SAKLA
    [KODLA_PC_ALT] ARTIR
    woz_pc_artti FARKLIYSA ATLA
    [KODLA_PC_UST] ARTIR
woz_pc_artti:
    woz_bayt_dongu ATLA

woz_yazma_bitti:
    1 T YÜKLE
    DÖN

woz_veri_hatasi:
    <metin_hata_adres X YÜKLE
    >metin_hata_adres Y YÜKLE
    2 SİSTEM
    1 T YÜKLE
    DÖN

woz_tek_satir_dokum:
    T ÇEK
    T ÇEK
    1 T YÜKLE
    T [KABUK_SAYAC] SAKLA
    bellek_satir_dongu ATLA

; =============================================================================
; 2C. FAZ 6b — ETKİLEŞİMLİ SATIR ASSEMBLER ([adres] KODLA)
; =============================================================================
kabuk_kodla_komutu:
    ; Varsayılan başlangıç adresi: 0x0300
    0x00 T YÜKLE
    T [KODLA_PC_ALT] SAKLA
    0x03 T YÜKLE
    T [KODLA_PC_UST] SAKLA

    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kodla_basla EŞİTSE ATLA

    kabuk_hex_adres_oku ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_adres_hatasi EŞİTSE ATLA
    [KABUK_ARG_ALT] T YÜKLE
    T [KODLA_PC_ALT] SAKLA
    [KABUK_ARG_UST] T YÜKLE
    T [KODLA_PC_UST] SAKLA

kodla_basla:
    <metin_kodla_baslik X YÜKLE
    >metin_kodla_baslik Y YÜKLE
    2 SİSTEM

kodla_satir_dongu:
    ; İstem: "AAAA ? "
    [KODLA_PC_UST] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    [KODLA_PC_ALT] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    ' ' T YÜKLE
    1 SİSTEM
    '?' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

    ; Kullanıcıdan assembly satırı oku
    5 SİSTEM
    kabuk_satir_hazirla ÇAĞIR

    ; Boş satır, ".", "ÇIK" veya "BİTTİ" ise satır assembler kipinden çık
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kodla_cikis EŞİTSE ATLA
    '.' KARŞILAŞTIR
    kodla_cikis EŞİTSE ATLA

    <kmt_cik X YÜKLE
    >kmt_cik Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kodla_cikis EŞİTSE ATLA

    <kmt_bitti X YÜKLE
    >kmt_bitti Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kodla_cikis EŞİTSE ATLA

    ; Eğer doğrudan "<adres> ÇALIŞTIR" yazıldıysa KODLA kipinden çıkıp çalıştır!
    <kmt_calistir X YÜKLE
    >kmt_calistir Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_calistir_komutu EŞİTSE ATLA

    ; Tek satırı derle ve KODLA_PC adresine yaz
    kodla_tek_satir_derle ÇAĞIR
    1 KARŞILAŞTIR
    kodla_satir_dongu EŞİTSE ATLA

    <metin_hata_sozdizimi X YÜKLE
    >metin_hata_sozdizimi Y YÜKLE
    2 SİSTEM
    kodla_satir_dongu ATLA

kodla_cikis:
    bios_komut_dongusu ATLA

; -----------------------------------------------------------------------------
; kodla_tek_satir_derle:
; SATIR_TAMPONU[KABUK_INDEKS..] içindeki Türkçe assembly satırını
; kodla_komut_tablosu üzerinden eşleştirir, makine kodunu [[KODLA_PC_ALT]]
; adresine yazar ve KODLA_PC adresini komut boyutu kadar ilerletir.
; Başarılıysa T = 1, eşleşmezse T = 0 döner.
; -----------------------------------------------------------------------------
kodla_tek_satir_derle:
    <kodla_komut_tablosu T YÜKLE
    T [KABUK_SABLON_ALT] SAKLA
    >kodla_komut_tablosu T YÜKLE
    T [KABUK_SABLON_UST] SAKLA

kodla_tablo_dongu:
    0 Y YÜKLE
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    0xFF KARŞILAŞTIR
    kodla_derle_basarisiz EŞİTSE ATLA
    T [KODLA_OPKOD] SAKLA

    Y ARTIR
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    T [KODLA_TIP] SAKLA

    ; Şablon metni Y=2'den başlar; SATIR_TAMPONU[KABUK_INDEKS..] ile karşılaştır
    2 Y YÜKLE
    [KABUK_INDEKS] X YÜKLE

kodla_desen_dongu:
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    kodla_desen_sonu EŞİTSE ATLA

    ; '#' yer tutucusu mu? (Sayısal işlenen)
    '#' KARŞILAŞTIR
    kodla_islenen_oku EŞİTSE ATLA

    ; Şablondaki boşluk: tampondaki 1 veya daha fazla boşlukla eşleşir
    ' ' KARŞILAŞTIR
    kodla_desen_bosluk EŞİTSE ATLA

    ; Normal sabit karakter karşılaştırması
    T [KABUK_HEX_GECICI] SAKLA
    [SATIR_TAMPONU + X] T YÜKLE
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    kodla_sonraki_kayit FARKLIYSA ATLA
    X ARTIR
    Y ARTIR
    kodla_desen_dongu ATLA

kodla_desen_bosluk:
    ; Eğer şablondaki sıradaki karakter '+' veya ']' ise, ya da bir önceki karakter
    ; '+' veya '[' idiyse boşluk isteğe bağlıdır; değilse en az 1 boşluk zorunludur.
    Y İT
    Y ARTIR
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    Y ÇEK
    '+' KARŞILAŞTIR
    kodla_opsiyonel_bosluk EŞİTSE ATLA
    ']' KARŞILAŞTIR
    kodla_opsiyonel_bosluk EŞİTSE ATLA

    Y İT
    Y AZALT
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    Y ÇEK
    '+' KARŞILAŞTIR
    kodla_opsiyonel_bosluk EŞİTSE ATLA
    '[' KARŞILAŞTIR
    kodla_opsiyonel_bosluk EŞİTSE ATLA

    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    kodla_sonraki_kayit FARKLIYSA ATLA
kodla_fazla_bosluk_gec:
    X ARTIR
    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    kodla_fazla_bosluk_gec EŞİTSE ATLA
    Y ARTIR
    kodla_desen_dongu ATLA

kodla_opsiyonel_bosluk:
    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    kodla_opsiyonel_bitti FARKLIYSA ATLA
    X ARTIR
    kodla_opsiyonel_bosluk ATLA
kodla_opsiyonel_bitti:
    Y ARTIR
    kodla_desen_dongu ATLA

kodla_islenen_oku:
    ; X konumundan itibaren 8-bit veya 16-bit sayısal işleneni oku
    Y İT
    kodla_sayi_coz ÇAĞIR
    Y ÇEK
    0 KARŞILAŞTIR
    kodla_sonraki_kayit EŞİTSE ATLA
    Y ARTIR
    kodla_desen_dongu ATLA

kodla_desen_sonu:
    ; Satırın geri kalanında yalnızca boşluk veya '\0' olmalı
kodla_son_bosluk_kontrol:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kodla_eslesti_yaz EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    kodla_sonraki_kayit FARKLIYSA ATLA
    X ARTIR
    kodla_son_bosluk_kontrol ATLA

kodla_eslesti_yaz:
    ; 1) Opkod baytını yaz
    [KODLA_OPKOD] T YÜKLE
    kodla_bayt_yaz ÇAĞIR

    ; 2) İşlenen tipine göre (0, 1 veya 2 bayt) işleneni yaz
    [KODLA_TIP] T YÜKLE
    0 KARŞILAŞTIR
    kodla_yaz_tamam EŞİTSE ATLA

    ; Alt baytı yaz
    [KODLA_DEGER_ALT] T YÜKLE
    kodla_bayt_yaz ÇAĞIR

    [KODLA_TIP] T YÜKLE
    1 KARŞILAŞTIR
    kodla_yaz_tamam EŞİTSE ATLA

    ; 16-bit işlenen: üst baytı da yaz
    [KODLA_DEGER_UST] T YÜKLE
    kodla_bayt_yaz ÇAĞIR

kodla_yaz_tamam:
    1 T YÜKLE
    DÖN

kodla_sonraki_kayit:
    ; Şablonun sonundaki '\0' baytını bulup bir sonraki kayda ilerle
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    kodla_kayit_sonu_bulundu EŞİTSE ATLA
    Y ARTIR
    kodla_sonraki_kayit ATLA

kodla_kayit_sonu_bulundu:
    Y ARTIR
    Y T AKTAR
    [KABUK_SABLON_ALT] TOPLA
    T [KABUK_SABLON_ALT] SAKLA
    [KABUK_SABLON_UST] T YÜKLE
    0 ELDEYLE TOPLA
    T [KABUK_SABLON_UST] SAKLA
    kodla_tablo_dongu ATLA

kodla_derle_basarisiz:
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; kodla_bayt_yaz:
; T yazmacındaki baytı [[KODLA_PC_ALT]] adresine yazar (DERLE 1. geçiş hariç)
; ve KODLA_PC'yi 1 artırır.
; -----------------------------------------------------------------------------
kodla_bayt_yaz:
    T İT
    [DERLE_GECIS] T YÜKLE
    1 KARŞILAŞTIR
    kodla_bayt_sadece_say EŞİTSE ATLA
    T ÇEK
    T [[KODLA_PC_ALT]] SAKLA
    kodla_bayt_pc_artir ATLA
kodla_bayt_sadece_say:
    T ÇEK
kodla_bayt_pc_artir:
    [KODLA_PC_ALT] ARTIR
    kodla_bayt_yaz_cik FARKLIYSA ATLA
    [KODLA_PC_UST] ARTIR
kodla_bayt_yaz_cik:
    DÖN

; -----------------------------------------------------------------------------
; kodla_sayi_coz:
; SATIR_TAMPONU + X konumundan itibaren isteğe bağlı '<' (alt bayt) veya '>' (üst bayt)
; önekli 'c' karakter sabiti, etiket/sabit adı veya onaltılık (0X, $ veya doğrudan hex)
; sayıyı okur -> KODLA_DEGER_ALT / UST.
; X yazmacını işlenenin sonuna ilerletir. Başarılıysa T = 1, değilse T = 0 döner.
; -----------------------------------------------------------------------------
kodla_sayi_coz:
    0 T YÜKLE
    T [DERLE_ONEK] SAKLA

    ; Boşlukları geç
kodla_sayi_bosluk:
    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    kodla_onek_kontrol FARKLIYSA ATLA
    X ARTIR
    kodla_sayi_bosluk ATLA

kodla_onek_kontrol:
    [SATIR_TAMPONU + X] T YÜKLE
    '<' KARŞILAŞTIR
    kodla_onek_kaydet EŞİTSE ATLA
    '>' KARŞILAŞTIR
    kodla_onek_kaydet EŞİTSE ATLA
    kodla_sayi_basla ATLA

kodla_onek_kaydet:
    T [DERLE_ONEK] SAKLA
    X ARTIR

kodla_sayi_basla:
    ; Tek tırnaklı karakter sabiti mi? ('A')
    [SATIR_TAMPONU + X] T YÜKLE
    39 KARŞILAŞTIR          ; 39 = '\''
    kodla_karakter_sabiti EŞİTSE ATLA

    ; Başlangıç X indeksini kaydet (sembol araması veya geri dönüş için)
    X [KABUK_SON_KELIME] SAKLA

    ; Eğer DERLE kipindeysek (DERLE_GECIS != 0) ve ilk karakter 'A'..'Z' veya '_' ise
    ; önce etiket/sabit tablosunda ara
    [DERLE_GECIS] T YÜKLE
    0 KARŞILAŞTIR
    kodla_dogrudan_sayi EŞİTSE ATLA

    [SATIR_TAMPONU + X] T YÜKLE
    '_' KARŞILAŞTIR
    kodla_sembol_dene EŞİTSE ATLA
    'A' KARŞILAŞTIR
    kodla_dogrudan_sayi KÜÇÜKSE ATLA
    '[' KARŞILAŞTIR
    kodla_dogrudan_sayi BÜYÜK VEYA EŞİTSE ATLA

kodla_sembol_dene:
    derle_etiket_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    kodla_sembol_degil EŞİTSE ATLA
    X [DERLE_SON_X] SAKLA
    derle_etiket_bul ÇAĞIR
    1 KARŞILAŞTIR
    kodla_sembol_bulundu EŞİTSE ATLA

kodla_sembol_degil:
    ; Tabloda bulunamadı: X'i geri yükle ve hex sayı olarak okumayı dene (ör. FF, A0)
    [KABUK_SON_KELIME] X YÜKLE

kodla_dogrudan_sayi:
    [SATIR_TAMPONU + X] T YÜKLE
    ; '$' öneki mi?
    '$' KARŞILAŞTIR
    kodla_dolar_gec EŞİTSE ATLA

    ; '0X' öneki mi?
    '0' KARŞILAŞTIR
    kodla_hex_dongu_hazirla FARKLIYSA ATLA
    X ARTIR
    [SATIR_TAMPONU + X] T YÜKLE
    'X' KARŞILAŞTIR
    kodla_0x_gec EŞİTSE ATLA
    X AZALT
    kodla_hex_dongu_hazirla ATLA

kodla_sembol_bulundu:
    [DERLE_SON_X] X YÜKLE
    kodla_onek_uygula ATLA

kodla_dolar_gec:
    X ARTIR
    kodla_hex_dongu_hazirla ATLA

kodla_0x_gec:
    X ARTIR

kodla_hex_dongu_hazirla:
    0 T YÜKLE
    T [KODLA_DEGER_ALT] SAKLA
    T [KODLA_DEGER_UST] SAKLA
    T [KABUK_SUTUN] SAKLA

kodla_hex_okuma:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kodla_hex_bitti EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    kodla_hex_bitti EŞİTSE ATLA
    ']' KARŞILAŞTIR
    kodla_hex_bitti EŞİTSE ATLA
    '+' KARŞILAŞTIR
    kodla_hex_bitti EŞİTSE ATLA
    ',' KARŞILAŞTIR
    kodla_hex_bitti EŞİTSE ATLA

    '0' KARŞILAŞTIR
    kodla_hex_basarisiz KÜÇÜKSE ATLA
    ':' KARŞILAŞTIR
    kodla_rakam_ekle KÜÇÜKSE ATLA

    'A' KARŞILAŞTIR
    kodla_hex_basarisiz KÜÇÜKSE ATLA
    'G' KARŞILAŞTIR
    kodla_hex_basarisiz BÜYÜK VEYA EŞİTSE ATLA
    'A' ÇIKAR
    10 TOPLA
    kodla_nibble_kaydir ATLA

kodla_rakam_ekle:
    '0' ÇIKAR

kodla_nibble_kaydir:
    T [KABUK_HEX_GECICI] SAKLA
    4 Y YÜKLE
kodla_kaydir_4:
    [KODLA_DEGER_ALT] T YÜKLE
    T SOLA KAYDIR
    T [KODLA_DEGER_ALT] SAKLA
    [KODLA_DEGER_UST] T YÜKLE
    T SOLA DÖNDÜR
    T [KODLA_DEGER_UST] SAKLA
    Y AZALT
    kodla_kaydir_4 FARKLIYSA ATLA

    [KODLA_DEGER_ALT] T YÜKLE
    [KABUK_HEX_GECICI] VEYA
    T [KODLA_DEGER_ALT] SAKLA

    [KABUK_SUTUN] ARTIR
    X ARTIR
    kodla_hex_okuma ATLA

kodla_hex_bitti:
    [KABUK_SUTUN] T YÜKLE
    0 KARŞILAŞTIR
    kodla_hex_basarisiz EŞİTSE ATLA
    kodla_onek_uygula ATLA

kodla_karakter_sabiti:
    X ARTIR
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    kodla_sayi_hata EŞİTSE ATLA
    T [KODLA_DEGER_ALT] SAKLA
    0 T YÜKLE
    T [KODLA_DEGER_UST] SAKLA
    X ARTIR
    [SATIR_TAMPONU + X] T YÜKLE
    39 KARŞILAŞTIR
    kodla_sayi_hata FARKLIYSA ATLA
    X ARTIR

kodla_onek_uygula:
    [DERLE_ONEK] T YÜKLE
    0 KARŞILAŞTIR
    kodla_sayi_tamam EŞİTSE ATLA
    '<' KARŞILAŞTIR
    kodla_onek_alt EŞİTSE ATLA
    ; '>' öneki: üst baytı alt bayta taşı
    [KODLA_DEGER_UST] T YÜKLE
    T [KODLA_DEGER_ALT] SAKLA
kodla_onek_alt:
    0 T YÜKLE
    T [KODLA_DEGER_UST] SAKLA
kodla_sayi_tamam:
    1 T YÜKLE
    DÖN

kodla_hex_basarisiz:
    ; Eğer DERLE 1. geçişindeysek (DERLE_GECIS == 1), ileri referanslı bir etiket olabilir!
    [DERLE_GECIS] T YÜKLE
    1 KARŞILAŞTIR
    kodla_sayi_hata FARKLIYSA ATLA

    [KABUK_SON_KELIME] X YÜKLE
    derle_etiket_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    kodla_sayi_hata EŞİTSE ATLA

    0 T YÜKLE
    T [KODLA_DEGER_ALT] SAKLA
    T [KODLA_DEGER_UST] SAKLA
    1 T YÜKLE
    DÖN

kodla_sayi_hata:
    0 T YÜKLE
    DÖN

; =============================================================================
; 2D. FAZ 6c — KAYNAK DÜZENLEYİCİ (DÜZENLE, KAYNAK) VE ETİKETLİ DERLEYİCİ (DERLE)
; =============================================================================

; -----------------------------------------------------------------------------
; duzenle_tampon_sifirla:
; KAYNAK_TAMPON (0x6000) alanını boşaltır ve satır sayacını 1 yapar.
; -----------------------------------------------------------------------------
duzenle_tampon_sifirla:
    0 T YÜKLE
    T [KAYNAK_SON_ALT] SAKLA
    0x60 T YÜKLE
    T [KAYNAK_SON_UST] SAKLA
    0 T YÜKLE
    T [[KAYNAK_SON_ALT]] SAKLA
    1 T YÜKLE
    T [KAYNAK_SATIR_NO] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; duzenle_sonu_hizala:
; KAYNAK_TAMPON (0x6000) içindeki mevcut metnin sonunu ('\0') ve satır sayısını
; hesaplayarak KAYNAK_SON_ALT/UST ve KAYNAK_SATIR_NO değerlerini günceller.
; -----------------------------------------------------------------------------
duzenle_sonu_hizala:
    0 T YÜKLE
    T [KAYNAK_SON_ALT] SAKLA
    0x60 T YÜKLE
    T [KAYNAK_SON_UST] SAKLA
    1 T YÜKLE
    T [KAYNAK_SATIR_NO] SAKLA

duzenle_hizala_dongu:
    [[KAYNAK_SON_ALT]] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_hizala_bitti EŞİTSE ATLA
    10 KARŞILAŞTIR
    duzenle_hizala_ilerle FARKLIYSA ATLA
    [KAYNAK_SATIR_NO] ARTIR
duzenle_hizala_ilerle:
    [KAYNAK_SON_ALT] ARTIR
    duzenle_hizala_dongu FARKLIYSA ATLA
    [KAYNAK_SON_UST] ARTIR
    duzenle_hizala_dongu ATLA
duzenle_hizala_bitti:
    DÖN

; -----------------------------------------------------------------------------
; kabuk_duzenle_komutu:
; Etkileşimli kaynak kod düzenleyicisini başlatır.
; "YENİ DÜZENLE" veya "DÜZENLE YENİ" yazılırsa önce kaynak tamponunu sıfırlar.
; -----------------------------------------------------------------------------
kabuk_duzenle_komutu:
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_mevcut_ac EŞİTSE ATLA

    <kmt_yeni X YÜKLE
    >kmt_yeni Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    duzenle_yeni_baslat EŞİTSE ATLA
    duzenle_mevcut_ac ATLA

duzenle_yeni_baslat:
    duzenle_tampon_sifirla ÇAĞIR

duzenle_mevcut_ac:
    duzenle_sonu_hizala ÇAĞIR
    <metin_duzenle_baslik X YÜKLE
    >metin_duzenle_baslik Y YÜKLE
    2 SİSTEM

duzenle_satir_dongu:
    ; İstem: "SS> " (SS = 2 haneli hex satır numarası)
    [KAYNAK_SATIR_NO] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    '>' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

    5 SİSTEM
    kabuk_satir_hazirla ÇAĞIR

    ; Boş satır veya "." ise düzenleyiciden çık
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_cikis EŞİTSE ATLA
    '.' KARŞILAŞTIR
    duzenle_nokta_kontrol EŞİTSE ATLA
    duzenle_ozel_komutlar ATLA

duzenle_nokta_kontrol:
    X ARTIR
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_cikis EŞİTSE ATLA

duzenle_ozel_komutlar:
    ; "ÇIK" veya "BİTTİ" -> düzenleyiciden çık
    <kmt_cik X YÜKLE
    >kmt_cik Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    duzenle_cikis EŞİTSE ATLA

    <kmt_bitti X YÜKLE
    >kmt_bitti Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    duzenle_cikis EŞİTSE ATLA

    ; "DERLE" yazılırsa düzenleyiciden çıkıp doğrudan derle!
    <kmt_derle X YÜKLE
    >kmt_derle Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    kabuk_derle_komutu EŞİTSE ATLA

    ; "YENİ" yazılırsa tamponu sıfırla
    <kmt_yeni X YÜKLE
    >kmt_yeni Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    duzenle_ic_yeni EŞİTSE ATLA

    ; "KAYNAK" yazılırsa mevcut tamponu listele
    <kmt_kaynak X YÜKLE
    >kmt_kaynak Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    duzenle_ic_kaynak EŞİTSE ATLA

    ; Tek başına "SİL" yazılırsa son satırı geri sil
    [KABUK_INDEKS] T YÜKLE
    T İT
    <kmt_sil X YÜKLE
    >kmt_sil Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    duzenle_ic_sil_kontrol EŞİTSE ATLA
    T ÇEK
    T [KABUK_INDEKS] SAKLA
    duzenle_satir_ekle ATLA

duzenle_ic_sil_kontrol:
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_ic_sil_yap EŞİTSE ATLA
    T ÇEK
    T [KABUK_INDEKS] SAKLA
    duzenle_satir_ekle ATLA

duzenle_ic_sil_yap:
    T ÇEK
    duzenle_son_satir_sil ÇAĞIR
    duzenle_satir_dongu ATLA

duzenle_ic_yeni:
    duzenle_tampon_sifirla ÇAĞIR
    duzenle_satir_dongu ATLA

duzenle_ic_kaynak:
    kaynak_listele_alt ÇAĞIR
    duzenle_satir_dongu ATLA

duzenle_satir_ekle:
    ; SATIR_TAMPONU[KABUK_INDEKS..] içeriğini [[KAYNAK_SON_ALT]] tamponuna kopyala
    [KABUK_INDEKS] X YÜKLE
duzenle_kopyala_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_kopyala_son EŞİTSE ATLA
    T [[KAYNAK_SON_ALT]] SAKLA
    [KAYNAK_SON_ALT] ARTIR
    duzenle_kopyala_sonraki FARKLIYSA ATLA
    [KAYNAK_SON_UST] ARTIR
duzenle_kopyala_sonraki:
    X ARTIR
    duzenle_kopyala_dongu ATLA

duzenle_kopyala_son:
    ; Satır sonuna '\n' (10) ve ardından '\0' (0) koy
    10 T YÜKLE
    T [[KAYNAK_SON_ALT]] SAKLA
    [KAYNAK_SON_ALT] ARTIR
    duzenle_nl_tamam FARKLIYSA ATLA
    [KAYNAK_SON_UST] ARTIR
duzenle_nl_tamam:
    0 T YÜKLE
    T [[KAYNAK_SON_ALT]] SAKLA
    [KAYNAK_SATIR_NO] ARTIR
    duzenle_satir_dongu ATLA

duzenle_cikis:
    bios_komut_dongusu ATLA

; -----------------------------------------------------------------------------
; duzenle_son_satir_sil:
; KAYNAK_TAMPON içindeki son satırı siler ve KAYNAK_SATIR_NO değerini 1 azaltır.
; -----------------------------------------------------------------------------
duzenle_son_satir_sil:
    ; Tampon zaten 0x6000 başındaysa çık
    [KAYNAK_SON_UST] T YÜKLE
    0x60 KARŞILAŞTIR
    duzenle_sil_geri_basla FARKLIYSA ATLA
    [KAYNAK_SON_ALT] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_sil_cik EŞİTSE ATLA

duzenle_sil_geri_basla:
    ; Önce son '\n' karakterinin üstüne geri gel
    duzenle_ptr_azalt ÇAĞIR

duzenle_sil_geri_dongu:
    [KAYNAK_SON_UST] T YÜKLE
    0x60 KARŞILAŞTIR
    duzenle_sil_kontrol FARKLIYSA ATLA
    [KAYNAK_SON_ALT] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_sil_bitti EŞİTSE ATLA

duzenle_sil_kontrol:
    duzenle_ptr_azalt ÇAĞIR
    [[KAYNAK_SON_ALT]] T YÜKLE
    10 KARŞILAŞTIR
    duzenle_sil_geri_dongu FARKLIYSA ATLA

    ; Bir önceki satırın '\n' karakterini bulduk, 1 ileri git
    [KAYNAK_SON_ALT] ARTIR
    duzenle_sil_bitti FARKLIYSA ATLA
    [KAYNAK_SON_UST] ARTIR

duzenle_sil_bitti:
    0 T YÜKLE
    T [[KAYNAK_SON_ALT]] SAKLA
    [KAYNAK_SATIR_NO] AZALT
duzenle_sil_cik:
    DÖN

duzenle_ptr_azalt:
    [KAYNAK_SON_ALT] T YÜKLE
    0 KARŞILAŞTIR
    duzenle_ptr_ust_azalt EŞİTSE ATLA
    [KAYNAK_SON_ALT] AZALT
    DÖN
duzenle_ptr_ust_azalt:
    [KAYNAK_SON_ALT] AZALT
    [KAYNAK_SON_UST] AZALT
    DÖN

; -----------------------------------------------------------------------------
; kabuk_kaynak_komutu / kaynak_listele_alt:
; KAYNAK_TAMPON (0x6000) içindeki kaynak kodu satır numaralarıyla ekrana basar.
; -----------------------------------------------------------------------------
kabuk_kaynak_komutu:
    kaynak_listele_alt ÇAĞIR
    bios_komut_dongusu ATLA

kaynak_listele_alt:
    0 T YÜKLE
    T [KAYNAK_OKU_ALT] SAKLA
    0x60 T YÜKLE
    T [KAYNAK_OKU_UST] SAKLA
    [[KAYNAK_OKU_ALT]] T YÜKLE
    0 KARŞILAŞTIR
    kaynak_bos_mesaj EŞİTSE ATLA

    1 T YÜKLE
    T [KABUK_SAYAC] SAKLA   ; Satır numarası

kaynak_satir_bas:
    [[KAYNAK_OKU_ALT]] T YÜKLE
    0 KARŞILAŞTIR
    kaynak_listele_cik EŞİTSE ATLA

    [KABUK_SAYAC] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    ':' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM

kaynak_karakter_dongu:
    [[KAYNAK_OKU_ALT]] T YÜKLE
    0 KARŞILAŞTIR
    kaynak_son_alt_satir EŞİTSE ATLA

    [KAYNAK_OKU_ALT] ARTIR
    kaynak_oku_artti FARKLIYSA ATLA
    [KAYNAK_OKU_UST] ARTIR
kaynak_oku_artti:
    10 KARŞILAŞTIR
    kaynak_satir_sonu EŞİTSE ATLA
    1 SİSTEM
    kaynak_karakter_dongu ATLA

kaynak_satir_sonu:
    10 T YÜKLE
    1 SİSTEM
    [KABUK_SAYAC] ARTIR
    kaynak_satir_bas ATLA

kaynak_son_alt_satir:
    10 T YÜKLE
    1 SİSTEM
kaynak_listele_cik:
    DÖN

kaynak_bos_mesaj:
    <metin_kaynak_bos X YÜKLE
    >metin_kaynak_bos Y YÜKLE
    2 SİSTEM
    DÖN

; -----------------------------------------------------------------------------
; kabuk_derle_komutu:
; KAYNAK_TAMPON (0x6000) içindeki Türkçe assembly kaynak kodunu 2 geçişli olarak
; derler.
; Kullanım:
;   DERLE          -> 0x0200 (veya kaynak içindeki .BAŞLANGIÇ) adresine derler
;   0300 DERLE     -> 0x0300 adresine derler
;   PROGRAM DERLE  -> Derler ve otomatik olarak disk.t8'e PROGRAM adıyla kaydeder
; -----------------------------------------------------------------------------
kabuk_derle_komutu:
    0x00 T YÜKLE
    T [DERLE_BAS_ALT] SAKLA
    0x02 T YÜKLE
    T [DERLE_BAS_UST] SAKLA
    0 T YÜKLE
    T [DERLE_KAYDET_VAR] SAKLA

    ; Argüman var mı kontrol et
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_tampon_kontrol EŞİTSE ATLA

    ; Önce hex adres olarak dene
    [KABUK_INDEKS] T YÜKLE
    T İT
    kabuk_hex_adres_oku ÇAĞIR
    1 KARŞILAŞTIR
    derle_arg_adres EŞİTSE ATLA

    ; Hex adres değilse dosya adı olarak oku (derleme sonrası diske kaydetmek için)
    T ÇEK
    T [KABUK_INDEKS] SAKLA
    kabuk_dosya_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    kabuk_adres_hatasi EŞİTSE ATLA
    1 T YÜKLE
    T [DERLE_KAYDET_VAR] SAKLA
    derle_tampon_kontrol ATLA

derle_arg_adres:
    T ÇEK
    [KABUK_ARG_ALT] T YÜKLE
    T [DERLE_BAS_ALT] SAKLA
    [KABUK_ARG_UST] T YÜKLE
    T [DERLE_BAS_UST] SAKLA

derle_tampon_kontrol:
    ; Kaynak tamponu (0x6000) boş mu?
    [KAYNAK_TAMPON] T YÜKLE
    0 KARŞILAŞTIR
    derle_gecis1_basla FARKLIYSA ATLA
    <metin_kaynak_bos X YÜKLE
    >metin_kaynak_bos Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

derle_gecis1_basla:
    ; --- 1. GEÇİŞ: Etiketleri ve sabitleri topla ---
    0 T YÜKLE
    T [ETIKET_SAYISI] SAKLA
    1 T YÜKLE
    T [DERLE_GECIS] SAKLA
    derle_gecis_calistir ÇAĞIR
    0 KARŞILAŞTIR
    derle_hata_cikis EŞİTSE ATLA

    ; --- 2. GEÇİŞ: Makine kodunu ve veriyi belleğe üret ---
    2 T YÜKLE
    T [DERLE_GECIS] SAKLA
    derle_gecis_calistir ÇAĞIR
    0 KARŞILAŞTIR
    derle_hata_cikis EŞİTSE ATLA

    0 T YÜKLE
    T [DERLE_GECIS] SAKLA

    ; Derlenen boyutu hesapla: DERLE_BOYUT = KODLA_PC - DERLE_BAS
    [KODLA_PC_ALT] T YÜKLE
    [DERLE_BAS_ALT] ÇIKAR
    T [DERLE_BOYUT_ALT] SAKLA
    [KODLA_PC_UST] T YÜKLE
    derle_boyut_borc_yok ELDE VARSA ATLA
    [DERLE_BAS_UST] ÇIKAR
    T AZALT
    derle_boyut_sakla ATLA
derle_boyut_borc_yok:
    [DERLE_BAS_UST] ÇIKAR
derle_boyut_sakla:
    T [DERLE_BOYUT_UST] SAKLA

    ; "DERLENDİ: 0xAAAA - 0xBBBB" mesajını yazdır
    <metin_derlendi X YÜKLE
    >metin_derlendi Y YÜKLE
    2 SİSTEM
    [DERLE_BAS_UST] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    [DERLE_BAS_ALT] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    ' ' T YÜKLE
    1 SİSTEM
    '-' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM
    '0' T YÜKLE
    1 SİSTEM
    'x' T YÜKLE
    1 SİSTEM
    [KODLA_PC_UST] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    [KODLA_PC_ALT] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    10 T YÜKLE
    1 SİSTEM

    ; Dosya adı verilmişse (<AD> DERLE) otomatik olarak diske kaydet!
    [DERLE_KAYDET_VAR] T YÜKLE
    0 KARŞILAŞTIR
    bios_komut_dongusu EŞİTSE ATLA

    [DERLE_BAS_ALT] T YÜKLE
    T [KABUK_ARG_ALT] SAKLA
    [DERLE_BAS_UST] T YÜKLE
    T [KABUK_ARG_UST] SAKLA
    [DERLE_BOYUT_ALT] T YÜKLE
    T [KABUK_ARG2_ALT] SAKLA
    [DERLE_BOYUT_UST] T YÜKLE
    T [KABUK_ARG2_UST] SAKLA
    kaydet_basla ATLA

derle_hata_cikis:
    0 T YÜKLE
    T [DERLE_GECIS] SAKLA
    <metin_hata_satir X YÜKLE
    >metin_hata_satir Y YÜKLE
    2 SİSTEM
    [KAYNAK_SATIR_NO] T YÜKLE
    kabuk_hex_bayt_yaz ÇAĞIR
    ':' T YÜKLE
    1 SİSTEM
    ' ' T YÜKLE
    1 SİSTEM
    <metin_hata_sozdizimi X YÜKLE
    >metin_hata_sozdizimi Y YÜKLE
    2 SİSTEM
    bios_komut_dongusu ATLA

; -----------------------------------------------------------------------------
; derle_gecis_calistir:
; KAYNAK_TAMPON (0x6000) başından sonuna kadar satır satır okur ve derler.
; Başarılıysa T = 1, hata varsa T = 0 döner.
; -----------------------------------------------------------------------------
derle_gecis_calistir:
    0 T YÜKLE
    T [KAYNAK_OKU_ALT] SAKLA
    T [DERLE_BAYT_YAZILDI] SAKLA
    0x60 T YÜKLE
    T [KAYNAK_OKU_UST] SAKLA

    [DERLE_BAS_ALT] T YÜKLE
    T [KODLA_PC_ALT] SAKLA
    [DERLE_BAS_UST] T YÜKLE
    T [KODLA_PC_UST] SAKLA

    1 T YÜKLE
    T [KAYNAK_SATIR_NO] SAKLA

derle_gecis_dongu:
    [[KAYNAK_OKU_ALT]] T YÜKLE
    0 KARŞILAŞTIR
    derle_gecis_tamam EŞİTSE ATLA

    ; Bir satırı (yorumları ';' ayıklayarak) SATIR_TAMPONU içine kopyala
    0 X YÜKLE
    0 T YÜKLE
    T [DERLE_TIRNAK_DURUM] SAKLA

derle_satir_kopyala:
    [[KAYNAK_OKU_ALT]] T YÜKLE
    0 KARŞILAŞTIR
    derle_kopya_bitti EŞİTSE ATLA

    [KAYNAK_OKU_ALT] ARTIR
    derle_oku_ilerledi FARKLIYSA ATLA
    [KAYNAK_OKU_UST] ARTIR
derle_oku_ilerledi:
    10 KARŞILAŞTIR
    derle_kopya_bitti EŞİTSE ATLA
    13 KARŞILAŞTIR
    derle_satir_kopyala EŞİTSE ATLA

    ; Tırnak durumu kontrolü (' veya ")
    T [GECICI_KARAKTER] SAKLA
    [DERLE_TIRNAK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    derle_tirnak_disinda EŞİTSE ATLA

    ; Tırnak içindeyiz: kapanış tırnağı mı?
    [GECICI_KARAKTER] KARŞILAŞTIR
    derle_karakter_ekle FARKLIYSA ATLA
    0 T YÜKLE
    T [DERLE_TIRNAK_DURUM] SAKLA
    derle_karakter_ekle ATLA

derle_tirnak_disinda:
    [GECICI_KARAKTER] T YÜKLE
    ';' KARŞILAŞTIR
    derle_yorum_atla EŞİTSE ATLA
    34 KARŞILAŞTIR          ; '"'
    derle_tirnak_ac EŞİTSE ATLA
    39 KARŞILAŞTIR          ; '\''
    derle_tirnak_ac EŞİTSE ATLA
    derle_karakter_ekle ATLA

derle_tirnak_ac:
    T [DERLE_TIRNAK_DURUM] SAKLA

derle_karakter_ekle:
    [GECICI_KARAKTER] T YÜKLE
    62 X KARŞILAŞTIR
    derle_satir_kopyala BÜYÜK VEYA EŞİTSE ATLA
    T [SATIR_TAMPONU + X] SAKLA
    X ARTIR
    derle_satir_kopyala ATLA

derle_yorum_atla:
    ; Satır sonuna ('\n' veya 0) kadar kaynak işaretçisini ilerlet
    [[KAYNAK_OKU_ALT]] T YÜKLE
    0 KARŞILAŞTIR
    derle_kopya_bitti EŞİTSE ATLA
    [KAYNAK_OKU_ALT] ARTIR
    derle_yorum_artti FARKLIYSA ATLA
    [KAYNAK_OKU_UST] ARTIR
derle_yorum_artti:
    10 KARŞILAŞTIR
    derle_yorum_atla FARKLIYSA ATLA

derle_kopya_bitti:
    0 T YÜKLE
    T [SATIR_TAMPONU + X] SAKLA

    ; Satırı normalize et ve baştaki boşlukları geç
    kabuk_satir_hazirla ÇAĞIR

    ; Satır boşsa sıradaki satıra geç
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_sonraki_satir EŞİTSE ATLA

    derle_satir_isle ÇAĞIR
    0 KARŞILAŞTIR
    derle_gecis_hata EŞİTSE ATLA

derle_sonraki_satir:
    [KAYNAK_SATIR_NO] ARTIR
    derle_gecis_dongu ATLA

derle_gecis_tamam:
    1 T YÜKLE
    DÖN

derle_gecis_hata:
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; derle_satir_isle:
; SATIR_TAMPONU[KABUK_INDEKS..] içindeki tek bir kaynak satırını (etiket,
; sözde komut veya makine komutu) işler.
; -----------------------------------------------------------------------------
derle_satir_isle:
    ; 1) Satır başında "ETİKET:" tanımı var mı kontrol et
    [KABUK_INDEKS] T YÜKLE
    T [KABUK_SON_KELIME] SAKLA
    T X AKTAR
    derle_etiket_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    derle_etiket_degil EŞİTSE ATLA

    [SATIR_TAMPONU + X] T YÜKLE
    ':' KARŞILAŞTIR
    derle_etiket_degil FARKLIYSA ATLA

    ; ':' karakterini geç ve KABUK_INDEKS'i güncelle
    X ARTIR
    X [KABUK_INDEKS] SAKLA
    kabuk_bosluk_atla ÇAĞIR

    ; 1. geçişteysek etiketi KODLA_PC adresiyle tabloya kaydet
    [DERLE_GECIS] T YÜKLE
    1 KARŞILAŞTIR
    derle_etiket_devam FARKLIYSA ATLA

    [KODLA_PC_ALT] T YÜKLE
    T [KODLA_DEGER_ALT] SAKLA
    [KODLA_PC_UST] T YÜKLE
    T [KODLA_DEGER_UST] SAKLA
    derle_etiket_kaydet ÇAĞIR
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA

derle_etiket_devam:
    ; Etiketten sonra satır bitti mi?
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_satir_tamam EŞİTSE ATLA
    derle_komut_veya_direktif ATLA

derle_etiket_degil:
    [KABUK_SON_KELIME] T YÜKLE
    T [KABUK_INDEKS] SAKLA

derle_komut_veya_direktif:
    ; 2) '.' ile başlayan sözde komut (direktif) mu?
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    '.' KARŞILAŞTIR
    derle_makine_komutu FARKLIYSA ATLA

    ; .BAŞLANGIÇ <adres>
    <drk_baslangic X YÜKLE
    >drk_baslangic Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    derle_drk_baslangic EŞİTSE ATLA

    ; .TANIM <ad> <değer>
    <drk_tanim X YÜKLE
    >drk_tanim Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    derle_drk_tanim EŞİTSE ATLA

    ; .METİN "..."
    <drk_metin X YÜKLE
    >drk_metin Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    derle_drk_metin EŞİTSE ATLA

    ; .BAYT <değer> [, <değer> ...]
    <drk_bayt X YÜKLE
    >drk_bayt Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    derle_drk_bayt EŞİTSE ATLA

    ; .KELİME <değer> [, <değer> ...]
    <drk_kelime X YÜKLE
    >drk_kelime Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    derle_drk_kelime EŞİTSE ATLA

    ; .BOŞLUK <boyut>
    <drk_bosluk X YÜKLE
    >drk_bosluk Y YÜKLE
    kabuk_komut_eslesir_mi ÇAĞIR
    1 KARŞILAŞTIR
    derle_drk_bosluk EŞİTSE ATLA

    derle_satir_hata ATLA

derle_drk_baslangic:
    [KABUK_INDEKS] X YÜKLE
    kodla_sayi_coz ÇAĞIR
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    [KODLA_DEGER_ALT] T YÜKLE
    T [KODLA_PC_ALT] SAKLA
    [KODLA_DEGER_UST] T YÜKLE
    T [KODLA_PC_UST] SAKLA
    ; Henüz bayt üretilmediyse DERLE_BAS adresini de güncelle
    [DERLE_BAYT_YAZILDI] T YÜKLE
    0 KARŞILAŞTIR
    derle_satir_tamam FARKLIYSA ATLA
    [KODLA_DEGER_ALT] T YÜKLE
    T [DERLE_BAS_ALT] SAKLA
    [KODLA_DEGER_UST] T YÜKLE
    T [DERLE_BAS_UST] SAKLA
    derle_satir_tamam ATLA

derle_drk_tanim:
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    derle_etiket_adi_oku ÇAĞIR
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    kodla_sayi_coz ÇAĞIR
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    [DERLE_GECIS] T YÜKLE
    1 KARŞILAŞTIR
    derle_satir_tamam FARKLIYSA ATLA
    derle_etiket_kaydet ÇAĞIR
    DÖN

derle_drk_metin:
    1 T YÜKLE
    T [DERLE_BAYT_YAZILDI] SAKLA
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE
    [SATIR_TAMPONU + X] T YÜKLE
    34 KARŞILAŞTIR          ; '"'
    derle_satir_hata FARKLIYSA ATLA
    X ARTIR
derle_metin_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    34 KARŞILAŞTIR          ; '"'
    derle_satir_tamam EŞİTSE ATLA
    92 KARŞILAŞTIR          ; '\\' kaçış karakteri mi?
    derle_metin_kacis EŞİTSE ATLA
    kodla_bayt_yaz ÇAĞIR
    X ARTIR
    derle_metin_dongu ATLA
derle_metin_kacis:
    X ARTIR
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    'n' KARŞILAŞTIR
    derle_metin_nl EŞİTSE ATLA
    'N' KARŞILAŞTIR
    derle_metin_nl EŞİTSE ATLA
    kodla_bayt_yaz ÇAĞIR
    X ARTIR
    derle_metin_dongu ATLA
derle_metin_nl:
    10 T YÜKLE
    kodla_bayt_yaz ÇAĞIR
    X ARTIR
    derle_metin_dongu ATLA

derle_drk_bayt:
    1 T YÜKLE
    T [DERLE_BAYT_YAZILDI] SAKLA
    [KABUK_INDEKS] X YÜKLE
derle_bayt_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_satir_tamam EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    derle_bayt_gec EŞİTSE ATLA
    ',' KARŞILAŞTIR
    derle_bayt_gec EŞİTSE ATLA
    34 KARŞILAŞTIR          ; '"'
    derle_bayt_metin EŞİTSE ATLA

    kodla_sayi_coz ÇAĞIR
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    [KODLA_DEGER_ALT] T YÜKLE
    kodla_bayt_yaz ÇAĞIR
    derle_bayt_dongu ATLA

derle_bayt_metin:
    X ARTIR
derle_bayt_metin_ic:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    34 KARŞILAŞTIR
    derle_bayt_gec EŞİTSE ATLA
    kodla_bayt_yaz ÇAĞIR
    X ARTIR
    derle_bayt_metin_ic ATLA

derle_bayt_gec:
    X ARTIR
    derle_bayt_dongu ATLA

derle_drk_kelime:
    1 T YÜKLE
    T [DERLE_BAYT_YAZILDI] SAKLA
    [KABUK_INDEKS] X YÜKLE
derle_kelime_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    derle_satir_tamam EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    derle_kelime_gec EŞİTSE ATLA
    ',' KARŞILAŞTIR
    derle_kelime_gec EŞİTSE ATLA

    kodla_sayi_coz ÇAĞIR
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    [KODLA_DEGER_ALT] T YÜKLE
    kodla_bayt_yaz ÇAĞIR
    [KODLA_DEGER_UST] T YÜKLE
    kodla_bayt_yaz ÇAĞIR
    derle_kelime_dongu ATLA

derle_kelime_gec:
    X ARTIR
    derle_kelime_dongu ATLA

derle_drk_bosluk:
    1 T YÜKLE
    T [DERLE_BAYT_YAZILDI] SAKLA
    [KABUK_INDEKS] X YÜKLE
    kodla_sayi_coz ÇAĞIR
    0 KARŞILAŞTIR
    derle_satir_hata EŞİTSE ATLA
    [KODLA_DEGER_ALT] Y YÜKLE
    0 Y KARŞILAŞTIR
    derle_satir_tamam EŞİTSE ATLA
derle_bosluk_yaz:
    0 T YÜKLE
    kodla_bayt_yaz ÇAĞIR
    Y AZALT
    derle_bosluk_yaz FARKLIYSA ATLA
    derle_satir_tamam ATLA

derle_makine_komutu:
    1 T YÜKLE
    T [DERLE_BAYT_YAZILDI] SAKLA
    kodla_tek_satir_derle ÇAĞIR
    DÖN

derle_satir_tamam:
    1 T YÜKLE
    DÖN

derle_satir_hata:
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; derle_etiket_adi_oku:
; SATIR_TAMPONU + X konumundan geçerli bir sembol adını ('A'..'Z', '_', '0'..'9')
; ETIKET_AD_TAMPON (0x0070..0x007D, azami 13 karakter + 0) içine okur.
; Başarılıysa T = 1 (X sembol sonundaki karaktere ilerler), değilse T = 0 döner.
; -----------------------------------------------------------------------------
derle_etiket_adi_oku:
    Y İT
    ; İlk karakter 'A'..'Z' veya '_' olmalı
    [SATIR_TAMPONU + X] T YÜKLE
    '_' KARŞILAŞTIR
    etiket_ad_basla EŞİTSE ATLA
    'A' KARŞILAŞTIR
    etiket_ad_hata KÜÇÜKSE ATLA
    '[' KARŞILAŞTIR
    etiket_ad_hata BÜYÜK VEYA EŞİTSE ATLA

etiket_ad_basla:
    0 Y YÜKLE
etiket_ad_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    '_' KARŞILAŞTIR
    etiket_ad_kabul EŞİTSE ATLA
    '0' KARŞILAŞTIR
    etiket_ad_son KÜÇÜKSE ATLA
    ':' KARŞILAŞTIR
    etiket_ad_kabul KÜÇÜKSE ATLA
    'A' KARŞILAŞTIR
    etiket_ad_son KÜÇÜKSE ATLA
    '[' KARŞILAŞTIR
    etiket_ad_son BÜYÜK VEYA EŞİTSE ATLA

etiket_ad_kabul:
    13 Y KARŞILAŞTIR
    etiket_ad_uzun BÜYÜK VEYA EŞİTSE ATLA
    T [ETIKET_AD_TAMPON + Y] SAKLA
    Y ARTIR
etiket_ad_uzun:
    X ARTIR
    etiket_ad_dongu ATLA

etiket_ad_son:
    0 Y KARŞILAŞTIR
    etiket_ad_hata EŞİTSE ATLA
    0 T YÜKLE
    T [ETIKET_AD_TAMPON + Y] SAKLA
    Y ÇEK
    1 T YÜKLE
    DÖN

etiket_ad_hata:
    Y ÇEK
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; derle_etiket_kaydet:
; ETIKET_AD_TAMPON içindeki sembolü ve KODLA_DEGER_ALT/UST değerini
; ETIKET_TABLOSU (0x7800, 64 giriş x 16 bayt) içine kaydeder.
; -----------------------------------------------------------------------------
derle_etiket_kaydet:
    X İT
    Y İT

    ; Zaten kayıtlıysa mevcut girişin üzerine yaz
    derle_etiket_bul ÇAĞIR
    1 KARŞILAŞTIR
    etiket_deger_yaz EŞİTSE ATLA

    [ETIKET_SAYISI] T YÜKLE
    64 KARŞILAŞTIR
    etiket_kaydet_dolu BÜYÜK VEYA EŞİTSE ATLA

    ; Giriş adresi = 0x7800 + ETIKET_SAYISI * 16
    T [ETIKET_PTR_ALT] SAKLA
    0 T YÜKLE
    T [ETIKET_PTR_UST] SAKLA
    4 Y YÜKLE
etiket_carp_16:
    [ETIKET_PTR_ALT] T YÜKLE
    T SOLA KAYDIR
    T [ETIKET_PTR_ALT] SAKLA
    [ETIKET_PTR_UST] T YÜKLE
    T SOLA DÖNDÜR
    T [ETIKET_PTR_UST] SAKLA
    Y AZALT
    etiket_carp_16 FARKLIYSA ATLA

    [ETIKET_PTR_UST] T YÜKLE
    0x78 TOPLA
    T [ETIKET_PTR_UST] SAKLA

    ; 14 baytlık ismi kopyala
    0 Y YÜKLE
etiket_isim_yaz:
    [ETIKET_AD_TAMPON + Y] T YÜKLE
    T [[ETIKET_PTR_ALT] + Y] SAKLA
    Y ARTIR
    14 Y KARŞILAŞTIR
    etiket_isim_yaz FARKLIYSA ATLA

    [ETIKET_SAYISI] ARTIR

etiket_deger_yaz:
    14 Y YÜKLE
    [KODLA_DEGER_ALT] T YÜKLE
    T [[ETIKET_PTR_ALT] + Y] SAKLA
    15 Y YÜKLE
    [KODLA_DEGER_UST] T YÜKLE
    T [[ETIKET_PTR_ALT] + Y] SAKLA

    Y ÇEK
    X ÇEK
    1 T YÜKLE
    DÖN

etiket_kaydet_dolu:
    Y ÇEK
    X ÇEK
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; derle_etiket_bul:
; ETIKET_TABLOSU (0x7800) içinde ETIKET_AD_TAMPON sembolünü arar.
; Bulursa KODLA_DEGER_ALT/UST içine değerini yükler ve T = 1 döner;
; bulamazsa T = 0 döner. X ve Y yazmaçlarını korur.
; -----------------------------------------------------------------------------
derle_etiket_bul:
    X İT
    Y İT

    0 T YÜKLE
    T [ETIKET_PTR_ALT] SAKLA
    0x78 T YÜKLE
    T [ETIKET_PTR_UST] SAKLA
    0 X YÜKLE               ; X = kontrol edilen giriş indeksi

etiket_ara_dongu:
    [ETIKET_SAYISI] T YÜKLE
    T [KABUK_HEX_GECICI] SAKLA
    X T AKTAR
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    etiket_bulunamadi BÜYÜK VEYA EŞİTSE ATLA

    0 Y YÜKLE
etiket_harf_kiyas:
    [ETIKET_AD_TAMPON + Y] T YÜKLE
    T [KABUK_HEX_GECICI] SAKLA
    [[ETIKET_PTR_ALT] + Y] T YÜKLE
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    etiket_sonraki_giris FARKLIYSA ATLA

    0 KARŞILAŞTIR
    etiket_eslesti EŞİTSE ATLA
    Y ARTIR
    14 Y KARŞILAŞTIR
    etiket_harf_kiyas FARKLIYSA ATLA

etiket_eslesti:
    14 Y YÜKLE
    [[ETIKET_PTR_ALT] + Y] T YÜKLE
    T [KODLA_DEGER_ALT] SAKLA
    15 Y YÜKLE
    [[ETIKET_PTR_ALT] + Y] T YÜKLE
    T [KODLA_DEGER_UST] SAKLA
    Y ÇEK
    X ÇEK
    1 T YÜKLE
    DÖN

etiket_sonraki_giris:
    [ETIKET_PTR_ALT] T YÜKLE
    16 TOPLA
    T [ETIKET_PTR_ALT] SAKLA
    etiket_ptr_tamam ELDE YOKSA ATLA
    [ETIKET_PTR_UST] ARTIR
etiket_ptr_tamam:
    X ARTIR
    etiket_ara_dongu ATLA

etiket_bulunamadi:
    Y ÇEK
    X ÇEK
    0 T YÜKLE
    DÖN

; --- Kabuk Yardımcı Alt Programları ---

; -----------------------------------------------------------------------------
; kabuk_satir_hazirla:
; SATIR_TAMPONU içindeki küçük harfleri ve Türkçe karakterleri (ISO-8859-9)
; büyük ASCII karşılıklarına (C, G, I, O, S, U) çevirir ve baştaki boşlukları atlar.
; Tek tırnak ('...') veya çift tırnak ("...") içindeki karakterlere dokunmaz.
; -----------------------------------------------------------------------------
kabuk_satir_hazirla:
    0 X YÜKLE
    0 Y YÜKLE               ; Y = tırnak durumu (0 = dışarıda, 39 = ' içinde, 34 = " içinde)
satir_norm_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    satir_norm_bitti EŞİTSE ATLA

    ; Tırnak içinde miyiz?
    0 Y KARŞILAŞTIR
    satir_tirnak_disi EŞİTSE ATLA

    ; Tırnak kapanışı mı?
    Y T AKTAR
    T [KABUK_HEX_GECICI] SAKLA
    [SATIR_TAMPONU + X] T YÜKLE
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    satir_norm_ilerle FARKLIYSA ATLA
    0 Y YÜKLE
    satir_norm_ilerle ATLA

satir_tirnak_disi:
    39 KARŞILAŞTIR          ; '\''
    satir_tek_tirnak_ac EŞİTSE ATLA
    34 KARŞILAŞTIR          ; '"'
    satir_cift_tirnak_ac EŞİTSE ATLA

    ; Küçük ASCII 'a'..'z' (97..122) -> 'A'..'Z'
    'a' KARŞILAŞTIR
    satir_tr_kontrol KÜÇÜKSE ATLA
    123 KARŞILAŞTIR
    satir_tr_kontrol BÜYÜK VEYA EŞİTSE ATLA
    32 ÇIKAR
    satir_norm_yaz ATLA

satir_tek_tirnak_ac:
    39 Y YÜKLE
    satir_norm_ilerle ATLA

satir_cift_tirnak_ac:
    34 Y YÜKLE
    satir_norm_ilerle ATLA

satir_tr_kontrol:
    ; Ç (0xC7) / ç (0xE7) -> 'C'
    0xC7 KARŞILAŞTIR
    tr_c_yap EŞİTSE ATLA
    0xE7 KARŞILAŞTIR
    tr_c_yap EŞİTSE ATLA

    ; Ğ (0xD0) / ğ (0xF0) -> 'G'
    0xD0 KARŞILAŞTIR
    tr_g_yap EŞİTSE ATLA
    0xF0 KARŞILAŞTIR
    tr_g_yap EŞİTSE ATLA

    ; İ (0xDD) / ı (0xFD) -> 'I'
    0xDD KARŞILAŞTIR
    tr_i_yap EŞİTSE ATLA
    0xFD KARŞILAŞTIR
    tr_i_yap EŞİTSE ATLA

    ; Ö (0xD6) / ö (0xF6) -> 'O'
    0xD6 KARŞILAŞTIR
    tr_o_yap EŞİTSE ATLA
    0xF6 KARŞILAŞTIR
    tr_o_yap EŞİTSE ATLA

    ; Ş (0xDE) / ş (0xFE) -> 'S'
    0xDE KARŞILAŞTIR
    tr_s_yap EŞİTSE ATLA
    0xFE KARŞILAŞTIR
    tr_s_yap EŞİTSE ATLA

    ; Ü (0xDC) / ü (0xFC) -> 'U'
    0xDC KARŞILAŞTIR
    tr_u_yap EŞİTSE ATLA
    0xFC KARŞILAŞTIR
    tr_u_yap EŞİTSE ATLA
    satir_norm_ilerle ATLA

tr_c_yap:
    'C' T YÜKLE
    satir_norm_yaz ATLA
tr_g_yap:
    'G' T YÜKLE
    satir_norm_yaz ATLA
tr_i_yap:
    'I' T YÜKLE
    satir_norm_yaz ATLA
tr_o_yap:
    'O' T YÜKLE
    satir_norm_yaz ATLA
tr_s_yap:
    'S' T YÜKLE
    satir_norm_yaz ATLA
tr_u_yap:
    'U' T YÜKLE

satir_norm_yaz:
    T [SATIR_TAMPONU + X] SAKLA
satir_norm_ilerle:
    X ARTIR
    satir_norm_dongu ATLA

satir_norm_bitti:
    0 T YÜKLE
    T [KABUK_INDEKS] SAKLA
    kabuk_bosluk_atla ÇAĞIR
    DÖN

; -----------------------------------------------------------------------------
; kabuk_bosluk_atla:
; KABUK_INDEKS konumundan itibaren boşluk (' ') karakterlerini geçer.
; -----------------------------------------------------------------------------
kabuk_bosluk_atla:
    [KABUK_INDEKS] X YÜKLE
bosluk_atla_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    bosluk_atla_bitti FARKLIYSA ATLA
    X ARTIR
    bosluk_atla_dongu ATLA
bosluk_atla_bitti:
    X [KABUK_INDEKS] SAKLA
    DÖN

; -----------------------------------------------------------------------------
; kabuk_komut_eslesir_mi:
; Girdi: X = şablon alt baytı, Y = şablon üst baytı
; Hem doğal Türkçe sonda yüklem (örn. "PONG ÇALIŞTIR", "0200 BELLEK")
; hem de önde komut ("ÇALIŞTIR PONG", "BELLEK 0200") düzenini destekler:
;   1) Önce SATIR_TAMPONU[KABUK_INDEKS..] başlangıcında şablonu arar.
;      Eşleşirse KABUK_INDEKS argümanın başına ilerletilir ve T = 1 döner.
;   2) Başta eşleşmezse satırdaki SON kelimeyi kontrol eder.
;      Son kelime şablonla eşleşirse son kelimeden önceki boşluğu '\0' yaparak
;      argümanları satır başında bırakır, KABUK_INDEKS'i korur ve T = 1 döner.
;   3) Hiçbiri eşleşmezse T = 0 döner.
; -----------------------------------------------------------------------------
kabuk_komut_eslesir_mi:
    X [KABUK_SABLON_ALT] SAKLA
    Y [KABUK_SABLON_UST] SAKLA
    [KABUK_INDEKS] X YÜKLE
    0 Y YÜKLE

komut_esles_dongu:
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    komut_sablon_sonu EŞİTSE ATLA

    ; Şablon karakterini geçici sakla ve tampondaki karakterle kıyasla
    T [KABUK_HEX_GECICI] SAKLA
    [SATIR_TAMPONU + X] T YÜKLE
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    komut_sonda_dene FARKLIYSA ATLA

    X ARTIR
    Y ARTIR
    komut_esles_dongu ATLA

komut_sablon_sonu:
    ; Komut kelimesi bitti; tampondaki sıradaki bayt 0 veya ' ' olmalı
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    komut_eslesti EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    komut_eslesti EŞİTSE ATLA

komut_sonda_dene:
    ; Satırın sonundaki boşlukları temizle ve son kelimenin başını bul
    [KABUK_INDEKS] X YÜKLE
sonda_sona_git:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    sonda_bosluk_budama EŞİTSE ATLA
    X ARTIR
    sonda_sona_git ATLA

sonda_bosluk_budama:
    [KABUK_INDEKS] T YÜKLE
    T [KABUK_HEX_GECICI] SAKLA
    X T AKTAR
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    komut_eslesmedi EŞİTSE ATLA
    X AZALT
    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    sonda_bosluk_koy EŞİTSE ATLA
    X ARTIR
    sonda_kelime_basi_bul ATLA

sonda_bosluk_koy:
    0 T YÜKLE
    T [SATIR_TAMPONU + X] SAKLA
    sonda_bosluk_budama ATLA

sonda_kelime_basi_bul:
    ; X şu an son kelimenin bitişindeki '\0' konumunda; geriye doğru ' ' ara
    X AZALT
    [KABUK_INDEKS] T YÜKLE
    T [KABUK_HEX_GECICI] SAKLA
    X T AKTAR
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    komut_eslesmedi EŞİTSE ATLA     ; Boşluk yoksa tek kelimedir ve başta zaten eşleşmedi

    [SATIR_TAMPONU + X] T YÜKLE
    ' ' KARŞILAŞTIR
    sonda_kelime_basi_bul FARKLIYSA ATLA

    ; X şu an son kelimeden hemen önceki boşlukta; X+1 son kelimenin başı
    X ARTIR
    X [KABUK_SON_KELIME] SAKLA
    0 Y YÜKLE

sonda_kiyas_dongu:
    [[KABUK_SABLON_ALT] + Y] T YÜKLE
    0 KARŞILAŞTIR
    sonda_sablon_sonu EŞİTSE ATLA

    T [KABUK_HEX_GECICI] SAKLA
    [SATIR_TAMPONU + X] T YÜKLE
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    komut_eslesmedi FARKLIYSA ATLA

    X ARTIR
    Y ARTIR
    sonda_kiyas_dongu ATLA

sonda_sablon_sonu:
    ; Son kelime tam olarak bitti mi?
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    komut_eslesmedi FARKLIYSA ATLA

    ; Eşleşti! Son kelimeden önceki boşluğu '\0' yap ki argümanlar orada bitsin
    [KABUK_SON_KELIME] X YÜKLE
    X AZALT
    0 T YÜKLE
    T [SATIR_TAMPONU + X] SAKLA
    1 T YÜKLE
    DÖN

komut_eslesmedi:
    0 T YÜKLE
    DÖN

komut_eslesti:
    X [KABUK_INDEKS] SAKLA
    1 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; kabuk_hex_adres_oku:
; KABUK_INDEKS konumundan itibaren onaltılık (isteğe bağlı 0X veya $ önekli)
; adresi okur, KABUK_ARG_ALT ve KABUK_ARG_UST içine yazar.
; Başarılıysa T = 1, geçersiz karakter varsa T = 0 döner.
; -----------------------------------------------------------------------------
kabuk_hex_adres_oku:
    kabuk_bosluk_atla ÇAĞIR
    [KABUK_INDEKS] X YÜKLE

    ; '$' öneki var mı?
    [SATIR_TAMPONU + X] T YÜKLE
    '$' KARŞILAŞTIR
    hex_dolar_atla EŞİTSE ATLA

    ; '0X' öneki var mı?
    '0' KARŞILAŞTIR
    hex_basla FARKLIYSA ATLA
    X ARTIR
    [SATIR_TAMPONU + X] T YÜKLE
    'X' KARŞILAŞTIR
    hex_ifade_gecerli_kontrol EŞİTSE ATLA
    X AZALT
    hex_basla ATLA

hex_dolar_atla:
    X ARTIR
    hex_ifade_gecerli_kontrol ATLA

hex_ifade_gecerli_kontrol:
    X ARTIR

hex_basla:
    0 T YÜKLE
    T [KABUK_ARG_ALT] SAKLA
    T [KABUK_ARG_UST] SAKLA
    T [KABUK_SUTUN] SAKLA   ; Okunan hane sayısı

hex_okuma_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    hex_okuma_sonu EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    hex_okuma_sonu EŞİTSE ATLA

    ; '0'..'9' arası mı?
    '0' KARŞILAŞTIR
    hex_hatali KÜÇÜKSE ATLA
    ':' KARŞILAŞTIR         ; ':' = '9' + 1
    hex_rakam_bulundu KÜÇÜKSE ATLA

    ; 'A'..'F' arası mı?
    'A' KARŞILAŞTIR
    hex_hatali KÜÇÜKSE ATLA
    'G' KARŞILAŞTIR         ; 'G' = 'F' + 1
    hex_hatali BÜYÜK VEYA EŞİTSE ATLA
    'A' ÇIKAR
    10 TOPLA
    hex_hane_ekle ATLA

hex_rakam_bulundu:
    '0' ÇIKAR

hex_hane_ekle:
    T [KABUK_HEX_GECICI] SAKLA

    ; 16-bit değeri 4 bit sola kaydır (KABUK_ARG << 4)
    4 Y YÜKLE
hex_kaydir_4:
    [KABUK_ARG_ALT] T YÜKLE
    T SOLA KAYDIR
    T [KABUK_ARG_ALT] SAKLA
    [KABUK_ARG_UST] T YÜKLE
    T SOLA DÖNDÜR
    T [KABUK_ARG_UST] SAKLA
    Y AZALT
    hex_kaydir_4 FARKLIYSA ATLA

    ; Yeni haneyi alt bayta ekle
    [KABUK_ARG_ALT] T YÜKLE
    [KABUK_HEX_GECICI] VEYA
    T [KABUK_ARG_ALT] SAKLA

    [KABUK_SUTUN] ARTIR
    X ARTIR
    hex_okuma_dongu ATLA

hex_okuma_sonu:
    [KABUK_SUTUN] T YÜKLE
    0 KARŞILAŞTIR
    hex_hatali EŞİTSE ATLA
    X [KABUK_INDEKS] SAKLA
    1 T YÜKLE
    DÖN

hex_hatali:
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; kabuk_hex_bayt_yaz:
; Girdi: T = 2 haneli onaltılık olarak ekrana yazdırılacak bayt (ör. 0xA5 -> "A5")
; -----------------------------------------------------------------------------
kabuk_hex_bayt_yaz:
    T İT
    ; Üst 4 bit (nibble)
    T SAĞA KAYDIR
    T SAĞA KAYDIR
    T SAĞA KAYDIR
    T SAĞA KAYDIR
    kabuk_hex_hane_yaz ÇAĞIR

    ; Alt 4 bit (nibble)
    T ÇEK
    0x0F VE
    kabuk_hex_hane_yaz ÇAĞIR
    DÖN

kabuk_hex_hane_yaz:
    10 KARŞILAŞTIR
    hex_hane_rakam KÜÇÜKSE ATLA
    10 ÇIKAR
    'A' TOPLA
    1 SİSTEM
    DÖN
hex_hane_rakam:
    '0' TOPLA
    1 SİSTEM
    DÖN

; -----------------------------------------------------------------------------
; kabuk_dosya_adi_oku:
; KABUK_INDEKS konumundan itibaren boşluğa veya satır sonuna kadar olan dosya
; adını (1..8 karakter) okur, DOSYA_AD_TAMPON (0x00C0..0x00C7) içine sağdan
; boşluk (' ') dolgulu olarak yazar.
; Başarılıysa T = 1, boş veya 8 karakterden uzunsa T = 0 döner.
; -----------------------------------------------------------------------------
kabuk_dosya_adi_oku:
    kabuk_bosluk_atla ÇAĞIR

    ; Önce 8 baytlık dosya adı tamponunu boşluk (' ') ile doldur
    ' ' T YÜKLE
    0 Y YÜKLE
dosya_ad_temizle:
    T [DOSYA_AD_TAMPON + Y] SAKLA
    Y ARTIR
    8 Y KARŞILAŞTIR
    dosya_ad_temizle FARKLIYSA ATLA

    [KABUK_INDEKS] X YÜKLE
    0 Y YÜKLE
dosya_ad_dongu:
    [SATIR_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    dosya_ad_bitti EŞİTSE ATLA
    ' ' KARŞILAŞTIR
    dosya_ad_bitti EŞİTSE ATLA

    8 Y KARŞILAŞTIR
    dosya_ad_hatali BÜYÜK VEYA EŞİTSE ATLA

    T [DOSYA_AD_TAMPON + Y] SAKLA
    X ARTIR
    Y ARTIR
    dosya_ad_dongu ATLA

dosya_ad_bitti:
    0 Y KARŞILAŞTIR
    dosya_ad_hatali EŞİTSE ATLA
    X [KABUK_INDEKS] SAKLA
    1 T YÜKLE
    DÖN

dosya_ad_hatali:
    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; kabuk_dizin_sektoru_oku / kabuk_dizin_sektoru_yaz:
; Diskin 0. sektörünü (dizin tablosu) DIZIN_TAMPONU (0x7F00) adresine okur/yazar.
; Başarılıysa T = 1, hata varsa ekrana mesaj basıp T = 0 döner.
; -----------------------------------------------------------------------------
kabuk_dizin_sektoru_oku:
    0 T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    T [PORT_DISK_ADR_ALT] SAKLA
    0x7F T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    1 T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    T [PORT_DISK_KOMUT] SAKLA   ; 1 = OKU
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    dizin_islem_tamam EŞİTSE ATLA
    <metin_hata_disk X YÜKLE
    >metin_hata_disk Y YÜKLE
    2 SİSTEM
    0 T YÜKLE
    DÖN

kabuk_dizin_sektoru_yaz:
    0 T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA
    T [PORT_DISK_ADR_ALT] SAKLA
    0x7F T YÜKLE
    T [PORT_DISK_ADR_UST] SAKLA
    1 T YÜKLE
    T [PORT_DISK_SAYI] SAKLA
    2 T YÜKLE
    T [PORT_DISK_KOMUT] SAKLA   ; 2 = YAZ
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    dizin_islem_tamam EŞİTSE ATLA
    <metin_hata_disk X YÜKLE
    >metin_hata_disk Y YÜKLE
    2 SİSTEM
    0 T YÜKLE
    DÖN

dizin_islem_tamam:
    1 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; kabuk_dizinde_dosya_ara:
; DIZIN_TAMPONU içindeki 16 girişi tarayarak DOSYA_AD_TAMPON ile eşleşen
; dosyayı arar. Bulursa KABUK_DIZIN_OFSET = giriş ofseti (0..240) ve T = 1 döner.
; Bulamazsa T = 0 döner.
; -----------------------------------------------------------------------------
kabuk_dizinde_dosya_ara:
    0 T YÜKLE
    T [KABUK_DIZIN_OFSET] SAKLA

dizin_ara_dongu:
    [KABUK_DIZIN_OFSET] X YÜKLE
    [DIZIN_TAMPONU + X] T YÜKLE
    0 KARŞILAŞTIR
    dizin_ara_sonraki EŞİTSE ATLA
    0xE5 KARŞILAŞTIR
    dizin_ara_sonraki EŞİTSE ATLA

    ; 8 baytlık dosya adını karşılaştır
    0 Y YÜKLE
dizin_isim_kiyas:
    [DOSYA_AD_TAMPON + Y] T YÜKLE
    T [KABUK_HEX_GECICI] SAKLA
    [DIZIN_TAMPONU + X] T YÜKLE
    [KABUK_HEX_GECICI] KARŞILAŞTIR
    dizin_ara_sonraki FARKLIYSA ATLA
    X ARTIR
    Y ARTIR
    8 Y KARŞILAŞTIR
    dizin_isim_kiyas FARKLIYSA ATLA

    ; Eşleşti!
    1 T YÜKLE
    DÖN

dizin_ara_sonraki:
    [KABUK_DIZIN_OFSET] T YÜKLE
    16 TOPLA
    T [KABUK_DIZIN_OFSET] SAKLA
    0 KARŞILAŞTIR
    dizin_ara_dongu FARKLIYSA ATLA

    0 T YÜKLE
    DÖN

; -----------------------------------------------------------------------------
; kabuk_diskten_dosya_yukle:
; DOSYA_AD_TAMPON içindeki dosyayı dizinde bulur ve hedef RAM adresine yükler.
; Başarılıysa KABUK_ARG_ALT/UST = yükleme adresi olur ve T = 1 döner.
; Başarısızsa hata mesajını basar ve T = 0 döner.
; -----------------------------------------------------------------------------
kabuk_diskten_dosya_yukle:
    kabuk_dizin_sektoru_oku ÇAĞIR
    0 KARŞILAŞTIR
    dosya_yukle_basarisiz EŞİTSE ATLA

    kabuk_dizinde_dosya_ara ÇAĞIR
    0 KARŞILAŞTIR
    dosya_yukle_bulunamadi EŞİTSE ATLA

    ; Girişten başlangıç sektörü (ofset+8), sektör sayısı (ofset+9),
    ; yükleme adresi (ofset+10, ofset+11) bilgilerini al
    [KABUK_DIZIN_OFSET] T YÜKLE
    8 TOPLA
    T X AKTAR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [PORT_DISK_SEKTOR] SAKLA

    X ARTIR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [PORT_DISK_SAYI] SAKLA

    X ARTIR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [KABUK_ARG_ALT] SAKLA
    T [PORT_DISK_ADR_ALT] SAKLA

    X ARTIR
    [DIZIN_TAMPONU + X] T YÜKLE
    T [KABUK_ARG_UST] SAKLA
    T [PORT_DISK_ADR_UST] SAKLA

    1 T YÜKLE
    T [PORT_DISK_KOMUT] SAKLA   ; 1 = OKU
    [PORT_DISK_DURUM] T YÜKLE
    0 KARŞILAŞTIR
    dosya_yukle_disk_hata FARKLIYSA ATLA

    1 T YÜKLE
    DÖN

dosya_yukle_bulunamadi:
    <metin_hata_dosya_yok X YÜKLE
    >metin_hata_dosya_yok Y YÜKLE
    2 SİSTEM
dosya_yukle_basarisiz:
    0 T YÜKLE
    DÖN

dosya_yukle_disk_hata:
    <metin_hata_disk X YÜKLE
    >metin_hata_disk Y YÜKLE
    2 SİSTEM
    0 T YÜKLE
    DÖN

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
; İmleç VRAM adresini (0x8000 + satir * 40 + sutun) tablodan hızlıca hesaplar.
; IMLEC_ADRES_ALT ve IMLEC_ADRES_UST güncellenir. T ve X yazmaçlarını korur.
; -----------------------------------------------------------------------------
imlec_adresi_hesapla:
    T İT
    X İT

    [IMLEC_SATIR] T YÜKLE
    T SOLA KAYDIR
    T X AKTAR

    [vram_satir_tablosu + X] T YÜKLE
    [IMLEC_SUTUN] TOPLA
    T [IMLEC_ADRES_ALT] SAKLA

    X ARTIR
    [vram_satir_tablosu + X] T YÜKLE
    0 ELDEYLE TOPLA
    T [IMLEC_ADRES_UST] SAKLA

    X ÇEK
    T ÇEK
    DÖN

vram_satir_tablosu:
    .KELİME 0x8000, 0x8028, 0x8050, 0x8078, 0x80A0
    .KELİME 0x80C8, 0x80F0, 0x8118, 0x8140, 0x8168
    .KELİME 0x8190, 0x81B8, 0x81E0, 0x8208, 0x8230
    .KELİME 0x8258, 0x8280, 0x82A8, 0x82D0, 0x82F8
    .KELİME 0x8320, 0x8348, 0x8370, 0x8398, 0x83C0

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

; Normalize edilmiş (büyük ASCII) komut şablonları
kmt_yardim:
    .METİN "YARDIM"
    .BAYT 0
kmt_temizle:
    .METİN "TEMIZLE"
    .BAYT 0
kmt_bilgi:
    .METİN "BILGI"
    .BAYT 0
kmt_sure:
    .METİN "SURE"
    .BAYT 0
kmt_bellek:
    .METİN "BELLEK"
    .BAYT 0
kmt_calistir:
    .METİN "CALISTIR"
    .BAYT 0
kmt_liste:
    .METİN "LISTE"
    .BAYT 0
kmt_yukle:
    .METİN "YUKLE"
    .BAYT 0
kmt_kaydet:
    .METİN "KAYDET"
    .BAYT 0
kmt_sil:
    .METİN "SIL"
    .BAYT 0
kmt_kodla:
    .METİN "KODLA"
    .BAYT 0
kmt_duzenle:
    .METİN "DUZENLE"
    .BAYT 0
kmt_kaynak:
    .METİN "KAYNAK"
    .BAYT 0
kmt_derle:
    .METİN "DERLE"
    .BAYT 0
kmt_yeni:
    .METİN "YENI"
    .BAYT 0
kmt_cik:
    .METİN "CIK"
    .BAYT 0
kmt_bitti:
    .METİN "BITTI"
    .BAYT 0

; Sözde komut (direktif) şablonları
drk_baslangic:
    .METİN ".BASLANGIC"
    .BAYT 0
drk_tanim:
    .METİN ".TANIM"
    .BAYT 0
drk_metin:
    .METİN ".METIN"
    .BAYT 0
drk_bayt:
    .METİN ".BAYT"
    .BAYT 0
drk_kelime:
    .METİN ".KELIME"
    .BAYT 0
drk_bosluk:
    .METİN ".BOSLUK"
    .BAYT 0

metin_yardim:
    .METİN "KOMUTLAR:\n"
    .METİN " YARDIM         KOMUT LİSTESİ\n"
    .METİN " TEMİZLE        EKRANI SİLER\n"
    .METİN " BİLGİ          SİSTEM ÖZETİ\n"
    .METİN " [ADR] BELLEK   32 BAYT DÖKÜM\n"
    .METİN " [ADR] KODLA    SATIR ASSEMBLER\n"
    .METİN " DÜZENLE        KAYNAK DÜZENLE\n"
    .METİN " KAYNAK         KAYNAĞI LİSTELE\n"
    .METİN " [AD] DERLE     KAYNAĞI DERLE\n"
    .METİN " ADR: B1 B2..   BELLEĞE YAZ\n"
    .METİN " <AD> ÇALIŞTIR  PROGRAMI AÇAR\n"
    .METİN " LİSTE          DİSK DİZİNİ\n"
    .METİN " <AD> YÜKLE     BELLEĞE YÜKLE\n"
    .METİN " <AD> KAYDET    DİSKE KAYDET\n"
    .METİN " <AD> SİL       DİSKTEN SİL\n"
    .METİN " SÜRE           ÇALIŞMA SÜRESİ\n"
    .BAYT 0

metin_bilgi:
    .METİN "İŞLEMCİ : TÜRK-8 (8-BİT, 91 KOMUT)\n"
    .METİN "RAM     : 31 KB (0x0200-0x7FFF)\n"
    .METİN "EKRAN   : 40x25 METİN (0x8000)\n"
    .METİN "BIOS ROM: 16 KB (0xC000-0xFFFF)\n"
    .BAYT 0

metin_sure_baslik:
    .METİN "SÜRE: "
    .BAYT 0

metin_sure_son:
    .METİN " KARE (50 HZ)\n"
    .BAYT 0

metin_liste_baslik:
    .METİN "DOSYA    ADRES   BOYUT\n"
    .BAYT 0

metin_sektor_eki:
    .METİN " SEKTÖR\n"
    .BAYT 0

metin_disk_bos:
    .METİN " (DİSK BOŞ)\n"
    .BAYT 0

metin_yuklendi:
    .METİN "YÜKLENDİ: 0x"
    .BAYT 0

metin_kaydedildi:
    .METİN "DİSKE KAYDEDİLDİ.\n"
    .BAYT 0

metin_silindi:
    .METİN "DOSYA SİLİNDİ.\n"
    .BAYT 0

metin_bilinmeyen:
    .METİN "BİLİNMEYEN KOMUT! (YARDIM YAZIN)\n"
    .BAYT 0

metin_hata_adres:
    .METİN "GEÇERSİZ ADRES!\n"
    .BAYT 0

metin_hata_dosya_adi:
    .METİN "GEÇERSİZ DOSYA ADI!\n"
    .BAYT 0

metin_hata_dosya_yok:
    .METİN "DOSYA BULUNAMADI!\n"
    .BAYT 0

metin_hata_disk_dolu:
    .METİN "DİSK DİZİNİ DOLU!\n"
    .BAYT 0

metin_hata_disk:
    .METİN "DİSK HATASI!\n"
    .BAYT 0

metin_kodla_baslik:
    .METİN "SATIR ASSEMBLER (ÇIKIŞ: BOŞ SATIR)\n"
    .BAYT 0

metin_duzenle_baslik:
    .METİN "KAYNAK DÜZENLEYİCİ (ÇIKIŞ: BOŞ SATIR)\n"
    .BAYT 0

metin_kaynak_bos:
    .METİN "(KAYNAK TAMPONU BOŞ)\n"
    .BAYT 0

metin_derlendi:
    .METİN "DERLENDİ: 0x"
    .BAYT 0

metin_hata_satir:
    .METİN "SATIR "
    .BAYT 0

metin_hata_sozdizimi:
    .METİN "SÖZ DİZİMİ HATASI!\n"
    .BAYT 0

; -----------------------------------------------------------------------------
; kodla_komut_tablosu:
; Tüm 91 ISA v1.0 komutu + takma adlar.
; Biçim: opkod (1B), işlenen_tipi (0=yok, 1=8-bit, 2=16-bit), "DESEN", 0
; Tablo sonu: 0xFF
; -----------------------------------------------------------------------------
kodla_komut_tablosu:
    .BAYT 0x00, 0, "BOS", 0
    .BAYT 0x01, 0, "DUR", 0
    .BAYT 0x02, 0, "KESME AC", 0
    .BAYT 0x03, 0, "KESME KAPAT", 0
    .BAYT 0x04, 0, "SIFIRLA", 0
    .BAYT 0x05, 1, "# SISTEM", 0
    .BAYT 0x06, 0, "KARE BEKLE", 0
    .BAYT 0x07, 0, "RASTGELE", 0
    .BAYT 0x10, 1, "# T YUKLE", 0
    .BAYT 0x11, 2, "[#] T YUKLE", 0
    .BAYT 0x12, 2, "[# + X] T YUKLE", 0
    .BAYT 0x13, 1, "# X YUKLE", 0
    .BAYT 0x14, 1, "# Y YUKLE", 0
    .BAYT 0x15, 2, "T [#] SAKLA", 0
    .BAYT 0x16, 2, "T [# + X] SAKLA", 0
    .BAYT 0x17, 2, "X [#] SAKLA", 0
    .BAYT 0x18, 2, "Y [#] SAKLA", 0
    .BAYT 0x19, 0, "X T AKTAR", 0
    .BAYT 0x1A, 0, "T X AKTAR", 0
    .BAYT 0x1B, 0, "Y T AKTAR", 0
    .BAYT 0x1C, 0, "T Y AKTAR", 0
    .BAYT 0x1D, 2, "[[#]] T YUKLE", 0
    .BAYT 0x1E, 2, "T [[#]] SAKLA", 0
    .BAYT 0x20, 2, "[#] X YUKLE", 0
    .BAYT 0x21, 2, "[#] Y YUKLE", 0
    .BAYT 0x22, 2, "[# + Y] T YUKLE", 0
    .BAYT 0x23, 2, "T [# + Y] SAKLA", 0
    .BAYT 0x24, 2, "[[#] + Y] T YUKLE", 0
    .BAYT 0x25, 2, "T [[#] + Y] SAKLA", 0
    .BAYT 0x26, 0, "YG T AKTAR", 0
    .BAYT 0x27, 0, "T YG AKTAR", 0
    .BAYT 0x28, 0, "KOPYALA", 0
    .BAYT 0x29, 0, "DOLDUR", 0
    .BAYT 0x30, 1, "# TOPLA", 0
    .BAYT 0x31, 2, "[#] TOPLA", 0
    .BAYT 0x32, 1, "# ELDEYLE TOPLA", 0
    .BAYT 0x33, 1, "# CIKAR", 0
    .BAYT 0x34, 2, "[#] CIKAR", 0
    .BAYT 0x35, 0, "T ARTIR", 0
    .BAYT 0x36, 0, "X ARTIR", 0
    .BAYT 0x37, 0, "Y ARTIR", 0
    .BAYT 0x38, 0, "T AZALT", 0
    .BAYT 0x39, 0, "X AZALT", 0
    .BAYT 0x3A, 0, "Y AZALT", 0
    .BAYT 0x3B, 1, "# KARSILASTIR", 0
    .BAYT 0x3C, 1, "# X KARSILASTIR", 0
    .BAYT 0x3D, 1, "# Y KARSILASTIR", 0
    .BAYT 0x3E, 2, "[#] KARSILASTIR", 0
    .BAYT 0x3F, 1, "# BORCLA CIKAR", 0
    .BAYT 0x40, 0, "ELDE KUR", 0
    .BAYT 0x41, 0, "ELDE TEMIZLE", 0
    .BAYT 0x42, 2, "[#] ARTIR", 0
    .BAYT 0x43, 2, "[#] AZALT", 0
    .BAYT 0x44, 0, "T RAKAMLARA AYIR", 0
    .BAYT 0x50, 1, "# VE", 0
    .BAYT 0x51, 1, "# VEYA", 0
    .BAYT 0x52, 1, "# OZELVEYA", 0
    .BAYT 0x53, 0, "T DEGILLE", 0
    .BAYT 0x54, 0, "T SOLA KAYDIR", 0
    .BAYT 0x55, 0, "T SAGA KAYDIR", 0
    .BAYT 0x56, 0, "T SOLA DONDUR", 0
    .BAYT 0x57, 0, "T SAGA DONDUR", 0
    .BAYT 0x58, 1, "# BIT SINA", 0
    .BAYT 0x59, 2, "[#] VE", 0
    .BAYT 0x5A, 2, "[#] VEYA", 0
    .BAYT 0x70, 2, "# ATLA", 0
    .BAYT 0x71, 2, "# ESITSE ATLA", 0
    .BAYT 0x72, 2, "# FARKLIYSA ATLA", 0
    .BAYT 0x73, 2, "# BUYUKSE ATLA", 0
    .BAYT 0x74, 2, "# KUCUKSE ATLA", 0
    .BAYT 0x75, 2, "# ELDE VARSA ATLA", 0
    .BAYT 0x76, 2, "# ELDE YOKSA ATLA", 0
    .BAYT 0x77, 2, "# NEGATIFSE ATLA", 0
    .BAYT 0x78, 2, "# POZITIFSE ATLA", 0
    .BAYT 0x79, 2, "# TASMA VARSA ATLA", 0
    .BAYT 0x7A, 2, "# KUCUK VEYA ESITSE ATLA", 0
    .BAYT 0x7B, 2, "[#] ATLA", 0
    .BAYT 0x7C, 2, "[#] CAGIR", 0
    .BAYT 0x90, 2, "# CAGIR", 0
    .BAYT 0x91, 0, "DON", 0
    .BAYT 0x92, 0, "KESMEDEN DON", 0
    .BAYT 0x93, 0, "T IT", 0
    .BAYT 0x94, 0, "T CEK", 0
    .BAYT 0x95, 0, "DURUM IT", 0
    .BAYT 0x96, 0, "DURUM CEK", 0
    .BAYT 0x97, 0, "X IT", 0
    .BAYT 0x98, 0, "X CEK", 0
    .BAYT 0x99, 0, "Y IT", 0
    .BAYT 0x9A, 0, "Y CEK", 0
    .BAYT 0xB0, 1, "# GIRIS", 0
    .BAYT 0xB1, 1, "# CIKIS", 0
    .BAYT 0x75, 2, "# BUYUK VEYA ESITSE ATLA", 0
    .BAYT 0xFF

; =============================================================================
; 7. İŞLEMCİ VEKTÖR TABLOSU (0xFFFA - 0xFFFF)
; =============================================================================
.BAŞLANGIÇ 0xFFFA
    .KELİME bios_sistem_giris   ; 0xFFFA: VEKTOR_SISTEM (<n> SİSTEM)
    .KELİME bios_sifirla        ; 0xFFFC: VEKTOR_SIFIRLA (Reset / Açılış)
    .KELİME bios_kesme_giris    ; 0xFFFE: VEKTOR_KESME (Donanım IRQ)
