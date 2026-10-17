; ==============================================================
; TÜRK-8: 1'den 10'a kadar sayıların toplamı (1+2+...+10 = 55)
; ==============================================================

.BAŞLANGIÇ 0x0200

ana_program:
    0 T YÜKLE             ; Toplaç (T) = 0
    10 X YÜKLE            ; Sayaç (X) = 10

dongu:
    X T AKTAR             ; X'i Toplaca koy
    [toplam_sonuc] TOPLA  ; T = T + önceki toplam
    T [toplam_sonuc] SAKLA; Yeni toplamı belleğe sakla

    X AZALT               ; X'i 1 azalt
    0 X KARŞILAŞTIR       ; X sıfır oldu mu?
    dongu FARKLIYSA ATLA  ; Sıfır değilse döngüye ATLA

bitti:
    [toplam_sonuc] T YÜKLE; Sonucu doğrulamak için T'ye yükle (55 = 0x37)
    DUR

toplam_sonuc:
    .BAYT 0

