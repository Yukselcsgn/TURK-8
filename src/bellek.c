#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "bellek.h"

void bellek_olustur(bellek_t *bellek) {
    if (!bellek) return;
    memset(bellek->veri, 0, sizeof(bellek->veri));
    bellek->rom_yazma_korumali = true;
    bellek->klavye_tamponu = 0;
    bellek->klavye_hazir = false;
    bellek->zamanlayici_sayaci = 0;
}

void bellek_sifirla(bellek_t *bellek) {
    bellek_olustur(bellek);
}

bayt_t bellek_oku(bellek_t *bellek, kelime_t adres) {
    if (!bellek) return 0;

    /* Giriş/Çıkış Portları (MMIO: 0xA000 - 0xA0FF) */
    if (adres == PORT_KLAVYE_VERI) {
        bayt_t tus = bellek->klavye_tamponu;
        bellek->klavye_hazir = false; /* Okununca bayrağı sıfırla */
        return tus;
    }
    if (adres == PORT_KLAVYE_DURUM) {
        return bellek->klavye_hazir ? 1 : 0;
    }
    if (adres == PORT_ZAMANLAYICI) {
        return bellek->zamanlayici_sayaci++;
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
    if (adres == PORT_TERMINAL_YAZ) {
        /* Doğrudan terminal konsoluna karakter bas */
        putchar(deger);
        fflush(stdout);
        return;
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
    bellek->klavye_tamponu = tus;
    bellek->klavye_hazir = true;
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

