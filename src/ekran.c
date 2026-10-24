#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include "ekran.h"
#include "islemci.h"

#ifdef _WIN32
    #include <windows.h>
    #include <conio.h>
    static DWORD g_eski_in_mode = 0;
    static DWORD g_eski_out_mode = 0;
    #define BEKLE_MS(ms) Sleep(ms)
#else
    #include <termios.h>
    #include <unistd.h>
    #include <sys/select.h>
    static struct termios g_eski_termios;
    #define BEKLE_MS(ms) usleep((ms) * 1000)
#endif

static bool g_terminal_degisti = false;
static volatile bool g_canli_calisiyor = false;

/* ISO-8859-9 (Latin-5) 8-bit Türkçe karakter kodlarını UTF-8 dizgesine çevirir.
 * Tanınmayan veya kontrol karakterleri için NULL döner. */
const char* ekran_bayt_utf8_karsiligi(bayt_t c) {
    switch (c) {
        case 0xC7: return "\xC3\x87"; /* Ç */
        case 0xE7: return "\xC3\xA7"; /* ç */
        case 0xD0: return "\xC4\x9E"; /* Ğ */
        case 0xF0: return "\xC4\x9F"; /* ğ */
        case 0xDD: return "\xC4\xB0"; /* İ */
        case 0xFD: return "\xC4\xB1"; /* ı */
        case 0xD6: return "\xC3\x96"; /* Ö */
        case 0xF6: return "\xC3\xB6"; /* ö */
        case 0xDE: return "\xC5\x9E"; /* Ş */
        case 0xFE: return "\xC5\x9F"; /* ş */
        case 0xDC: return "\xC3\x9C"; /* Ü */
        case 0xFC: return "\xC3\xBC"; /* ü */
        default:   return NULL;
    }
}

/* 2 baytlık UTF-8 Türkçe karakter dizisini (0xC3/0xC4/0xC5 + ikinci bayt)
 * tek baytlık ISO-8859-9 (Latin-5) TÜRK-8 karakter koduna çevirir. */
bayt_t ekran_utf8_bayta_cevir(bayt_t ilk, bayt_t ikinci) {
    if (ilk == 0xC3) {
        switch (ikinci) {
            case 0x87: return 0xC7; /* Ç */
            case 0xA7: return 0xE7; /* ç */
            case 0x96: return 0xD6; /* Ö */
            case 0xB6: return 0xF6; /* ö */
            case 0x9C: return 0xDC; /* Ü */
            case 0xBC: return 0xFC; /* ü */
            default:   break;
        }
    } else if (ilk == 0xC4) {
        switch (ikinci) {
            case 0x9E: return 0xD0; /* Ğ */
            case 0x9F: return 0xF0; /* ğ */
            case 0xB0: return 0xDD; /* İ */
            case 0xB1: return 0xFD; /* ı */
            default:   break;
        }
    } else if (ilk == 0xC5) {
        switch (ikinci) {
            case 0x9E: return 0xDE; /* Ş */
            case 0x9F: return 0xFE; /* ş */
            default:   break;
        }
    }
    return 0;
}

static void vram_hucre_yazdir(bayt_t c) {
    if (c >= 32 && c <= 126) {
        putchar(c);
    } else if (c == 0) {
        putchar(' ');
    } else {
        const char *utf8 = ekran_bayt_utf8_karsiligi(c);
        if (utf8) {
            fputs(utf8, stdout);
        } else {
            putchar('.');
        }
    }
}

static void terminal_eski_hale_getir(void) {
    if (g_terminal_degisti) {
#ifdef _WIN32
        HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
        HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
        SetConsoleMode(hIn, g_eski_in_mode);
        SetConsoleMode(hOut, g_eski_out_mode);
#else
        tcsetattr(STDIN_FILENO, TCSANOW, &g_eski_termios);
#endif
        printf("\033[?25h\n"); /* İmleci geri göster */
        g_terminal_degisti = false;
    }
}

static void sinyal_yakalayici(int sig) {
    (void)sig;
    g_canli_calisiyor = false;
    terminal_eski_hale_getir();
    exit(0);
}

void ekran_temizle(bellek_t *bellek) {
    if (!bellek) return;
    for (kelime_t i = 0; i < EKRAN_BAYT_SAYISI; i++) {
        bellek_yaz(bellek, (kelime_t)(ADRES_VRAM_BAS + i), ' ');
    }
}

void ekran_karakter_koy(bellek_t *bellek, uint8_t x, uint8_t y, char karakter) {
    if (!bellek || x >= EKRAN_GENISLIK || y >= EKRAN_YUKSEKLIK) return;
    kelime_t ofset = (kelime_t)(y * EKRAN_GENISLIK + x);
    bellek_yaz(bellek, (kelime_t)(ADRES_VRAM_BAS + ofset), (bayt_t)karakter);
}

void ekran_metin_yaz(bellek_t *bellek, uint8_t x, uint8_t y, const char *metin) {
    if (!bellek || !metin) return;
    while (*metin && x < EKRAN_GENISLIK && y < EKRAN_YUKSEKLIK) {
        if (*metin == '\n') {
            x = 0;
            y++;
        } else {
            ekran_karakter_koy(bellek, x++, y, *metin);
        }
        metin++;
    }
}

void ekran_metin_dokum(const bellek_t *bellek, const char *onek) {
    if (!bellek) return;
    if (!onek) onek = "";

    for (int y = 0; y < EKRAN_YUKSEKLIK; y++) {
        int son_dolu = -1;
        for (int x = 0; x < EKRAN_GENISLIK; x++) {
            bayt_t c = bellek->veri[ADRES_VRAM_BAS + y * EKRAN_GENISLIK + x];
            if ((c > 32 && c <= 126) || ekran_bayt_utf8_karsiligi(c) != NULL) {
                son_dolu = x;
            }
        }
        printf("%s", onek);
        for (int x = 0; x <= son_dolu; x++) {
            bayt_t c = bellek->veri[ADRES_VRAM_BAS + y * EKRAN_GENISLIK + x];
            const char *utf8 = ekran_bayt_utf8_karsiligi(c);
            if (utf8) {
                fputs(utf8, stdout);
            } else if (c >= 32 && c <= 126) {
                putchar(c);
            } else {
                putchar(' ');
            }
        }
        printf("\n");
    }
}

void ekran_ciz(const bellek_t *bellek) {
    if (!bellek) return;

    /* ANSI Yeşil Fosfor Rengi: \033[1;32m */
    printf("\033[1;32m");
    printf("╔══════════════════════════════════════════╗\n");
    printf("║          TÜRK-8 VRAM EKRANI (40x25)      ║\n");
    printf("╠══════════════════════════════════════════╣\n");

    for (int y = 0; y < EKRAN_YUKSEKLIK; y++) {
        printf("║");
        for (int x = 0; x < EKRAN_GENISLIK; x++) {
            kelime_t ofset = (kelime_t)(y * EKRAN_GENISLIK + x);
            vram_hucre_yazdir(bellek->veri[ADRES_VRAM_BAS + ofset]);
        }
        printf("║\n");
    }

    printf("╚══════════════════════════════════════════╝\033[0m\n");
}

/* Canlı TUI Çizimi (İmleci başa alarak titreşimsiz yenileme) */
static void canli_arayuz_ciz(const islemci_t *islemci, const bellek_t *bellek) {
    printf("\033[H\033[1;32m");
    printf("╔══════════════════════════════════════════╗\r\n");
    printf("║    TÜRK-8 ETKİLEŞİMLİ CANLI BİLGİSAYAR   ║\r\n");
    printf("╠══════════════════════════════════════════╣\r\n");

    for (int y = 0; y < EKRAN_YUKSEKLIK; y++) {
        printf("║");
        for (int x = 0; x < EKRAN_GENISLIK; x++) {
            kelime_t ofset = (kelime_t)(y * EKRAN_GENISLIK + x);
            vram_hucre_yazdir(bellek->veri[ADRES_VRAM_BAS + ofset]);
        }
        printf("║\r\n");
    }

    printf("╠══════════════════════════════════════════╣\r\n");
    printf("║ T: 0x%02X (%3d) | X: 0x%02X | Y: 0x%02X        ║\r\n",
           islemci->T, islemci->T, islemci->X, islemci->Y);
    printf("║ PS: 0x%04X | YG: 0x%02X | Çevrim: %-8llu ║\r\n",
           islemci->PS, islemci->YG, (unsigned long long)islemci->toplam_cevrim);
    printf("║ [ESC: Çıkış]  [Klavyeden yazı yazın...]  ║\r\n");
    printf("╚══════════════════════════════════════════╝\033[0m\r\n");
    fflush(stdout);
}

void ekran_canli_mod_baslat(void *islemci_ptr, bellek_t *bellek) {
    islemci_t *islemci = (islemci_t *)islemci_ptr;
    if (!islemci || !bellek) return;

    /* Terminali raw (anlık tuş) moduna al */
#ifdef _WIN32
    HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
    HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    GetConsoleMode(hIn, &g_eski_in_mode);
    GetConsoleMode(hOut, &g_eski_out_mode);

    DWORD yeni_in = g_eski_in_mode & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
    DWORD yeni_out = g_eski_out_mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    SetConsoleMode(hIn, yeni_in);
    SetConsoleMode(hOut, yeni_out);
    SetConsoleModeCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
    g_terminal_degisti = true;
#else
    if (tcgetattr(STDIN_FILENO, &g_eski_termios) == 0) {
        struct termios yeni = g_eski_termios;
        yeni.c_lflag &= ~(ICANON | ECHO);
        yeni.c_cc[VMIN] = 0;
        yeni.c_cc[VTIME] = 0;
        tcsetattr(STDIN_FILENO, TCSANOW, &yeni);
        g_terminal_degisti = true;
    }
#endif

    atexit(terminal_eski_hale_getir);
    signal(SIGINT, sinyal_yakalayici);
    signal(SIGTERM, sinyal_yakalayici);

    /* Terminali temizle ve imleci gizle */
    printf("\033[2J\033[?25l");
    fflush(stdout);

    g_canli_calisiyor = true;

    while (g_canli_calisiyor) {
        /* 1. Klavyeden tuş kontrolü (non-blocking, UTF-8 Türkçe -> 8-bit ISO-8859-9) */
        bool cikis_istendi = false;
#ifdef _WIN32
        while (_kbhit()) {
            bayt_t tus = (bayt_t)_getch();
            if (tus == 27) {
                cikis_istendi = true;
                break;
            }
            if (tus == '\r') tus = '\n';
            if ((tus == 0xC3 || tus == 0xC4 || tus == 0xC5) && _kbhit()) {
                bayt_t ikinci = (bayt_t)_getch();
                bayt_t tr = ekran_utf8_bayta_cevir(tus, ikinci);
                if (tr != 0) tus = tr;
            }
            bellek_klavye_tusu_gonder(bellek, tus);
        }
#else
        bayt_t tus = 0;
        while (read(STDIN_FILENO, &tus, 1) > 0) {
            if (tus == 27) { /* ESC */
                cikis_istendi = true;
                break;
            }
            if (tus == '\r') tus = '\n';
            /* 2 baytlık UTF-8 Türkçe karakter başlangıcı mı? */
            if (tus == 0xC3 || tus == 0xC4 || tus == 0xC5) {
                bayt_t ikinci = 0;
                if (read(STDIN_FILENO, &ikinci, 1) > 0) {
                    bayt_t tr = ekran_utf8_bayta_cevir(tus, ikinci);
                    if (tr != 0) {
                        tus = tr;
                    }
                }
            }
            bellek_klavye_tusu_gonder(bellek, tus);
        }
#endif
        if (cikis_istendi) break;

        /* 2. Donanım 50 Hz Zamanlayıcı Tiki ve Kesmesi */
        islemci_kare_bildir(islemci);

        /* 3. İşlemciyi çalıştır (Her karede en çok 500 komut veya KARE BEKLE'ye kadar) */
        for (int i = 0; i < CEVRIM_50HZ_KARE && !islemci->durdu && !islemci->kare_bekliyor; i++) {
            islemci_tek_adim(islemci);
        }

        /* 4. Ekranı yenile */
        canli_arayuz_ciz(islemci, bellek);

        /* 5. ~50 FPS için 20 ms bekle */
        BEKLE_MS(20);
    }

    terminal_eski_hale_getir();
    printf("\n[SİSTEM] Canlı ekran modundan çıkıldı.\n");
}
