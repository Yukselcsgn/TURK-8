#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "turk8_tanimlar.h"
#include "bellek.h"
#include "islemci.h"
#include "ekran.h"
#include "ayiklayici.h"

/* Başsız test modu çıkış kodları */
#define CIKIS_TAMAM        0   /* DUR ile bitti ya da test portuna 1 yazıldı */
#define CIKIS_TEST_HATASI  1   /* Program test portuna 1'den farklı değer yazdı */
#define CIKIS_ISLEMCI_HATA 2   /* Bilinmeyen işlem koduyla durdu */
#define CIKIS_ZAMAN_ASIMI  3   /* Çevrim sınırı aşıldı (sonsuz döngü?) */
#define CIKIS_ARGUMAN      4   /* Argüman ya da dosya hatası */

#define EN_FAZLA_DOKUM     8
#define VARSAYILAN_MAX_CEVRIM 10000000ULL

typedef struct {
    kelime_t adres;
    kelime_t uzunluk;
} dokum_istegi_t;

static void yardim_yazdir(const char *prog_adi) {
    printf("===================================================================\n");
    printf("       TÜRK-8: 8-BİT TÜRKÇE MİMARİ VE SANAL BİLGİSAYAR             \n");
    printf("===================================================================\n");
    printf("Kullanım:\n");
    printf("  %s [seçenekler] <program.rom>\n\n", prog_adi);
    printf("Seçenekler:\n");
    printf("  -c, --canli       Gerçek zamanlı etkileşimli ekran modunu (TUI) başlat\n");
    printf("  -m, --monitor     Etkileşimli sistem monitörünü (ayıklayıcı) başlat\n");
    printf("  -e, --ekran       Program bitince 40x25 VRAM ekranını ekrana çiz\n");
    printf("  -d, --dokum       Program bitince 0x0200'den bellek dökümü al\n");
    printf("  -y, --yazmac      Program bitince yazmaç tablosunu göster\n");
    printf("  -a, --adres A     ROM'un yükleneceği adres (varsayılan 0x0200)\n");
    printf("  -h, --yardim      Bu yardım mesajını göster\n\n");
    printf("Test modu (başsız, makine tarafından okunabilir çıktı):\n");
    printf("  -t, --test              Başsız çalıştır; 'T8:' önekli sonuç satırları yaz\n");
    printf("      --max-cevrim N      Çevrim sınırı (varsayılan %llu)\n", VARSAYILAN_MAX_CEVRIM);
    printf("      --bellek-dokum A:U  Bitince A adresinden U bayt dök (en çok %d kez)\n", EN_FAZLA_DOKUM);
    printf("      --ekran-metin       Bitince VRAM'i düz metin olarak dök\n");
    printf("  Çıkış kodları: 0 tamam, 1 test hatası, 2 işlemci hatası, 3 zaman aşımı, 4 argüman hatası\n");
}

static bool sayi_oku(const char *metin, unsigned long *deger) {
    char *son = NULL;
    if (!metin || !*metin) return false;
    *deger = strtoul(metin, &son, 0);
    return son && *son == '\0';
}

static bool dokum_istegi_oku(const char *metin, dokum_istegi_t *istek) {
    char kopya[64];
    char *iki_nokta;
    unsigned long adres, uzunluk;

    if (strlen(metin) >= sizeof(kopya)) return false;
    strcpy(kopya, metin);
    iki_nokta = strchr(kopya, ':');
    if (!iki_nokta) return false;
    *iki_nokta = '\0';
    if (!sayi_oku(kopya, &adres) || !sayi_oku(iki_nokta + 1, &uzunluk)) return false;
    if (adres > 0xFFFF || uzunluk == 0 || adres + uzunluk > BELLEK_BOYUTU) return false;
    istek->adres = (kelime_t)adres;
    istek->uzunluk = (kelime_t)uzunluk;
    return true;
}

static int test_modu_calistir(islemci_t *islemci, bellek_t *bellek,
                              unsigned long long max_cevrim,
                              const dokum_istegi_t *dokumler, int dokum_sayisi,
                              bool ekran_metin) {
    const char *neden = "bitti";
    int cikis = CIKIS_TAMAM;

    while (!islemci->durdu && !bellek->test_sonuc_var && islemci->toplam_cevrim < max_cevrim) {
        islemci_tek_adim(islemci);
        if (islemci->kare_bekliyor) {
            bellek->zamanlayici_sayaci++;
            islemci->kare_bekliyor = false;
        }
    }

    if (bellek->test_sonuc_var) {
        neden = "test_portu";
        cikis = (bellek->test_sonuc == 1) ? CIKIS_TAMAM : CIKIS_TEST_HATASI;
    } else if (islemci->hata) {
        neden = "islemci_hatasi";
        cikis = CIKIS_ISLEMCI_HATA;
    } else if (!islemci->durdu) {
        neden = "zaman_asimi";
        cikis = CIKIS_ZAMAN_ASIMI;
    }

    /* Programın kendi terminal çıktısı satır ortasında kalmış olabilir:
     * önce satır başına geç, böylece T8: satırları her zaman satır başında olur. */
    printf("\nT8:DURUM %s\n", neden);
    if (bellek->test_sonuc_var) {
        printf("T8:TEST_KODU %02X\n", bellek->test_sonuc);
    }
    printf("T8:SONUC T=%02X X=%02X Y=%02X YG=%02X PS=%04X DURUM=%02X CEVRIM=%llu\n",
           islemci->T, islemci->X, islemci->Y, islemci->YG, islemci->PS,
           islemci->DURUM, (unsigned long long)islemci->toplam_cevrim);

    for (int i = 0; i < dokum_sayisi; i++) {
        printf("T8:BELLEK %04X", dokumler[i].adres);
        for (kelime_t j = 0; j < dokumler[i].uzunluk; j++) {
            printf(" %02X", bellek->veri[(kelime_t)(dokumler[i].adres + j)]);
        }
        printf("\n");
    }

    if (ekran_metin) {
        printf("T8:EKRAN\n");
        ekran_metin_dokum(bellek, "T8:| ");
    }

    return cikis;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        yardim_yazdir(argv[0]);
        return CIKIS_ARGUMAN;
    }

    const char *rom_dosyasi = NULL;
    bool canli_modu = false;
    bool monitor_modu = false;
    bool ekran_ciz_istegi = false;
    bool dokum_istegi = false;
    bool yazmac_istegi = false;
    bool test_modu = false;
    bool ekran_metin = false;
    unsigned long yukle_adresi = ADRES_RAM_BAS;
    unsigned long long max_cevrim = VARSAYILAN_MAX_CEVRIM;
    dokum_istegi_t dokumler[EN_FAZLA_DOKUM];
    int dokum_sayisi = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-c") == 0 || strcmp(argv[i], "--canli") == 0) {
            canli_modu = true;
        } else if (strcmp(argv[i], "-m") == 0 || strcmp(argv[i], "--monitor") == 0) {
            monitor_modu = true;
        } else if (strcmp(argv[i], "-e") == 0 || strcmp(argv[i], "--ekran") == 0) {
            ekran_ciz_istegi = true;
        } else if (strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--dokum") == 0) {
            dokum_istegi = true;
        } else if (strcmp(argv[i], "-y") == 0 || strcmp(argv[i], "--yazmac") == 0) {
            yazmac_istegi = true;
        } else if (strcmp(argv[i], "-t") == 0 || strcmp(argv[i], "--test") == 0) {
            test_modu = true;
        } else if (strcmp(argv[i], "--ekran-metin") == 0) {
            ekran_metin = true;
        } else if (strcmp(argv[i], "-a") == 0 || strcmp(argv[i], "--adres") == 0) {
            if (i + 1 >= argc || !sayi_oku(argv[++i], &yukle_adresi) || yukle_adresi > 0xFFFF) {
                fprintf(stderr, "[HATA] --adres için 0..0xFFFF arası bir değer gerekli\n");
                return CIKIS_ARGUMAN;
            }
        } else if (strcmp(argv[i], "--max-cevrim") == 0) {
            unsigned long deger;
            if (i + 1 >= argc || !sayi_oku(argv[++i], &deger) || deger == 0) {
                fprintf(stderr, "[HATA] --max-cevrim için pozitif bir sayı gerekli\n");
                return CIKIS_ARGUMAN;
            }
            max_cevrim = deger;
        } else if (strcmp(argv[i], "--bellek-dokum") == 0) {
            if (dokum_sayisi >= EN_FAZLA_DOKUM || i + 1 >= argc ||
                !dokum_istegi_oku(argv[++i], &dokumler[dokum_sayisi])) {
                fprintf(stderr, "[HATA] --bellek-dokum kullanımı: ADRES:UZUNLUK (en çok %d kez)\n", EN_FAZLA_DOKUM);
                return CIKIS_ARGUMAN;
            }
            dokum_sayisi++;
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--yardim") == 0) {
            yardim_yazdir(argv[0]);
            return 0;
        } else if (argv[i][0] != '-') {
            rom_dosyasi = argv[i];
        } else {
            fprintf(stderr, "[HATA] Bilinmeyen seçenek: %s (yardım için -h)\n", argv[i]);
            return CIKIS_ARGUMAN;
        }
    }

    /* 1. Bellek ve İşlemciyi Oluştur */
    bellek_t bellek;
    bellek_olustur(&bellek);

    islemci_t islemci;
    islemci_olustur(&islemci, &bellek);

    /* VRAM'i temizle */
    ekran_temizle(&bellek);

    /* 2. ROM Dosyasını Yükle (varsayılan RAM adresi: 0x0200) */
    if (rom_dosyasi) {
        if (!test_modu) {
            printf("[SİSTEM] Program yükleniyor: %s\n", rom_dosyasi);
        }
        if (!bellek_yukle_ikili(&bellek, (kelime_t)yukle_adresi, rom_dosyasi)) {
            fprintf(stderr, "[HATA] ROM dosyası okunamadı veya belleğe sığmadı: %s\n", rom_dosyasi);
            return CIKIS_ARGUMAN;
        }
        islemci.PS = (kelime_t)yukle_adresi;
        if (!test_modu) {
            printf("[SİSTEM] Başlangıç Program Sayacı (PS): 0x%04X\n", islemci.PS);
        }
    } else if (test_modu) {
        fprintf(stderr, "[HATA] Test modu için bir ROM dosyası gerekli\n");
        return CIKIS_ARGUMAN;
    }

    if (test_modu) {
        return test_modu_calistir(&islemci, &bellek, max_cevrim,
                                  dokumler, dokum_sayisi, ekran_metin);
    }

    ayiklayici_t ayiklayici;
    ayiklayici_olustur(&ayiklayici, &islemci);

    /* 3. Çalıştırma Modu */
    if (canli_modu) {
        ekran_canli_mod_baslat(&islemci, &bellek);
    } else if (monitor_modu) {
        ayiklayici_kabuk_baslat(&ayiklayici);
    } else {
        printf("[SİSTEM] TÜRK-8 çalışmaya başladı...\n");
        while (!islemci.durdu) {
            islemci_tek_adim(&islemci);
            if (islemci.kare_bekliyor) {
                bellek.zamanlayici_sayaci++;
                islemci.kare_bekliyor = false;
            }
        }
        printf("\n[SİSTEM] İşlemci DURDU. Toplam Çevrim: %llu\n", (unsigned long long)islemci.toplam_cevrim);

        if (yazmac_istegi || !ekran_ciz_istegi) {
            islemci_durum_yazdir(&islemci);
        }
        if (ekran_ciz_istegi) {
            ekran_ciz(&bellek);
        }
        if (dokum_istegi) {
            bellek_dokum_yazdir(&bellek, ADRES_RAM_BAS, 128);
        }
    }

    return 0;
}
