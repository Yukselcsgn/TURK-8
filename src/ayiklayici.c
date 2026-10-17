#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ayiklayici.h"
#include "ekran.h"

void ayiklayici_olustur(ayiklayici_t *ayiklayici, islemci_t *islemci) {
    if (!ayiklayici) return;
    ayiklayici->islemci = islemci;
    ayiklayici->kesme_noktasi_sayisi = 0;
    memset(ayiklayici->kesme_noktalari, 0, sizeof(ayiklayici->kesme_noktalari));
}

void ayiklayici_kesme_noktasi_ekle(ayiklayici_t *ayiklayici, kelime_t adres) {
    if (!ayiklayici || ayiklayici->kesme_noktasi_sayisi >= 16) return;
    ayiklayici->kesme_noktalari[ayiklayici->kesme_noktasi_sayisi++] = adres;
    printf("[AYIKLAYICI] Kesme noktası eklendi: 0x%04X\n", adres);
}

bool ayiklayici_kesme_noktasi_mi(const ayiklayici_t *ayiklayici, kelime_t adres) {
    if (!ayiklayici) return false;
    for (uint8_t i = 0; i < ayiklayici->kesme_noktasi_sayisi; i++) {
        if (ayiklayici->kesme_noktalari[i] == adres) return true;
    }
    return false;
}

int ayiklayici_komut_ayristir(const bellek_t *bellek, kelime_t adres, char *cikti_tamponu, size_t tampon_boyutu) {
    if (!bellek || !cikti_tamponu) return 1;

    bayt_t opcode = bellek->veri[adres];
    const komut_bilgi_t *bilgi = komut_bilgisi_al(opcode);

    if (bilgi->uzunluk_bayt == 1) {
        snprintf(cikti_tamponu, tampon_boyutu, "%-22s", bilgi->turkce_ad);
        return 1;
    } else if (bilgi->uzunluk_bayt == 2) {
        bayt_t op1 = bellek->veri[(kelime_t)(adres + 1)];
        switch ((komut_kodu_t)opcode) {
            case KMT_YUKLE_SABIT_T:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) T YÜKLE", op1, op1);
                break;
            case KMT_YUKLE_SABIT_X:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) X YÜKLE", op1, op1);
                break;
            case KMT_YUKLE_SABIT_Y:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) Y YÜKLE", op1, op1);
                break;
            case KMT_TOPLA_SABIT:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) TOPLA", op1, op1);
                break;
            case KMT_TOPLA_ELDEYLE:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) ELDEYLE TOPLA", op1, op1);
                break;
            case KMT_CIKAR_SABIT:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) ÇIKAR", op1, op1);
                break;
            case KMT_KARSILASTIR_SABIT:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) KARŞILAŞTIR", op1, op1);
                break;
            case KMT_KARSILASTIR_X:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X (%d) X KARŞILAŞTIR", op1, op1);
                break;
            case KMT_VE_SABIT:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X VE", op1);
                break;
            case KMT_VEYA_SABIT:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X VEYA", op1);
                break;
            case KMT_OZELVEYA_SABIT:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%02X ÖZELVEYA", op1);
                break;
            case KMT_GIRIS:
                snprintf(cikti_tamponu, tampon_boyutu, "PORT 0x%02X GİRİŞ", op1);
                break;
            case KMT_CIKIS:
                snprintf(cikti_tamponu, tampon_boyutu, "PORT 0x%02X ÇIKIŞ", op1);
                break;
            default:
                snprintf(cikti_tamponu, tampon_boyutu, "%s 0x%02X", bilgi->turkce_ad, op1);
                break;
        }
        return 2;
    } else if (bilgi->uzunluk_bayt == 3) {
        bayt_t alt = bellek->veri[(kelime_t)(adres + 1)];
        bayt_t ust = bellek->veri[(kelime_t)(adres + 2)];
        kelime_t hedef = (kelime_t)(alt | (ust << 8));

        switch ((komut_kodu_t)opcode) {
            case KMT_YUKLE_ADRES_T:
                snprintf(cikti_tamponu, tampon_boyutu, "[0x%04X] T YÜKLE", hedef);
                break;
            case KMT_YUKLE_INDEKS_X_T:
                snprintf(cikti_tamponu, tampon_boyutu, "[0x%04X + X] T YÜKLE", hedef);
                break;
            case KMT_SAKLA_T_ADRES:
                snprintf(cikti_tamponu, tampon_boyutu, "T [0x%04X] SAKLA", hedef);
                break;
            case KMT_SAKLA_T_INDEKS_X:
                snprintf(cikti_tamponu, tampon_boyutu, "T [0x%04X + X] SAKLA", hedef);
                break;
            case KMT_SAKLA_X_ADRES:
                snprintf(cikti_tamponu, tampon_boyutu, "X [0x%04X] SAKLA", hedef);
                break;
            case KMT_SAKLA_Y_ADRES:
                snprintf(cikti_tamponu, tampon_boyutu, "Y [0x%04X] SAKLA", hedef);
                break;
            case KMT_TOPLA_ADRES:
                snprintf(cikti_tamponu, tampon_boyutu, "[0x%04X] TOPLA", hedef);
                break;
            case KMT_CIKAR_ADRES:
                snprintf(cikti_tamponu, tampon_boyutu, "[0x%04X] ÇIKAR", hedef);
                break;
            case KMT_ATLA:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%04X ATLA", hedef);
                break;
            case KMT_ESITSE_ATLA:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%04X EŞİTSE ATLA", hedef);
                break;
            case KMT_FARKLIYSA_ATLA:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%04X FARKLIYSA ATLA", hedef);
                break;
            case KMT_BUYUKSE_ATLA:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%04X BÜYÜKSE ATLA", hedef);
                break;
            case KMT_KUCUKSE_ATLA:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%04X KÜÇÜKSE ATLA", hedef);
                break;
            case KMT_ELDE_VARSA_ATLA:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%04X ELDE VARSA ATLA", hedef);
                break;
            case KMT_CAGIR:
                snprintf(cikti_tamponu, tampon_boyutu, "0x%04X ÇAĞIR", hedef);
                break;
            default:
                snprintf(cikti_tamponu, tampon_boyutu, "%s 0x%04X", bilgi->turkce_ad, hedef);
                break;
        }
        return 3;
    }

    snprintf(cikti_tamponu, tampon_boyutu, "BILINMEYEN 0x%02X", opcode);
    return 1;
}

void ayiklayici_kod_dokumu(const islemci_t *islemci, kelime_t baslangic, int komut_sayisi) {
    if (!islemci) return;
    kelime_t curr = baslangic;
    char tampon[64];

    printf("\n--- PROGRAM SAYACI ÇEVRESİNDEKİ KOMUTLAR ---\n");
    for (int i = 0; i < komut_sayisi; i++) {
        bool su_anki = (curr == islemci->PS);
        int boyut = ayiklayici_komut_ayristir(islemci->bellek, curr, tampon, sizeof(tampon));

        printf(" %s 0x%04X: ", su_anki ? "-->" : "   ", curr);
        for (int b = 0; b < 3; b++) {
            if (b < boyut) {
                printf("%02X ", islemci->bellek->veri[(kelime_t)(curr + b)]);
            } else {
                printf("   ");
            }
        }
        printf(" %s\n", tampon);
        curr += boyut;
    }
}

void ayiklayici_kabuk_baslat(ayiklayici_t *ayiklayici) {
    if (!ayiklayici || !ayiklayici->islemci) return;

    printf("\n=======================================================\n");
    printf("         TÜRK-8 ETKİLEŞİMLİ SİSTEM MONİTÖRÜ           \n");
    printf("       Komutlar: (a)dım [n], (k)oş, (d)öküm [adr],     \n");
    printf("                 (e)kran, (y)azmac, (b)reakpoint, (c)ık\n");
    printf("=======================================================\n");

    char satir[128];
    while (true) {
        printf("\n[PS: 0x%04X] > ", ayiklayici->islemci->PS);
        if (!fgets(satir, sizeof(satir), stdin)) break;

        char kmt = satir[0];
        if (kmt == 'c' || kmt == 'C' || kmt == 'q') {
            printf("[MONİTÖR] Çıkılıyor...\n");
            break;
        } else if (kmt == 'a' || kmt == 'A' || kmt == 's' || kmt == '\n') {
            /* Adım çalıştır */
            int adim_sayisi = 1;
            if (kmt != '\n') {
                sscanf(satir + 1, "%d", &adim_sayisi);
                if (adim_sayisi <= 0) adim_sayisi = 1;
            }
            for (int i = 0; i < adim_sayisi && !ayiklayici->islemci->durdu; i++) {
                char ayrismis[64];
                ayiklayici_komut_ayristir(ayiklayici->islemci->bellek, ayiklayici->islemci->PS, ayrismis, sizeof(ayrismis));
                printf("[ADIM] 0x%04X: %s\n", ayiklayici->islemci->PS, ayrismis);
                islemci_tek_adim(ayiklayici->islemci);
                if (ayiklayici_kesme_noktasi_mi(ayiklayici, ayiklayici->islemci->PS)) {
                    printf("[UYARI] Kesme noktasına ulaşıldı: 0x%04X\n", ayiklayici->islemci->PS);
                    break;
                }
            }
            islemci_durum_yazdir(ayiklayici->islemci);
        } else if (kmt == 'k' || kmt == 'K' || kmt == 'r') {
            /* Serbest Koş */
            printf("[MONİTÖR] Program serbest koşuya başladı...\n");
            while (!ayiklayici->islemci->durdu) {
                islemci_tek_adim(ayiklayici->islemci);
                if (ayiklayici_kesme_noktasi_mi(ayiklayici, ayiklayici->islemci->PS)) {
                    printf("[UYARI] Kesme noktasına ulaşıldı: 0x%04X\n", ayiklayici->islemci->PS);
                    break;
                }
            }
            printf("[MONİTÖR] İşlemci durdu veya kesme noktası tetiklendi.\n");
            islemci_durum_yazdir(ayiklayici->islemci);
        } else if (kmt == 'd' || kmt == 'D') {
            /* Bellek dökümü */
            unsigned int adr = 0x0200, uz = 64;
            sscanf(satir + 1, "%x %x", &adr, &uz);
            bellek_dokum_yazdir(ayiklayici->islemci->bellek, (kelime_t)adr, (kelime_t)uz);
        } else if (kmt == 'e' || kmt == 'E') {
            /* VRAM Ekranı çiz */
            ekran_ciz(ayiklayici->islemci->bellek);
        } else if (kmt == 'y' || kmt == 'Y') {
            /* Yazmaçları göster */
            islemci_durum_yazdir(ayiklayici->islemci);
            ayiklayici_kod_dokumu(ayiklayici->islemci, ayiklayici->islemci->PS, 5);
        } else if (kmt == 'b' || kmt == 'B') {
            /* Kesme noktası ekle */
            unsigned int adr = 0;
            if (sscanf(satir + 1, "%x", &adr) == 1) {
                ayiklayici_kesme_noktasi_ekle(ayiklayici, (kelime_t)adr);
            } else {
                printf("[HATA] Kullanım: b <hex_adres> (Örn: b 0210)\n");
            }
        } else {
            printf("[YARDIM] Bilinmeyen komut. Kullanılabilir: (a)dım, (k)oş, (d)öküm, (e)kran, (y)azmaç, (b)reakpoint, (c)ıkış\n");
        }
    }
}

