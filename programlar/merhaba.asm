; ==============================================================
; TÜRK-8 İlk Örnek Programı: Merhaba Dünya ve VRAM Ekranı
; Söz Dizimi: Özne/Nesne -> Yüklem Sonda (Doğal Türkçe)
; ==============================================================

.BAŞLANGIÇ 0x0200

ana_program:
    0 X YÜKLE                  ; 0'ı X indeksine YÜKLE (X = 0)

dongu:
    [mesaj + X] T YÜKLE        ; mesajın X. harfini Toplaca YÜKLE
    0 KARŞILAŞTIR              ; Metin sonu mu (0)?
    bitti EŞİTSE ATLA          ; Eşitse 'bitti' etiketine ATLA

    ; Hem VRAM CRT ekranına hem de Terminal Portuna gönder
    T [0x8000 + X] SAKLA       ; VRAM ekran adresine yaz
    3 ÇIKIŞ                    ; Port 0x03'e (Terminal Çıktısı) bas

    X ARTIR                    ; X'i 1 ARTIR
    dongu ATLA                 ; dongu etiketine ATLA

bitti:
    10 T YÜKLE                 ; Yeni satır karakteri (ASCII 10: \n)
    3 ÇIKIŞ
    DUR                        ; İşlemciyi DURDUR

mesaj:
    .METİN "MERHABA DUNYA! TURK-8 CALISIYOR."
    .BAYT 0

