; ==============================================================
; TÜRK-8 RETRO PING PONG (PONG) OYUNU
; Kontroller: W (Yukarı), S (Aşağı), ESC (Çıkış)
; ==============================================================

.BAŞLANGIÇ 0x0200

oyun_baslangic:
    ; 1. Ekranı temizle (tüm VRAM'e boşluk yaz)
    0 X YÜKLE
ekran_temizle_dongu:
    32 T YÜKLE
    T [0x8000 + X] SAKLA
    T [0x8100 + X] SAKLA
    T [0x8200 + X] SAKLA
    T [0x8300 + X] SAKLA
    X ARTIR
    0 X KARŞILAŞTIR
    ekran_temizle_dongu FARKLIYSA ATLA

    ; 2. Başlık ve Skor Tabelasını Yaz (Satır 0: 0x8000)
    0 X YÜKLE
baslik_yaz_dongu:
    [baslik_metni + X] T YÜKLE
    0 KARŞILAŞTIR
    baslik_bitti EŞİTSE ATLA
    T [0x8000 + X] SAKLA
    X ARTIR
    baslik_yaz_dongu ATLA

baslik_bitti:
    ; 3. Üst ve Alt Duvarları Çiz (Satır 2: 0x8050, Satır 23: 0x8398)
    0 X YÜKLE
duvar_ciz_dongu:
    45 T YÜKLE ; '-' karakteri
    T [0x8050 + X] SAKLA ; Üst sınır
    T [0x8398 + X] SAKLA ; Alt sınır
    X ARTIR
    39 X KARŞILAŞTIR
    duvar_ciz_dongu FARKLIYSA ATLA

    ; 4. Sağ Duvarı Çiz (Her satırın 38. sütununa '|')
    3 X YÜKLE
sag_duvar_dongu:
    X T AKTAR
    [satir_adresleri_alt + X] T YÜKLE
    T [cizim_adresi_alt] SAKLA
    [satir_adresleri_ust + X] T YÜKLE
    T [cizim_adresi_ust] SAKLA

    ; 38. sütunu ekle (sayfa sınırını aşarsa üst bayta elde ekle)
    38 T YÜKLE
    [cizim_adresi_alt] TOPLA
    T [cizim_adresi_alt] SAKLA
    [cizim_adresi_ust] T YÜKLE
    0 ELDEYLE TOPLA
    T [cizim_adresi_ust] SAKLA

    124 T YÜKLE ; '|' karakteri
    T [[cizim_adresi_alt]] SAKLA

    X ARTIR
    23 X KARŞILAŞTIR
    sag_duvar_dongu FARKLIYSA ATLA

    ; 5. Raketi Çiz
    raket_ciz ÇAĞIR

    ; 6. Skoru Çiz
    skor_guncelle ÇAĞIR

; ==============================================================
; ANA OYUN DÖNGÜSÜ
; ==============================================================
ana_oyun_dongusu:
    ; --- KLAVYE KONTROLÜ ---
    [0xA001] T YÜKLE ; PORT_KLAVYE_DURUM
    1 KARŞILAŞTIR
    tus_isleme EŞİTSE ATLA
    klavye_bitti ATLA

tus_isleme:
    [0xA000] T YÜKLE ; PORT_KLAVYE_VERI

    ; 'w' (119) veya 'W' (87) basıldı mı?
    119 KARŞILAŞTIR
    yukari_hareket EŞİTSE ATLA
    87 KARŞILAŞTIR
    yukari_hareket EŞİTSE ATLA

    ; 's' (115) veya 'S' (83) basıldı mı?
    115 KARŞILAŞTIR
    asagi_hareket EŞİTSE ATLA
    83 KARŞILAŞTIR
    asagi_hareket EŞİTSE ATLA

    klavye_bitti ATLA

yukari_hareket:
    [raket_y] T YÜKLE
    3 KARŞILAŞTIR
    klavye_bitti EŞİTSE ATLA ; Üst duvara çarptıysa gitme

    raket_sil ÇAĞIR
    [raket_y] T YÜKLE
    1 ÇIKAR
    T [raket_y] SAKLA
    raket_ciz ÇAĞIR
    klavye_bitti ATLA

asagi_hareket:
    [raket_y] T YÜKLE
    19 KARŞILAŞTIR
    klavye_bitti EŞİTSE ATLA ; Alt sınıra çarptıysa gitme

    raket_sil ÇAĞIR
    [raket_y] T YÜKLE
    1 TOPLA
    T [raket_y] SAKLA
    raket_ciz ÇAĞIR
    klavye_bitti ATLA

klavye_bitti:
    ; --- DONANIM ZAMANLAYICISI (50 Hz / 20ms) SENKRONU ---
    ; İşlemciyi bir sonraki 50 Hz kareye kadar uyut (%100 CPU kullanımını önler)
    KARE BEKLE

    [kare_sayaci] ARTIR
    [kare_sayaci] T YÜKLE
    6 KARŞILAŞTIR ; 6 kare = 120ms (Saniyede ~8 adım, tam nostaljik Pong hızı!)
    ana_oyun_dongusu KÜÇÜKSE ATLA

    ; 6 kare doldu! Sayacı sıfırla ve topu 1 adım yürüt
    0 T YÜKLE
    T [kare_sayaci] SAKLA

    ; --- TOPU HAREKET ETTİR ---
    ; 1. Eski topu sil
    32 T YÜKLE ; Boşluk
    T [top_karakteri] SAKLA
    top_ciz ÇAĞIR

    ; 2. X konumunu güncelle
    [top_hiz_x] T YÜKLE
    1 KARŞILAŞTIR
    saga_git EŞİTSE ATLA

sola_git:
    [top_x] T YÜKLE
    1 ÇIKAR
    T [top_x] SAKLA
    y_guncelle ATLA

saga_git:
    [top_x] T YÜKLE
    1 TOPLA
    T [top_x] SAKLA

y_guncelle:
    ; 3. Y konumunu güncelle
    [top_hiz_y] T YÜKLE
    1 KARŞILAŞTIR
    asagi_git EŞİTSE ATLA

yukari_git:
    [top_y] T YÜKLE
    1 ÇIKAR
    T [top_y] SAKLA
    carpisma_testi ATLA

asagi_git:
    [top_y] T YÜKLE
    1 TOPLA
    T [top_y] SAKLA

; --- ÇARPIŞMA KONTROLLERİ ---
carpisma_testi:
    ; Üst duvar (y <= 3)
    [top_y] T YÜKLE
    3 KARŞILAŞTIR
    ustten_sek EŞİTSE ATLA
    alt_duvar_testi ATLA

ustten_sek:
    1 T YÜKLE
    T [top_hiz_y] SAKLA ; Aşağı doğru yönel
    alt_duvar_testi ATLA

alt_duvar_testi:
    ; Alt duvar (y >= 22)
    [top_y] T YÜKLE
    22 KARŞILAŞTIR
    alttan_sek EŞİTSE ATLA
    sag_duvar_testi ATLA

alttan_sek:
    0 T YÜKLE
    T [top_hiz_y] SAKLA ; Yukarı doğru yönel

sag_duvar_testi:
    ; Sağ duvar (x >= 37)
    [top_x] T YÜKLE
    37 KARŞILAŞTIR
    sagdan_sek EŞİTSE ATLA
    raket_testi ATLA

sagdan_sek:
    0 T YÜKLE
    T [top_hiz_x] SAKLA ; Sola doğru yönel

raket_testi:
    ; Top raket sütununa (x == 3) geldi mi?
    [top_x] T YÜKLE
    3 KARŞILAŞTIR
    raketle_carpisma EŞİTSE ATLA

    ; Top kaçtı mı (x <= 1)?
    [top_x] T YÜKLE
    1 KARŞILAŞTIR
    top_kacti EŞİTSE ATLA
    cizim_adimi ATLA

raketle_carpisma:
    ; Top raketin boyu içinde mi? (top_y >= raket_y ve top_y <= raket_y + 3)
    [top_y] T YÜKLE
    [raket_y] ÇIKAR
    ; Eğer fark 0, 1, 2 veya 3 ise çarptı!
    0 KARŞILAŞTIR
    raketten_sek EŞİTSE ATLA
    1 KARŞILAŞTIR
    raketten_sek EŞİTSE ATLA
    2 KARŞILAŞTIR
    raketten_sek EŞİTSE ATLA
    3 KARŞILAŞTIR
    raketten_sek EŞİTSE ATLA
    cizim_adimi ATLA ; Rakete çarpmadı

raketten_sek:
    1 T YÜKLE
    T [top_hiz_x] SAKLA ; Sağa sek

    ; Raket vuruş sesi çal (Port 4: Frekans, Port 5: Süre)
    120 T YÜKLE
    4 ÇIKIŞ
    2 T YÜKLE
    5 ÇIKIŞ

    ; Skoru 1 artır
    [skor] ARTIR
    skor_guncelle ÇAĞIR
    cizim_adimi ATLA

top_kacti:
    ; Top kaçtı, sıfırla
    20 T YÜKLE
    T [top_x] SAKLA
    12 T YÜKLE
    T [top_y] SAKLA
    1 T YÜKLE
    T [top_hiz_x] SAKLA
    0 T YÜKLE
    T [skor] SAKLA
    skor_guncelle ÇAĞIR

cizim_adimi:
    ; Yeni topu çiz
    79 T YÜKLE ; 'O' harfi
    T [top_karakteri] SAKLA
    top_ciz ÇAĞIR

    ana_oyun_dongusu ATLA

; ==============================================================
; YARDIMCI FONKSİYONLAR (ALT PROGRAMLAR)
; ==============================================================

; Topu ekrana basan fonksiyon
top_ciz:
    [top_y] T YÜKLE
    T X AKTAR
    [satir_adresleri_alt + X] T YÜKLE
    T [cizim_adresi_alt] SAKLA
    [satir_adresleri_ust + X] T YÜKLE
    T [cizim_adresi_ust] SAKLA

    ; top_x'i adrese ekle (sayfa sınırını aşarsa üst bayta elde ekle)
    [top_x] T YÜKLE
    [cizim_adresi_alt] TOPLA
    T [cizim_adresi_alt] SAKLA
    [cizim_adresi_ust] T YÜKLE
    0 ELDEYLE TOPLA
    T [cizim_adresi_ust] SAKLA

    [top_karakteri] T YÜKLE
    T [[cizim_adresi_alt]] SAKLA
    DÖN

; Raketi ekrana çizen fonksiyon ('|' karakteri ile 4 birim)
raket_ciz:
    124 T YÜKLE ; '|'
    T [raket_karakteri] SAKLA
    raket_bas ÇAĞIR
    DÖN

raket_sil:
    32 T YÜKLE ; ' '
    T [raket_karakteri] SAKLA
    raket_bas ÇAĞIR
    DÖN

raket_bas:
    0 T YÜKLE
    T [raket_ofset] SAKLA
raket_parca_dongu:
    [raket_y] T YÜKLE
    [raket_ofset] TOPLA
    T X AKTAR

    [satir_adresleri_alt + X] T YÜKLE
    T [cizim_adresi_alt] SAKLA
    [satir_adresleri_ust + X] T YÜKLE
    T [cizim_adresi_ust] SAKLA

    ; 2. sütuna çiz (sayfa sınırını aşarsa üst bayta elde ekle)
    2 T YÜKLE
    [cizim_adresi_alt] TOPLA
    T [cizim_adresi_alt] SAKLA
    [cizim_adresi_ust] T YÜKLE
    0 ELDEYLE TOPLA
    T [cizim_adresi_ust] SAKLA

    [raket_karakteri] T YÜKLE
    T [[cizim_adresi_alt]] SAKLA

    [raket_ofset] T YÜKLE
    T ARTIR
    T [raket_ofset] SAKLA
    4 KARŞILAŞTIR
    raket_parca_dongu FARKLIYSA ATLA
    DÖN

; Skor tabelasını güncelleyen fonksiyon
skor_guncelle:
    [skor] T YÜKLE
    T RAKAMLARA AYIR
    X [0x8019] SAKLA ; Skor onlar basamağı adresi
    T [0x801A] SAKLA ; Skor birler basamağı adresi
    DÖN

; ==============================================================
; DEĞİŞKENLER VE SABİT TABLOLAR
; ==============================================================

raket_y:
    .BAYT 10
raket_karakteri:
    .BAYT 124
raket_ofset:
    .BAYT 0

top_x:
    .BAYT 20
top_y:
    .BAYT 12
top_hiz_x:
    .BAYT 1 ; 1: Sağa, 0: Sola
top_hiz_y:
    .BAYT 1 ; 1: Aşağı, 0: Yukarı
top_karakteri:
    .BAYT 79 ; 'O'
son_zaman:
    .BAYT 0
kare_sayaci:
    .BAYT 0

skor:
    .BAYT 0
gecici_skor:
    .BAYT 0

cizim_adresi_alt:
    .BAYT 0
cizim_adresi_ust:
    .BAYT 0

baslik_metni:
    .METİN "== TURK-8 PONG ==  SKOR: 00  (W/S: Oyna)"
    .BAYT 0

; 25 Satırın 16-Bit VRAM Başlangıç Adresleri Tablosu
satir_adresleri_alt:
    .BAYT 0x00, 0x28, 0x50, 0x78, 0xA0, 0xC8, 0xF0, 0x18
    .BAYT 0x40, 0x68, 0x90, 0xB8, 0xE0, 0x08, 0x30, 0x58
    .BAYT 0x80, 0xA8, 0xD0, 0xF8, 0x20, 0x48, 0x70, 0x98, 0xC0

satir_adresleri_ust:
    .BAYT 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x81
    .BAYT 0x81, 0x81, 0x81, 0x81, 0x81, 0x82, 0x82, 0x82
    .BAYT 0x82, 0x82, 0x82, 0x82, 0x83, 0x83, 0x83, 0x83, 0x83
