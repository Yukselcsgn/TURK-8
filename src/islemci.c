#include <stdio.h>
#include <string.h>
#include "islemci.h"

void islemci_bayrak_kur(islemci_t *islemci, bayt_t bayrak, bool durum) {
    if (durum) {
        islemci->DURUM |= bayrak;
    } else {
        islemci->DURUM &= ~bayrak;
    }
}

bool islemci_bayrak_oku(const islemci_t *islemci, bayt_t bayrak) {
    return (islemci->DURUM & bayrak) != 0;
}

void islemci_sifir_negatif_guncelle(islemci_t *islemci, bayt_t deger) {
    islemci_bayrak_kur(islemci, BAYRAK_SIFIR, (deger == 0));
    islemci_bayrak_kur(islemci, BAYRAK_NEGATIF, (deger & 0x80) != 0);
}

void islemci_yigina_it_bayt(islemci_t *islemci, bayt_t deger) {
    kelime_t yigin_adresi = (kelime_t)(ADRES_YIGIN_TABANI + islemci->YG);
    bellek_yaz(islemci->bellek, yigin_adresi, deger);
    islemci->YG--;
}

bayt_t islemci_yigindan_cek_bayt(islemci_t *islemci) {
    islemci->YG++;
    kelime_t yigin_adresi = (kelime_t)(ADRES_YIGIN_TABANI + islemci->YG);
    return bellek_oku(islemci->bellek, yigin_adresi);
}

void islemci_yigina_it_kelime(islemci_t *islemci, kelime_t deger) {
    /* Küçük uçlu (Little-Endian): Üst bayt önce, alt bayt sonra */
    islemci_yigina_it_bayt(islemci, (bayt_t)((deger >> 8) & 0xFF));
    islemci_yigina_it_bayt(islemci, (bayt_t)(deger & 0xFF));
}

kelime_t islemci_yigindan_cek_kelime(islemci_t *islemci) {
    bayt_t alt = islemci_yigindan_cek_bayt(islemci);
    bayt_t ust = islemci_yigindan_cek_bayt(islemci);
    return (kelime_t)(alt | (ust << 8));
}

void islemci_olustur(islemci_t *islemci, bellek_t *bellek) {
    if (!islemci) return;
    memset(islemci, 0, sizeof(islemci_t));
    islemci->bellek = bellek;
    islemci_sifirla(islemci);
}

void islemci_sifirla(islemci_t *islemci) {
    if (!islemci) return;
    islemci->T = 0;
    islemci->X = 0;
    islemci->Y = 0;
    islemci->YG = 0xFF; /* Yığın 0x01FF adresinden başlar */
    islemci->DURUM = BAYRAK_KESME; /* Başlangıçta kesmeler kapalı */
    islemci->durdu = false;
    islemci->toplam_cevrim = 0;

    /* Açılış Vektörünü Oku (0xFFFC) */
    kelime_t baslangic = bellek_oku_kelime(islemci->bellek, VEKTOR_SIFIRLA);
    if (baslangic == 0 || baslangic == 0xFFFF) {
        /* ROM vektörü tanımlı değilse varsayılan kullanıcı alanından başla */
        islemci->PS = ADRES_RAM_BAS;
    } else {
        islemci->PS = baslangic;
    }
}

void islemci_kesme_uret(islemci_t *islemci) {
    if (!islemci || islemci->durdu) return;

    /* Kesmeler engelliyse çalışma */
    if (islemci_bayrak_oku(islemci, BAYRAK_KESME)) return;

    /* Dönüş adresini ve durum bayrağını yığına kaydet */
    islemci_yigina_it_kelime(islemci, islemci->PS);
    islemci_yigina_it_bayt(islemci, islemci->DURUM);

    /* Yeni kesmeleri engelle */
    islemci_bayrak_kur(islemci, BAYRAK_KESME, true);

    /* Kesme vektörüne atla (0xFFFE) */
    kelime_t kesme_adresi = bellek_oku_kelime(islemci->bellek, VEKTOR_KESME);
    if (kesme_adresi != 0) {
        islemci->PS = kesme_adresi;
    }
}

uint8_t islemci_tek_adim(islemci_t *islemci) {
    if (!islemci || islemci->durdu) return 0;

    /* 1. GETİR (Fetch) */
    bayt_t opcode = bellek_oku(islemci->bellek, islemci->PS++);
    const komut_bilgi_t *bilgi = komut_bilgisi_al(opcode);

    /* 2. ÇÖZ & İŞLET (Decode & Execute) */
    switch ((komut_kodu_t)opcode) {
        case KMT_BOS:
            break;

        case KMT_DUR:
            islemci->durdu = true;
            break;

        case KMT_KESME_AC:
            islemci_bayrak_kur(islemci, BAYRAK_KESME, false);
            break;

        case KMT_KESME_KAPAT:
            islemci_bayrak_kur(islemci, BAYRAK_KESME, true);
            break;

        case KMT_SIFIRLA:
            islemci_sifirla(islemci);
            break;

        /* Veri Yükleme, Saklama ve Aktarma */
        case KMT_YUKLE_SABIT_T: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci->T = val;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_YUKLE_ADRES_T: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            islemci->T = bellek_oku(islemci->bellek, adr);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_YUKLE_INDEKS_X_T: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            islemci->T = bellek_oku(islemci->bellek, (kelime_t)(adr + islemci->X));
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_YUKLE_SABIT_X: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci->X = val;
            islemci_sifir_negatif_guncelle(islemci, islemci->X);
            break;
        }

        case KMT_YUKLE_SABIT_Y: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci->Y = val;
            islemci_sifir_negatif_guncelle(islemci, islemci->Y);
            break;
        }

        case KMT_SAKLA_T_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bellek_yaz(islemci->bellek, adr, islemci->T);
            break;
        }

        case KMT_SAKLA_T_INDEKS_X: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bellek_yaz(islemci->bellek, (kelime_t)(adr + islemci->X), islemci->T);
            break;
        }

        case KMT_SAKLA_X_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bellek_yaz(islemci->bellek, adr, islemci->X);
            break;
        }

        case KMT_SAKLA_Y_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bellek_yaz(islemci->bellek, adr, islemci->Y);
            break;
        }

        case KMT_AKTAR_X_T:
            islemci->T = islemci->X;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;

        case KMT_AKTAR_T_X:
            islemci->X = islemci->T;
            islemci_sifir_negatif_guncelle(islemci, islemci->X);
            break;

        case KMT_AKTAR_Y_T:
            islemci->T = islemci->Y;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;

        case KMT_AKTAR_T_Y:
            islemci->Y = islemci->T;
            islemci_sifir_negatif_guncelle(islemci, islemci->Y);
            break;

        case KMT_YUKLE_DOLAYLI_T: {
            kelime_t isaretci_adresi = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            kelime_t hedef_adres = bellek_oku_kelime(islemci->bellek, isaretci_adresi);
            islemci->T = bellek_oku(islemci->bellek, hedef_adres);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_SAKLA_T_DOLAYLI: {
            kelime_t isaretci_adresi = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            kelime_t hedef_adres = bellek_oku_kelime(islemci->bellek, isaretci_adresi);
            bellek_yaz(islemci->bellek, hedef_adres, islemci->T);
            break;
        }

        /* Aritmetik ve Karşılaştırma */
        case KMT_TOPLA_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            uint16_t toplam = islemci->T + val;
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, toplam > 0xFF);
            islemci->T = (bayt_t)(toplam & 0xFF);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_TOPLA_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bayt_t val = bellek_oku(islemci->bellek, adr);
            uint16_t toplam = islemci->T + val;
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, toplam > 0xFF);
            islemci->T = (bayt_t)(toplam & 0xFF);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_TOPLA_ELDEYLE: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            uint8_t elde = islemci_bayrak_oku(islemci, BAYRAK_ELDE) ? 1 : 0;
            uint16_t toplam = islemci->T + val + elde;
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, toplam > 0xFF);
            islemci->T = (bayt_t)(toplam & 0xFF);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_CIKAR_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, islemci->T >= val); /* Borç yoksa elde=1 */
            islemci->T = (bayt_t)(islemci->T - val);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_CIKAR_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bayt_t val = bellek_oku(islemci->bellek, adr);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, islemci->T >= val);
            islemci->T = (bayt_t)(islemci->T - val);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_ARTIR_T:
            islemci->T++;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;

        case KMT_ARTIR_X:
            islemci->X++;
            islemci_sifir_negatif_guncelle(islemci, islemci->X);
            break;

        case KMT_ARTIR_Y:
            islemci->Y++;
            islemci_sifir_negatif_guncelle(islemci, islemci->Y);
            break;

        case KMT_AZALT_T:
            islemci->T--;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;

        case KMT_AZALT_X:
            islemci->X--;
            islemci_sifir_negatif_guncelle(islemci, islemci->X);
            break;

        case KMT_AZALT_Y:
            islemci->Y--;
            islemci_sifir_negatif_guncelle(islemci, islemci->Y);
            break;

        case KMT_KARSILASTIR_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, islemci->T >= val);
            islemci_bayrak_kur(islemci, BAYRAK_SIFIR, islemci->T == val);
            bayt_t fark = (bayt_t)(islemci->T - val);
            islemci_bayrak_kur(islemci, BAYRAK_NEGATIF, (fark & 0x80) != 0);
            break;
        }

        case KMT_KARSILASTIR_X: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, islemci->X >= val);
            islemci_bayrak_kur(islemci, BAYRAK_SIFIR, islemci->X == val);
            bayt_t fark = (bayt_t)(islemci->X - val);
            islemci_bayrak_kur(islemci, BAYRAK_NEGATIF, (fark & 0x80) != 0);
            break;
        }

        /* Mantık ve Bit İşlemleri */
        case KMT_VE_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci->T &= val;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_VEYA_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci->T |= val;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_OZELVEYA_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            islemci->T ^= val;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_DEGILLE_T:
            islemci->T = (bayt_t)(~islemci->T);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;

        case KMT_KAYDIR_SOLA: {
            bool elde = (islemci->T & 0x80) != 0;
            islemci->T = (bayt_t)(islemci->T << 1);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, elde);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_KAYDIR_SAGA: {
            bool elde = (islemci->T & 0x01) != 0;
            islemci->T = (bayt_t)(islemci->T >> 1);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, elde);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        /* Akış Kontrolü ve Şartlı Atlamalar */
        case KMT_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS = hedef;
            break;
        }

        case KMT_ESITSE_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (islemci_bayrak_oku(islemci, BAYRAK_SIFIR)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_FARKLIYSA_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (!islemci_bayrak_oku(islemci, BAYRAK_SIFIR)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_BUYUKSE_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            bool sifir = islemci_bayrak_oku(islemci, BAYRAK_SIFIR);
            bool negatif = islemci_bayrak_oku(islemci, BAYRAK_NEGATIF);
            if (!sifir && !negatif) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_KUCUKSE_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (islemci_bayrak_oku(islemci, BAYRAK_NEGATIF)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_ELDE_VARSA_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (islemci_bayrak_oku(islemci, BAYRAK_ELDE)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        /* Alt Programlar ve Yığın */
        case KMT_CAGIR: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            /* Dönüş adresi: Bu komuttan sonraki adres (PS + 2) */
            islemci_yigina_it_kelime(islemci, (kelime_t)(islemci->PS + 2));
            islemci->PS = hedef;
            break;
        }

        case KMT_DON:
            islemci->PS = islemci_yigindan_cek_kelime(islemci);
            break;

        case KMT_KESMEDEN_DON:
            islemci->DURUM = islemci_yigindan_cek_bayt(islemci);
            islemci->PS = islemci_yigindan_cek_kelime(islemci);
            break;

        case KMT_IT_T:
            islemci_yigina_it_bayt(islemci, islemci->T);
            break;

        case KMT_CEK_T:
            islemci->T = islemci_yigindan_cek_bayt(islemci);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;

        case KMT_IT_DURUM:
            islemci_yigina_it_bayt(islemci, islemci->DURUM);
            break;

        case KMT_CEK_DURUM:
            islemci->DURUM = islemci_yigindan_cek_bayt(islemci);
            break;

        /* Giriş / Çıkış (MMIO Portları) */
        case KMT_GIRIS: {
            bayt_t port = bellek_oku(islemci->bellek, islemci->PS++);
            kelime_t port_adresi = (kelime_t)(ADRES_GIRIS_CIKIS + port);
            islemci->T = bellek_oku(islemci->bellek, port_adresi);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_CIKIS: {
            bayt_t port = bellek_oku(islemci->bellek, islemci->PS++);
            kelime_t port_adresi = (kelime_t)(ADRES_GIRIS_CIKIS + port);
            bellek_yaz(islemci->bellek, port_adresi, islemci->T);
            break;
        }

        default:
            /* Bilinmeyen komut */
            printf("\n[HATA] Bilinmeyen işlem kodu: 0x%02X (Adres: 0x%04X)\n", opcode, (kelime_t)(islemci->PS - 1));
            islemci->durdu = true;
            break;
    }

    uint8_t cevrim = bilgi ? bilgi->saat_cevrimi : 1;
    islemci->toplam_cevrim += cevrim;
    return cevrim;
}

void islemci_durum_yazdir(const islemci_t *islemci) {
    if (!islemci) return;
    printf("┌────────────────────────────────────────────────────────┐\n");
    printf("│                TÜRK-8 İŞLEMCİ DURUMU                   │\n");
    printf("├────────────────────────────────────────────────────────┤\n");
    printf("│ Toplaç (T): 0x%02X (%3d)   │ X İndeks (X): 0x%02X (%3d)  │\n",
           islemci->T, islemci->T, islemci->X, islemci->X);
    printf("│ Y İndeks (Y): 0x%02X (%3d)   │ Yığın (YG):   0x%02X (0x01%02X)│\n",
           islemci->Y, islemci->Y, islemci->YG, islemci->YG);
    printf("│ Program Sayacı (PS): 0x%04X │ Toplam Çevrim: %llu       │\n",
           islemci->PS, (unsigned long long)islemci->toplam_cevrim);
    printf("├────────────────────────────────────────────────────────┤\n");
    printf("│ DURUM BAYRAKLARI: [E:%d | S:%d | K:%d | N:%d | T:%d]        │\n",
           islemci_bayrak_oku(islemci, BAYRAK_ELDE) ? 1 : 0,
           islemci_bayrak_oku(islemci, BAYRAK_SIFIR) ? 1 : 0,
           islemci_bayrak_oku(islemci, BAYRAK_KESME) ? 1 : 0,
           islemci_bayrak_oku(islemci, BAYRAK_NEGATIF) ? 1 : 0,
           islemci_bayrak_oku(islemci, BAYRAK_TASMA) ? 1 : 0);
    printf("│ Durum: %-15s                                 │\n",
           islemci->durdu ? "DURDU (HALT)" : "ÇALIŞIYOR");
    printf("└────────────────────────────────────────────────────────┘\n");
}

