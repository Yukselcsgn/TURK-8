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

static void toplama_uygula(islemci_t *islemci, bayt_t val, uint8_t elde) {
    bayt_t eski_t = islemci->T;
    uint16_t toplam = (uint16_t)eski_t + (uint16_t)val + (uint16_t)elde;
    bayt_t sonuc = (bayt_t)(toplam & 0xFF);
    bool tasma = ((~(eski_t ^ val) & (eski_t ^ sonuc)) & 0x80) != 0;

    islemci_bayrak_kur(islemci, BAYRAK_ELDE, toplam > 0xFF);
    islemci_bayrak_kur(islemci, BAYRAK_TASMA, tasma);
    islemci->T = sonuc;
    islemci_sifir_negatif_guncelle(islemci, sonuc);
}

static void cikarma_uygula(islemci_t *islemci, bayt_t val, uint8_t borc) {
    bayt_t eski_t = islemci->T;
    uint16_t cikan = (uint16_t)val + (uint16_t)borc;
    bayt_t sonuc = (bayt_t)(eski_t - cikan);
    bool tasma = (((eski_t ^ val) & (eski_t ^ sonuc)) & 0x80) != 0;

    islemci_bayrak_kur(islemci, BAYRAK_ELDE, (uint16_t)eski_t >= cikan);
    islemci_bayrak_kur(islemci, BAYRAK_TASMA, tasma);
    islemci->T = sonuc;
    islemci_sifir_negatif_guncelle(islemci, sonuc);
}

static void karsilastir_uygula(islemci_t *islemci, bayt_t sol, bayt_t sag) {
    islemci_bayrak_kur(islemci, BAYRAK_ELDE, sol >= sag);
    islemci_bayrak_kur(islemci, BAYRAK_SIFIR, sol == sag);
    bayt_t fark = (bayt_t)(sol - sag);
    islemci_bayrak_kur(islemci, BAYRAK_NEGATIF, (fark & 0x80) != 0);
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
    islemci->hata = false;
    islemci->kare_bekliyor = false;
    islemci->rng_durum = 0xACE1u;
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

    /* Kesme vektörüne atla (önce ROM 0xFFFE, boşsa RAM 0x00FE) */
    kelime_t kesme_adresi = bellek_oku_kelime(islemci->bellek, VEKTOR_KESME);
    if (kesme_adresi == 0 || kesme_adresi == 0xFFFF) {
        kesme_adresi = bellek_oku_kelime(islemci->bellek, ADRES_KESME_VEKTOR);
    }
    if (kesme_adresi != 0 && kesme_adresi != 0xFFFF) {
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
        /* 1. Sistem ve Kontrol Grubu */
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

        case KMT_SISTEM: {
            bayt_t servis_no = bellek_oku(islemci->bellek, islemci->PS++);
            bellek_yaz(islemci->bellek, ADRES_SISTEM_NO, servis_no);
            islemci_yigina_it_kelime(islemci, islemci->PS);
            islemci_yigina_it_bayt(islemci, islemci->DURUM);
            islemci_bayrak_kur(islemci, BAYRAK_KESME, true);
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, VEKTOR_SISTEM);
            if (hedef == 0 || hedef == 0xFFFF) {
                hedef = bellek_oku_kelime(islemci->bellek, ADRES_SISTEM_VEKTOR);
            }
            if (hedef == 0 || hedef == 0xFFFF) {
                hedef = bellek_oku_kelime(islemci->bellek, VEKTOR_KESME);
            }
            if (hedef != 0 && hedef != 0xFFFF) {
                islemci->PS = hedef;
            }
            break;
        }

        case KMT_KARE_BEKLE:
            islemci->kare_bekliyor = true;
            break;

        case KMT_RASTGELE: {
            /* 16-bit Xorshift PRNG (Donanım zamanlayıcısı ile karıştırılır) */
            uint16_t x = islemci->rng_durum;
            if (x == 0) x = 0xACE1u;
            x ^= (uint16_t)(x << 7);
            x ^= (uint16_t)(x >> 9);
            x ^= (uint16_t)(x << 8);
            islemci->rng_durum = x;
            islemci->T = (bayt_t)((x ^ (x >> 8) ^ islemci->bellek->zamanlayici_sayaci) & 0xFF);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        /* 2. Veri Yükleme, Saklama, Aktarma ve Blok İşlemleri */
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

        case KMT_YUKLE_ADRES_X: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            islemci->X = bellek_oku(islemci->bellek, adr);
            islemci_sifir_negatif_guncelle(islemci, islemci->X);
            break;
        }

        case KMT_YUKLE_ADRES_Y: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            islemci->Y = bellek_oku(islemci->bellek, adr);
            islemci_sifir_negatif_guncelle(islemci, islemci->Y);
            break;
        }

        case KMT_YUKLE_INDEKS_Y_T: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            islemci->T = bellek_oku(islemci->bellek, (kelime_t)(adr + islemci->Y));
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_SAKLA_T_INDEKS_Y: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bellek_yaz(islemci->bellek, (kelime_t)(adr + islemci->Y), islemci->T);
            break;
        }

        case KMT_YUKLE_DOLAYLI_Y_T: {
            kelime_t isaretci_adresi = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            kelime_t taban = bellek_oku_kelime(islemci->bellek, isaretci_adresi);
            islemci->T = bellek_oku(islemci->bellek, (kelime_t)(taban + islemci->Y));
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_SAKLA_T_DOLAYLI_Y: {
            kelime_t isaretci_adresi = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            kelime_t taban = bellek_oku_kelime(islemci->bellek, isaretci_adresi);
            bellek_yaz(islemci->bellek, (kelime_t)(taban + islemci->Y), islemci->T);
            break;
        }

        case KMT_AKTAR_YG_T:
            islemci->T = islemci->YG;
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;

        case KMT_AKTAR_T_YG:
            islemci->YG = islemci->T;
            break;

        case KMT_KOPYALA: {
            kelime_t kaynak = bellek_oku_kelime(islemci->bellek, ADRES_BLOK_KAYNAK);
            kelime_t hedef  = bellek_oku_kelime(islemci->bellek, ADRES_BLOK_HEDEF);
            kelime_t uzunluk = bellek_oku_kelime(islemci->bellek, ADRES_BLOK_UZUNLUK);
            if (uzunluk > 0) {
                if (hedef > kaynak && (uint32_t)hedef < (uint32_t)kaynak + (uint32_t)uzunluk) {
                    for (uint32_t i = uzunluk; i > 0; i--) {
                        bayt_t b = bellek_oku(islemci->bellek, (kelime_t)(kaynak + i - 1));
                        bellek_yaz(islemci->bellek, (kelime_t)(hedef + i - 1), b);
                    }
                } else {
                    for (uint32_t i = 0; i < uzunluk; i++) {
                        bayt_t b = bellek_oku(islemci->bellek, (kelime_t)(kaynak + i));
                        bellek_yaz(islemci->bellek, (kelime_t)(hedef + i), b);
                    }
                }
            }
            bellek_yaz_kelime(islemci->bellek, ADRES_BLOK_UZUNLUK, 0);
            islemci_bayrak_kur(islemci, BAYRAK_SIFIR, true);
            islemci_bayrak_kur(islemci, BAYRAK_NEGATIF, false);
            break;
        }

        case KMT_DOLDUR: {
            kelime_t hedef   = bellek_oku_kelime(islemci->bellek, ADRES_BLOK_HEDEF);
            kelime_t uzunluk = bellek_oku_kelime(islemci->bellek, ADRES_BLOK_UZUNLUK);
            for (uint32_t i = 0; i < uzunluk; i++) {
                bellek_yaz(islemci->bellek, (kelime_t)(hedef + i), islemci->T);
            }
            bellek_yaz_kelime(islemci->bellek, ADRES_BLOK_UZUNLUK, 0);
            islemci_bayrak_kur(islemci, BAYRAK_SIFIR, true);
            islemci_bayrak_kur(islemci, BAYRAK_NEGATIF, false);
            break;
        }

        /* 3. Aritmetik ve Karşılaştırma */
        case KMT_TOPLA_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            toplama_uygula(islemci, val, 0);
            break;
        }

        case KMT_TOPLA_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bayt_t val = bellek_oku(islemci->bellek, adr);
            toplama_uygula(islemci, val, 0);
            break;
        }

        case KMT_TOPLA_ELDEYLE: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            uint8_t elde = islemci_bayrak_oku(islemci, BAYRAK_ELDE) ? 1 : 0;
            toplama_uygula(islemci, val, elde);
            break;
        }

        case KMT_CIKAR_SABIT: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            cikarma_uygula(islemci, val, 0);
            break;
        }

        case KMT_CIKAR_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bayt_t val = bellek_oku(islemci->bellek, adr);
            cikarma_uygula(islemci, val, 0);
            break;
        }

        case KMT_CIKAR_BORCLA: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            uint8_t borc = islemci_bayrak_oku(islemci, BAYRAK_ELDE) ? 0 : 1;
            cikarma_uygula(islemci, val, borc);
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
            karsilastir_uygula(islemci, islemci->T, val);
            break;
        }

        case KMT_KARSILASTIR_X: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            karsilastir_uygula(islemci, islemci->X, val);
            break;
        }

        case KMT_KARSILASTIR_Y: {
            bayt_t val = bellek_oku(islemci->bellek, islemci->PS++);
            karsilastir_uygula(islemci, islemci->Y, val);
            break;
        }

        case KMT_KARSILASTIR_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bayt_t val = bellek_oku(islemci->bellek, adr);
            karsilastir_uygula(islemci, islemci->T, val);
            break;
        }

        case KMT_ELDE_KUR:
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, true);
            break;

        case KMT_ELDE_TEMIZLE:
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, false);
            break;

        case KMT_ARTIR_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bayt_t val = (bayt_t)(bellek_oku(islemci->bellek, adr) + 1);
            bellek_yaz(islemci->bellek, adr, val);
            islemci_sifir_negatif_guncelle(islemci, val);
            break;
        }

        case KMT_AZALT_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            bayt_t val = (bayt_t)(bellek_oku(islemci->bellek, adr) - 1);
            bellek_yaz(islemci->bellek, adr, val);
            islemci_sifir_negatif_guncelle(islemci, val);
            break;
        }

        case KMT_RAKAMLARA_AYIR: {
            bayt_t deger = islemci->T;
            islemci->Y = (bayt_t)('0' + (deger / 100));
            islemci->X = (bayt_t)('0' + ((deger / 10) % 10));
            islemci->T = (bayt_t)('0' + (deger % 10));
            islemci_bayrak_kur(islemci, BAYRAK_SIFIR, deger == 0);
            islemci_bayrak_kur(islemci, BAYRAK_NEGATIF, false);
            break;
        }

        /* 4. Mantık ve Bit İşlemleri */
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

        case KMT_DONDUR_SOLA: {
            bayt_t eski_elde = islemci_bayrak_oku(islemci, BAYRAK_ELDE) ? 1 : 0;
            bool yeni_elde = (islemci->T & 0x80) != 0;
            islemci->T = (bayt_t)((islemci->T << 1) | eski_elde);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, yeni_elde);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_DONDUR_SAGA: {
            bayt_t eski_elde = islemci_bayrak_oku(islemci, BAYRAK_ELDE) ? 0x80 : 0;
            bool yeni_elde = (islemci->T & 0x01) != 0;
            islemci->T = (bayt_t)((islemci->T >> 1) | eski_elde);
            islemci_bayrak_kur(islemci, BAYRAK_ELDE, yeni_elde);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_BIT_SINA: {
            bayt_t maske = bellek_oku(islemci->bellek, islemci->PS++);
            bayt_t sonuc = (bayt_t)(islemci->T & maske);
            islemci_sifir_negatif_guncelle(islemci, sonuc);
            break;
        }

        case KMT_VE_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            islemci->T &= bellek_oku(islemci->bellek, adr);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        case KMT_VEYA_ADRES: {
            kelime_t adr = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS += 2;
            islemci->T |= bellek_oku(islemci->bellek, adr);
            islemci_sifir_negatif_guncelle(islemci, islemci->T);
            break;
        }

        /* 5. Akış Kontrolü ve Şartlı Atlamalar */
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
            /* İşaretsiz büyüklük (T > val): Elde=1 ve Sıfır=0 */
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            bool elde = islemci_bayrak_oku(islemci, BAYRAK_ELDE);
            bool sifir = islemci_bayrak_oku(islemci, BAYRAK_SIFIR);
            if (elde && !sifir) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_KUCUKSE_ATLA: {
            /* İşaretsiz küçüklük (T < val): Elde=0 */
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (!islemci_bayrak_oku(islemci, BAYRAK_ELDE)) {
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

        case KMT_ELDE_YOKSA_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (!islemci_bayrak_oku(islemci, BAYRAK_ELDE)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_NEGATIFSE_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (islemci_bayrak_oku(islemci, BAYRAK_NEGATIF)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_POZITIFSE_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (!islemci_bayrak_oku(islemci, BAYRAK_NEGATIF)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_TASMA_VARSA_ATLA: {
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (islemci_bayrak_oku(islemci, BAYRAK_TASMA)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_KUCUK_ESITSE_ATLA: {
            /* İşaretsiz küçük veya eşit (T <= val): Elde=0 veya Sıfır=1 */
            kelime_t hedef = bellek_oku_kelime(islemci->bellek, islemci->PS);
            if (!islemci_bayrak_oku(islemci, BAYRAK_ELDE) ||
                islemci_bayrak_oku(islemci, BAYRAK_SIFIR)) {
                islemci->PS = hedef;
            } else {
                islemci->PS += 2;
            }
            break;
        }

        case KMT_ATLA_DOLAYLI: {
            kelime_t isaretci = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci->PS = bellek_oku_kelime(islemci->bellek, isaretci);
            break;
        }

        case KMT_CAGIR_DOLAYLI: {
            kelime_t isaretci = bellek_oku_kelime(islemci->bellek, islemci->PS);
            islemci_yigina_it_kelime(islemci, (kelime_t)(islemci->PS + 2));
            islemci->PS = bellek_oku_kelime(islemci->bellek, isaretci);
            break;
        }

        /* 6. Alt Programlar ve Yığın */
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

        case KMT_IT_X:
            islemci_yigina_it_bayt(islemci, islemci->X);
            break;

        case KMT_CEK_X:
            islemci->X = islemci_yigindan_cek_bayt(islemci);
            islemci_sifir_negatif_guncelle(islemci, islemci->X);
            break;

        case KMT_IT_Y:
            islemci_yigina_it_bayt(islemci, islemci->Y);
            break;

        case KMT_CEK_Y:
            islemci->Y = islemci_yigindan_cek_bayt(islemci);
            islemci_sifir_negatif_guncelle(islemci, islemci->Y);
            break;

        /* 7. Giriş / Çıkış (MMIO Portları) */
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
            islemci->hata = true;
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
