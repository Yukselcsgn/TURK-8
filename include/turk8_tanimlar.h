#ifndef TURK8_TANIMLAR_H
#define TURK8_TANIMLAR_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

/* Temel Veri Tipleri */
typedef uint8_t   bayt_t;           /* 8-bitlik veri (0 - 255) */
typedef uint16_t  kelime_t;         /* 16-bitlik adres (0 - 65535) */
typedef int8_t    isaretli_bayt_t;  /* İşaretli 8-bit (-128 ile +127) */

/* Durum Yazmacı (DURUM) Bayrak Maskeleri */
#define BAYRAK_ELDE     (1 << 0)  /* E: Elde (Carry) - 0x01 */
#define BAYRAK_SIFIR    (1 << 1)  /* S: Sıfır (Zero) - 0x02 */
#define BAYRAK_KESME    (1 << 2)  /* K: Kesme Engeli (Interrupt) - 0x04 */
#define BAYRAK_NEGATIF  (1 << 3)  /* N: Negatif (Negative - 7. bit) - 0x08 */
#define BAYRAK_TASMA    (1 << 4)  /* T: Taşma (Overflow) - 0x10 */

/* 64 KB Bellek Haritası Sabitleri */
#define BELLEK_BOYUTU       65536     /* 64 Kilobayt */

#define ADRES_SIFIR_SAYFA   0x0000    /* 0x0000 - 0x00FF: Hızlı Sıfır Sayfa (Zero Page) */
#define ADRES_YIGIN_TABANI  0x0100    /* 0x0100 - 0x01FF: Yığın (Stack - 256 bayt) */
#define ADRES_RAM_BAS       0x0200    /* 0x0200 - 0x7FFF: Genel Kullanıcı Belleği */
#define ADRES_VRAM_BAS      0x8000    /* 0x8000 - 0x83E7: Ekran Belleği (40x25 = 1000 karakter) */
#define EKRAN_GENISLIK      40
#define EKRAN_YUKSEKLIK     25
#define EKRAN_BAYT_SAYISI   (EKRAN_GENISLIK * EKRAN_YUKSEKLIK)

#define ADRES_GIRIS_CIKIS   0xA000    /* 0xA000 - 0xA0FF: Bellek Haritalı Giriş/Çıkış (MMIO) */
#define PORT_KLAVYE_VERI    0xA000    /* Okunan son tuş */
#define PORT_KLAVYE_DURUM   0xA001    /* 1: Yeni tuş var, 0: Yok */
#define PORT_ZAMANLAYICI    0xA002    /* Milisaniye sayacı */
#define PORT_TERMINAL_YAZ   0xA003    /* Standart çıktıya bayt basar */

#define ADRES_ROM_BAS       0xC000    /* 0xC000 - 0xFFFF: Kalıcı Sistem ROM / BIOS (16 KB) */
#define VEKTOR_KESME        0xFFFE    /* Donanım kesmesi atlama adresi */
#define VEKTOR_SIFIRLA      0xFFFC    /* Açılışta Program Sayacının (PS) ilk adresi */

#endif /* TURK8_TANIMLAR_H */

