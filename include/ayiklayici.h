#ifndef AYIKLAYICI_H
#define AYIKLAYICI_H

#include "turk8_tanimlar.h"
#include "islemci.h"

/* TÜRK-8 Etkileşimli Canlı Hata Ayıklayıcı ve Sistem Monitörü */
typedef struct {
    islemci_t *islemci;
    kelime_t   kesme_noktalari[16];
    uint8_t    kesme_noktasi_sayisi;
} ayiklayici_t;

void ayiklayici_olustur(ayiklayici_t *ayiklayici, islemci_t *islemci);
void ayiklayici_kesme_noktasi_ekle(ayiklayici_t *ayiklayici, kelime_t adres);
bool ayiklayici_kesme_noktasi_mi(const ayiklayici_t *ayiklayici, kelime_t adres);

/* Komut Ayrıştırıcı (Disassembler) */
int  ayiklayici_komut_ayristir(const bellek_t *bellek, kelime_t adres, char *cikti_tamponu, size_t tampon_boyutu);
void ayiklayici_kod_dokumu(const islemci_t *islemci, kelime_t baslangic, int komut_sayisi);

/* Etkileşimli TUI Monitörü Başlat */
void ayiklayici_kabuk_baslat(ayiklayici_t *ayiklayici);

#endif /* AYIKLAYICI_H */

