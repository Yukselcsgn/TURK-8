#ifndef BELLEK_H
#define BELLEK_H

#include "turk8_tanimlar.h"

/* 64 KB Bellek ve MMIO Donanım Yapısı */
typedef struct {
    bayt_t   veri[BELLEK_BOYUTU];
    bool     rom_yazma_korumali; /* 0xC000 - 0xFFFF arasını korur */

    /* 16 Baytlık Klavye FIFO Tamponu */
    bayt_t   klavye_fifo[KLAVYE_FIFO_BOYUTU];
    uint8_t  klavye_bas;
    uint8_t  klavye_son;
    uint8_t  klavye_sayi;
    bool     klavye_tasti;       /* 16 bayt doluyken yeni tuş geldiyse true olur */
    bayt_t   klavye_tamponu;     /* Geriye dönük uyumluluk: sıradaki tuş */
    bool     klavye_hazir;       /* klavye_sayi > 0 ise true */

    /* 50 Hz Zamanlayıcı, Ses ve Rastgele Sayı Donanımı */
    bayt_t   zamanlayici_sayaci;
    bayt_t   ses_frekans;
    bayt_t   ses_sure;
    uint32_t ses_calma_sayisi;   /* Tetiklenen toplam ses sayısı */
    bool     sessiz_mod;         /* Test kipinde terminal zilini (\a) bastırır */
    uint16_t donanim_rng;        /* MMIO PORT_RASTGELE için 16-bit LFSR durumu */

    /* Sanal Disk Denetleyici Yazmaçları (0xA010 - 0xA017) */
    bayt_t   disk_komut;
    bayt_t   disk_durum;
    bayt_t   disk_sektor;
    bayt_t   disk_adres_alt;
    bayt_t   disk_adres_ust;
    bayt_t   disk_sayi;
    bayt_t   disk_hata;
    bayt_t   disk_veri;

    /* Test modu: program PORT_TEST_SONUC'a yazınca dolar */
    bool     test_sonuc_var;
    bayt_t   test_sonuc;
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
