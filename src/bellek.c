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
    if (!bellek) return;
    char kayitli_disk[256];
    strncpy(kayitli_disk, bellek->disk_dosya_yolu, sizeof(kayitli_disk));
    kayitli_disk[sizeof(kayitli_disk) - 1] = '\0';
    bellek_olustur(bellek);
    strncpy(bellek->disk_dosya_yolu, kayitli_disk, sizeof(bellek->disk_dosya_yolu) - 1);
}

void bellek_disk_bagla(bellek_t *bellek, const char *dosya_yolu) {
    if (!bellek) return;
    if (!dosya_yolu) {
        bellek->disk_dosya_yolu[0] = '\0';
        return;
    }
    strncpy(bellek->disk_dosya_yolu, dosya_yolu, sizeof(bellek->disk_dosya_yolu) - 1);
    bellek->disk_dosya_yolu[sizeof(bellek->disk_dosya_yolu) - 1] = '\0';
}

static void disk_komut_calistir(bellek_t *bellek, bayt_t komut) {
    bellek->disk_komut = komut;
    if (komut == 0) {
        return;
    }

    if (komut == DISK_KOMUT_BILGI) {
        if (bellek->disk_dosya_yolu[0] == '\0') {
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_DOSYA_YOK;
            return;
        }
        FILE *f = fopen(bellek->disk_dosya_yolu, "rb");
        if (!f) {
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_DOSYA_YOK;
            return;
        }
        fclose(f);
        bellek->disk_durum = 0;
        bellek->disk_hata = DISK_HATA_YOK;
        return;
    }

    if (komut != DISK_KOMUT_OKU && komut != DISK_KOMUT_YAZ) {
        bellek->disk_durum = 0xFF;
        bellek->disk_hata = DISK_HATA_GC;
        return;
    }

    if (bellek->disk_dosya_yolu[0] == '\0') {
        bellek->disk_durum = 0xFF;
        bellek->disk_hata = DISK_HATA_DOSYA_YOK;
        return;
    }

    uint32_t sektor_sayisi = (bellek->disk_sayi == 0) ? 1u : (uint32_t)bellek->disk_sayi;
    uint32_t baslangic_sektor = (uint32_t)bellek->disk_sektor;
    uint32_t dma_adres = (uint32_t)bellek->disk_adres_alt | ((uint32_t)bellek->disk_adres_ust << 8);
    uint32_t toplam_bayt = sektor_sayisi * DISK_SEKTOR_BOYUTU;

    if (baslangic_sektor + sektor_sayisi > DISK_TOPLAM_SEKTOR ||
        dma_adres + toplam_bayt > BELLEK_BOYUTU) {
        bellek->disk_durum = 0xFF;
        bellek->disk_hata = DISK_HATA_SEKTOR;
        return;
    }

    if (komut == DISK_KOMUT_OKU) {
        if (bellek->rom_yazma_korumali && dma_adres + toplam_bayt > ADRES_ROM_BAS) {
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_SEKTOR;
            return;
        }
        FILE *f = fopen(bellek->disk_dosya_yolu, "rb");
        if (!f) {
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_DOSYA_YOK;
            return;
        }
        if (fseek(f, (long)(baslangic_sektor * DISK_SEKTOR_BOYUTU), SEEK_SET) != 0) {
            fclose(f);
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_GC;
            return;
        }
        memset(&bellek->veri[dma_adres], 0, toplam_bayt);
        size_t okunan = fread(&bellek->veri[dma_adres], 1, toplam_bayt, f);
        fclose(f);
        if (okunan == 0 && ferror(f)) {
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_GC;
            return;
        }
        bellek->disk_durum = 0;
        bellek->disk_hata = DISK_HATA_YOK;
    } else if (komut == DISK_KOMUT_YAZ) {
        FILE *f = fopen(bellek->disk_dosya_yolu, "r+b");
        if (!f) {
            /* İmaj henüz yoksa 64 KB sıfır dolu oluştur */
            f = fopen(bellek->disk_dosya_yolu, "w+b");
            if (!f) {
                bellek->disk_durum = 0xFF;
                bellek->disk_hata = DISK_HATA_DOSYA_YOK;
                return;
            }
            bayt_t bos_sektor[DISK_SEKTOR_BOYUTU];
            memset(bos_sektor, 0, sizeof(bos_sektor));
            for (int s = 0; s < DISK_TOPLAM_SEKTOR; s++) {
                fwrite(bos_sektor, 1, DISK_SEKTOR_BOYUTU, f);
            }
        }
        if (fseek(f, (long)(baslangic_sektor * DISK_SEKTOR_BOYUTU), SEEK_SET) != 0) {
            fclose(f);
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_GC;
            return;
        }
        size_t yazilan = fwrite(&bellek->veri[dma_adres], 1, toplam_bayt, f);
        fflush(f);
        fclose(f);
        if (yazilan != toplam_bayt) {
            bellek->disk_durum = 0xFF;
            bellek->disk_hata = DISK_HATA_GC;
            return;
        }
        bellek->disk_durum = 0;
        bellek->disk_hata = DISK_HATA_YOK;
    }
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
            disk_komut_calistir(bellek, deger);
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
