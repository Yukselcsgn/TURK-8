#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "bellek.h"
#include "ekran.h"

void bellek_olustur(bellek_t *bellek) {
    if (!bellek) return;
    memset(bellek, 0, sizeof(bellek_t));
    bellek->rom_yazma_korumali = true;
    bellek->donanim_rng = 0xBEEFu;
}

void bellek_sifirla(bellek_t *bellek) {
    bellek_olustur(bellek);
}

bayt_t bellek_oku(bellek_t *bellek, kelime_t adres) {
    if (!bellek) return 0;

    /* Giriş/Çıkış Portları (MMIO: 0xA000 - 0xA0FF) */
    switch (adres) {
        case PORT_KLAVYE_VERI: {
            if (bellek->klavye_sayi == 0) {
                return 0;
            }
            bayt_t tus = bellek->klavye_fifo[bellek->klavye_bas];
            bellek->klavye_bas = (uint8_t)((bellek->klavye_bas + 1) % KLAVYE_FIFO_BOYUTU);
            bellek->klavye_sayi--;
            bellek->klavye_hazir = (bellek->klavye_sayi > 0);
            bellek->klavye_tamponu = bellek->klavye_hazir
                ? bellek->klavye_fifo[bellek->klavye_bas]
                : 0;
            return tus;
        }
        case PORT_KLAVYE_DURUM:
            return (bellek->klavye_sayi > 0) ? 1 : 0;

        case PORT_ZAMANLAYICI:
            return bellek->zamanlayici_sayaci;

        case PORT_SES_FREKANS:
            return bellek->ses_frekans;

        case PORT_SES_SURE:
            return bellek->ses_sure;

        case PORT_RASTGELE: {
            uint16_t x = bellek->donanim_rng;
            if (x == 0) x = 0xBEEFu;
            x ^= (uint16_t)(x << 7);
            x ^= (uint16_t)(x >> 9);
            x ^= (uint16_t)(x << 8);
            bellek->donanim_rng = x;
            return (bayt_t)((x ^ (x >> 8) ^ bellek->zamanlayici_sayaci) & 0xFF);
        }

        /* Sanal Disk Denetleyici Port Alanı (0xA010 - 0xA017) */
        case PORT_DISK_KOMUT:     return bellek->disk_komut;
        case PORT_DISK_DURUM:     return bellek->disk_durum;
        case PORT_DISK_SEKTOR:    return bellek->disk_sektor;
        case PORT_DISK_ADRES_ALT: return bellek->disk_adres_alt;
        case PORT_DISK_ADRES_UST: return bellek->disk_adres_ust;
        case PORT_DISK_SAYI:      return bellek->disk_sayi;
        case PORT_DISK_HATA:      return bellek->disk_hata;
        case PORT_DISK_VERI:      return bellek->disk_veri;

        default:
            break;
    }

    return bellek->veri[adres];
}

void bellek_yaz(bellek_t *bellek, kelime_t adres, bayt_t deger) {
    if (!bellek) return;

    /* ROM Bölgesi Koruması (0xC000 - 0xFFFF) */
    if (adres >= ADRES_ROM_BAS && bellek->rom_yazma_korumali) {
        /* ROM salt okunurdur, yazma isteği yoksayılır */
        return;
    }

    /* Giriş/Çıkış Portları (MMIO) */
    switch (adres) {
        case PORT_TERMINAL_YAZ: {
            /* Doğrudan terminal konsoluna karakter bas (ISO-8859-9 Türkçe destekli) */
            const char *utf8 = ekran_bayt_utf8_karsiligi(deger);
            if (utf8) {
                fputs(utf8, stdout);
            } else {
                putchar(deger);
            }
            fflush(stdout);
            return;
        }

        case PORT_SES_FREKANS:
            bellek->ses_frekans = deger;
            return;

        case PORT_SES_SURE:
            bellek->ses_sure = deger;
            if (deger > 0 && bellek->ses_frekans > 0) {
                bellek->ses_calma_sayisi++;
                if (!bellek->sessiz_mod) {
                    putchar('\a');
                    fflush(stdout);
                }
            }
            return;

        case PORT_DISK_KOMUT:
            bellek->disk_komut = deger;
            return;
        case PORT_DISK_DURUM:
            bellek->disk_durum = deger;
            return;
        case PORT_DISK_SEKTOR:
            bellek->disk_sektor = deger;
            return;
        case PORT_DISK_ADRES_ALT:
            bellek->disk_adres_alt = deger;
            return;
        case PORT_DISK_ADRES_UST:
            bellek->disk_adres_ust = deger;
            return;
        case PORT_DISK_SAYI:
            bellek->disk_sayi = deger;
            return;
        case PORT_DISK_HATA:
            bellek->disk_hata = deger;
            return;
        case PORT_DISK_VERI:
            bellek->disk_veri = deger;
            return;

        case PORT_TEST_SONUC:
            bellek->test_sonuc = deger;
            bellek->test_sonuc_var = true;
            return;

        default:
            break;
    }

    bellek->veri[adres] = deger;
}

kelime_t bellek_oku_kelime(bellek_t *bellek, kelime_t adres) {
    /* Küçük Uçlu (Little-Endian): Alt bayt önce, üst bayt sonra */
    bayt_t alt = bellek_oku(bellek, adres);
    bayt_t ust = bellek_oku(bellek, (kelime_t)(adres + 1));
    return (kelime_t)(alt | (ust << 8));
}

void bellek_yaz_kelime(bellek_t *bellek, kelime_t adres, kelime_t deger) {
    bayt_t alt = (bayt_t)(deger & 0xFF);
    bayt_t ust = (bayt_t)((deger >> 8) & 0xFF);
    bellek_yaz(bellek, adres, alt);
    bellek_yaz(bellek, (kelime_t)(adres + 1), ust);
}

bool bellek_yukle_ikili(bellek_t *bellek, kelime_t baslangic_adresi, const char *dosya_yolu) {
    if (!bellek || !dosya_yolu) return false;

    FILE *f = fopen(dosya_yolu, "rb");
    if (!f) return false;

    fseek(f, 0, SEEK_END);
    long boyut = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (boyut <= 0 || baslangic_adresi + boyut > BELLEK_BOYUTU) {
        fclose(f);
        return false;
    }

    /* ROM'a yazabilmek için geçici korumayı kaldır */
    bool eski_koruma = bellek->rom_yazma_korumali;
    bellek->rom_yazma_korumali = false;

    size_t okunan = fread(&bellek->veri[baslangic_adresi], 1, boyut, f);
    fclose(f);

    bellek->rom_yazma_korumali = eski_koruma;
    return (okunan == (size_t)boyut);
}

void bellek_klavye_tusu_gonder(bellek_t *bellek, bayt_t tus) {
    if (!bellek) return;
    if (bellek->klavye_sayi >= KLAVYE_FIFO_BOYUTU) {
        /* 16 baytlık FIFO dolu: mevcut kuyruğu bozmadan taşma bayrağını işaretle */
        bellek->klavye_tasti = true;
        return;
    }
    bellek->klavye_fifo[bellek->klavye_son] = tus;
    bellek->klavye_son = (uint8_t)((bellek->klavye_son + 1) % KLAVYE_FIFO_BOYUTU);
    bellek->klavye_sayi++;
    bellek->klavye_hazir = true;
    bellek->klavye_tamponu = bellek->klavye_fifo[bellek->klavye_bas];
}

void bellek_dokum_yazdir(const bellek_t *bellek, kelime_t baslangic, kelime_t uzunluk) {
    if (!bellek) return;

    printf("\n--- BELLEK DÖKÜMÜ [0x%04X - 0x%04X] ---\n", baslangic, baslangic + uzunluk - 1);
    for (kelime_t i = 0; i < uzunluk; i += 16) {
        kelime_t satir_adresi = baslangic + i;
        printf("%04X: ", satir_adresi);

        /* Hex baytlar */
        for (int j = 0; j < 16; j++) {
            if (i + j < uzunluk) {
                printf("%02X ", bellek->veri[satir_adresi + j]);
            } else {
                printf("   ");
            }
            if (j == 7) printf(" ");
        }

        /* ASCII Karakterler */
        printf(" |");
        for (int j = 0; j < 16 && (i + j < uzunluk); j++) {
            bayt_t b = bellek->veri[satir_adresi + j];
            if (b >= 32 && b <= 126) {
                putchar(b);
            } else {
                putchar('.');
            }
        }
        printf("|\n");
    }
}
