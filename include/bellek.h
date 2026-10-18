#ifndef BELLEK_H
#define BELLEK_H

#include "turk8_tanimlar.h"

/* 64 KB Bellek Yapısı */
typedef struct {
    bayt_t  veri[BELLEK_BOYUTU];
    bool    rom_yazma_korumali; /* 0xC000 - 0xFFFF arasını korur */

    /* MMIO Donanım Durumları */
    bayt_t  klavye_tamponu;
    bool    klavye_hazir;
    bayt_t  zamanlayici_sayaci;

    /* Test modu: program PORT_TEST_SONUC'a yazınca dolar */
    bool    test_sonuc_var;
    bayt_t  test_sonuc;
} bellek_t;

/* Bellek Yönetim Fonksiyonları */
void     bellek_olustur(bellek_t *bellek);
void     bellek_sifirla(bellek_t *bellek);

bayt_t   bellek_oku(bellek_t *bellek, kelime_t adres);
void     bellek_yaz(bellek_t *bellek, kelime_t adres, bayt_t deger);

kelime_t bellek_oku_kelime(bellek_t *bellek, kelime_t adres);
void     bellek_yaz_kelime(bellek_t *bellek, kelime_t adres, kelime_t deger);

/* Yardımcılar */
bool     bellek_yukle_ikili(bellek_t *bellek, kelime_t baslangic_adresi, const char *dosya_yolu);
void     bellek_klavye_tusu_gonder(bellek_t *bellek, bayt_t tus);
void     bellek_dokum_yazdir(const bellek_t *bellek, kelime_t baslangic, kelime_t uzunluk);

#endif /* BELLEK_H */

