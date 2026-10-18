#ifndef EKRAN_H
#define EKRAN_H

#include "turk8_tanimlar.h"
#include "bellek.h"

struct islemci_t;

/* VRAM Ekran Yönetimi */
void ekran_temizle(bellek_t *bellek);
void ekran_karakter_koy(bellek_t *bellek, uint8_t x, uint8_t y, char karakter);
void ekran_metin_yaz(bellek_t *bellek, uint8_t x, uint8_t y, const char *metin);

/* Terminalde Retro Yeşil/Kehribar Monitör Görünümü Çiz */
void ekran_ciz(const bellek_t *bellek);

/* VRAM'i çerçevesiz düz metin olarak yazdırır; her satırın başına 'onek' eklenir,
 * satır sonundaki boşluklar atılır (testlerde ekran içeriğini doğrulamak için). */
void ekran_metin_dokum(const bellek_t *bellek, const char *onek);

/* Gerçek Zamanlı Canlı İnteraktif Ekran ve Klavye Döngüsü */
void ekran_canli_mod_baslat(void *islemci_ptr, bellek_t *bellek);

#endif /* EKRAN_H */
