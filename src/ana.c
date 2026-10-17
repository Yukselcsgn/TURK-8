#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "turk8_tanimlar.h"
#include "bellek.h"
#include "islemci.h"
#include "ekran.h"
#include "ayiklayici.h"

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
    printf("  -h, --yardim      Bu yardım mesajını göster\n");
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        yardim_yazdir(argv[0]);
        return 1;
    }

    const char *rom_dosyasi = NULL;
    bool canli_modu = false;
    bool monitor_modu = false;
    bool ekran_ciz_istegi = false;
    bool dokum_istegi = false;
    bool yazmac_istegi = false;

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
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--yardim") == 0) {
            yardim_yazdir(argv[0]);
            return 0;
        } else if (argv[i][0] != '-') {
            rom_dosyasi = argv[i];
        }
    }

    /* 1. Bellek ve İşlemciyi Oluştur */
    bellek_t bellek;
    bellek_olustur(&bellek);

    islemci_t islemci;
    islemci_olustur(&islemci, &bellek);

    /* VRAM'i temizle */
    ekran_temizle(&bellek);

    /* 2. ROM Dosyasını Yükle (Varsayılan RAM adresi: 0x0200) */
    if (rom_dosyasi) {
        printf("[SİSTEM] Program yükleniyor: %s\n", rom_dosyasi);
        if (!bellek_yukle_ikili(&bellek, ADRES_RAM_BAS, rom_dosyasi)) {
            fprintf(stderr, "[HATA] ROM dosyası okunamadı veya belleğe sığmadı: %s\n", rom_dosyasi);
            return 1;
        }
        islemci.PS = ADRES_RAM_BAS;
        printf("[SİSTEM] Başlangıç Program Sayacı (PS): 0x%04X\n", islemci.PS);
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

