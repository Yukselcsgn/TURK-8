; ==============================================================
; TÜRK-8 İnteraktif Canlı Ekran ve Klavye Kabuğu (v1.0)
; ==============================================================

.BAŞLANGIÇ 0x0200

ana_program:
    ; 1. Karşılama başlığını ekrana yaz
    0 X YÜKLE
baslik_yaz:
    [baslik + X] T YÜKLE
    0 KARŞILAŞTIR
    baslik_bitti EŞİTSE ATLA
    T [0x8000 + X] SAKLA
    X ARTIR
    baslik_yaz ATLA

baslik_bitti:
    ; 2. Alt bilgi çizgisini yaz
    0 X YÜKLE
cizgi_yaz:
    [cizgi + X] T YÜKLE
    0 KARŞILAŞTIR
    cizgi_bitti EŞİTSE ATLA
    T [0x8028 + X] SAKLA
    X ARTIR
    cizgi_yaz ATLA

cizgi_bitti:
    ; 3. İmleç başlangıç konumu: Satır 3 başı (ofset = 80)
    80 X YÜKLE

klavye_dongusu:
    ; İmleci ekranda '_' (ASCII 95) olarak göster
    95 T YÜKLE
    T [0x8000 + X] SAKLA

    ; Klavyede yeni tuş var mı? (PORT_KLAVYE_DURUM: 0xA001)
    [0xA001] T YÜKLE
    1 KARŞILAŞTIR
    tus_geldi EŞİTSE ATLA

    ; Tuş henüz yoksa döngüye devam et
    klavye_dongusu ATLA

tus_geldi:
    ; Tuşu oku (PORT_KLAVYE_VERI: 0xA000)
    [0xA000] T YÜKLE

    ; Enter tuşu mu? (ASCII 10: \n)
    10 KARŞILAŞTIR
    enter_basildi EŞİTSE ATLA

    ; Backspace / Geri Al tuşu mu? (ASCII 127 veya 8)
    127 KARŞILAŞTIR
    sil_basildi EŞİTSE ATLA
    8 KARŞILAŞTIR
    sil_basildi EŞİTSE ATLA

    ; Normal yazdırılabilir karakter: Karakteri ekrana yaz
    T [0x8000 + X] SAKLA
    X ARTIR
    klavye_dongusu ATLA

enter_basildi:
    ; Eski imleç yerine boşluk koy
    32 T YÜKLE
    T [0x8000 + X] SAKLA
    ; Yeni satıra geç (X = X + 40)
    X T AKTAR
    40 TOPLA
    T X AKTAR
    klavye_dongusu ATLA

sil_basildi:
    ; Şu anki imleci boşluk yap
    32 T YÜKLE
    T [0x8000 + X] SAKLA
    ; 80'den geriye gitmeyi engelle
    80 X KARŞILAŞTIR
    klavye_dongusu EŞİTSE ATLA
    X AZALT
    32 T YÜKLE
    T [0x8000 + X] SAKLA
    klavye_dongusu ATLA

baslik:
    .METİN "=== TURK-8 CANLI KABUK (KLAVYE AKTIF) ==="
    .BAYT 0

cizgi:
    .METİN "Yazi yazabilirsiniz (Cikis icin ESC)   "
    .BAYT 0

