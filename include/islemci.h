#ifndef ISLEMCI_H
#define ISLEMCI_H

#include "turk8_tanimlar.h"
#include "bellek.h"
#include "komutlar.h"

/* TÜRK-8 Merkezi İşlem Birimi (MİB / CPU) */
typedef struct {
    /* Yazmaçlar (Registers) */
    bayt_t    T;       /* Toplaç (Akümülatör - A) */
    bayt_t    X;       /* 1. İndeks Yazmacı */
    bayt_t    Y;       /* 2. İndeks Yazmacı */
    bayt_t    YG;      /* Yığın Göstergesi (Stack Pointer - SP) */
    kelime_t  PS;      /* Program Sayacı (Program Counter - PC) */
    bayt_t    DURUM;   /* Durum Bayrakları [T|N|K|S|E] */

    /* İşlemci Durumu */
    bool      durdu;          /* true ise işlemci DUR komutuyla durmuştur */
    bool      hata;           /* true ise bilinmeyen işlem koduyla durmuştur */
    uint64_t  toplam_cevrim;  /* Toplam saat vuruşu sayısı */

    /* Veri Yolu (Bağlı 64 KB Bellek) */
    bellek_t *bellek;
} islemci_t;

/* İşlemci Yaşam Döngüsü */
void   islemci_olustur(islemci_t *islemci, bellek_t *bellek);
void   islemci_sifirla(islemci_t *islemci);

/* Komut Döngüsü (Fetch - Decode - Execute) */
uint8_t islemci_tek_adim(islemci_t *islemci);
void    islemci_kesme_uret(islemci_t *islemci);

/* Bayrak İşlemleri */
void   islemci_bayrak_kur(islemci_t *islemci, bayt_t bayrak, bool durum);
bool   islemci_bayrak_oku(const islemci_t *islemci, bayt_t bayrak);
void   islemci_sifir_negatif_guncelle(islemci_t *islemci, bayt_t deger);

/* Yığın (Stack) İşlemleri */
void   islemci_yigina_it_bayt(islemci_t *islemci, bayt_t deger);
bayt_t islemci_yigindan_cek_bayt(islemci_t *islemci);
void   islemci_yigina_it_kelime(islemci_t *islemci, kelime_t deger);
kelime_t islemci_yigindan_cek_kelime(islemci_t *islemci);

/* Hata Ayıklama / Bilgi */
void   islemci_durum_yazdir(const islemci_t *islemci);

#endif /* ISLEMCI_H */

