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
#define ADRES_BLOK_KAYNAK   0x0000    /* KOPYALA kaynak adresi (16-bit: 0x0000-0x0001) */
#define ADRES_BLOK_HEDEF    0x0002    /* KOPYALA/DOLDUR hedef adresi (16-bit: 0x0002-0x0003) */
#define ADRES_BLOK_UZUNLUK  0x0004    /* KOPYALA/DOLDUR uzunluk (16-bit: 0x0004-0x0005) */
#define ADRES_SISTEM_NO     0x00FA    /* <n> SİSTEM çağrısının servis numarası (1 bayt) */
#define ADRES_SISTEM_VEKTOR 0x00FC    /* RAM yazılım kesmesi vektörü (16-bit: 0x00FC-0x00FD) */
#define ADRES_KESME_VEKTOR  0x00FE    /* RAM donanım kesmesi vektörü (16-bit: 0x00FE-0x00FF) */
#define ADRES_YIGIN_TABANI  0x0100    /* 0x0100 - 0x01FF: Yığın (Stack - 256 bayt) */
#define ADRES_RAM_BAS       0x0200    /* 0x0200 - 0x7FFF: Genel Kullanıcı Belleği */
#define ADRES_VRAM_BAS      0x8000    /* 0x8000 - 0x83E7: Ekran Belleği (40x25 = 1000 karakter) */
#define EKRAN_GENISLIK      40
#define EKRAN_YUKSEKLIK     25
#define EKRAN_BAYT_SAYISI   (EKRAN_GENISLIK * EKRAN_YUKSEKLIK)

#define ADRES_GIRIS_CIKIS   0xA000    /* 0xA000 - 0xA0FF: Bellek Haritalı Giriş/Çıkış (MMIO) */
#define PORT_KLAVYE_VERI    0xA000    /* Klavye 16 baytlık FIFO tamponundan sıradaki tuşu çeker */
#define PORT_KLAVYE_DURUM   0xA001    /* 1: Tamponda okunmamış tuş var, 0: Boş */
#define PORT_ZAMANLAYICI    0xA002    /* 50 Hz donanım kare sayacı */
#define PORT_TERMINAL_YAZ   0xA003    /* Standart çıktıya bayt basar */
#define PORT_SES_FREKANS    0xA004    /* Ses üreteci frekans / nota kodu (0: sessiz, 1-255) */
#define PORT_SES_SURE       0xA005    /* Ses süresi (20ms kare birimi; yazılınca sesi tetikler) */
#define PORT_RASTGELE       0xA006    /* Donanım rastgele sayı üreteci portu (0-255) */

/* Sanal Disk Denetleyici Port Alanı (0xA010 - 0xA017) */
#define PORT_DISK_KOMUT     0xA010    /* Disk komutu (1: Oku, 2: Yaz, 3: Bilgi) */
#define PORT_DISK_DURUM     0xA011    /* Disk durumu (0: Hazır, 1: Meşgul, 0xFF: Hata) */
#define PORT_DISK_SEKTOR    0xA012    /* Sektör numarası (0 - 255) */
#define PORT_DISK_ADRES_ALT 0xA013    /* DMA bellek adresi alt baytı */
#define PORT_DISK_ADRES_UST 0xA014    /* DMA bellek adresi üst baytı */
#define PORT_DISK_SAYI      0xA015    /* Okunacak/yazılacak sektör sayısı */
#define PORT_DISK_HATA      0xA016    /* Son disk hata kodu */
#define PORT_DISK_VERI      0xA017    /* Bayt akış veri portu */

#define PORT_TEST_SONUC     0xA0FF    /* Test modu: 1 yazılırsa BAŞARILI, başka değer hata kodu; yazılınca çalışma biter */

#define KLAVYE_FIFO_BOYUTU  16        /* Donanım klavye FIFO tampon kapasitesi (bayt) */
#define CEVRIM_50HZ_KARE    500       /* 50 Hz kare başına varsayılan işlemci saat çevrimi */

#define ADRES_ROM_BAS       0xC000    /* 0xC000 - 0xFFFF: Kalıcı Sistem ROM / BIOS (16 KB) */
#define VEKTOR_SISTEM       0xFFFA    /* Yazılım kesmesi (<n> SİSTEM) atlama adresi */
#define VEKTOR_SIFIRLA      0xFFFC    /* Açılışta Program Sayacının (PS) ilk adresi */
#define VEKTOR_KESME        0xFFFE    /* Donanım kesmesi atlama adresi */

#endif /* TURK8_TANIMLAR_H */

