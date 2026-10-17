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
            bayt_t c = bellek->veri[ADRES_VRAM_BAS + ofset];
            if (c >= 32 && c <= 126) {
                putchar(c);
            } else if (c == 0) {
                putchar(' ');
            } else {
                putchar('.');
            }
        }
        printf("║\n");
    }

    printf("╚══════════════════════════════════════════╝\033[0m\n");
}

/* Canlı TUI Çizimi (İmleci başa alarak titreşimsiz yenileme) */
static void canli_arayuz_ciz(const islemci_t *islemci, const bellek_t *bellek) {
    printf("\033[H\033[1;32m");
    printf("╔══════════════════════════════════════════╗\n");
    printf("║    TÜRK-8 ETKİLEŞİMLİ CANLI BİLGİSAYAR   ║\n");
    printf("╠══════════════════════════════════════════╣\n");

    for (int y = 0; y < EKRAN_YUKSEKLIK; y++) {
        printf("║");
        for (int x = 0; x < EKRAN_GENISLIK; x++) {
            kelime_t ofset = (kelime_t)(y * EKRAN_GENISLIK + x);
            bayt_t c = bellek->veri[ADRES_VRAM_BAS + ofset];
            if (c >= 32 && c <= 126) {
                putchar(c);
            } else if (c == 0) {
                putchar(' ');
            } else {
                putchar('.');
            }
        }
        printf("║\n");
    }

    printf("╠══════════════════════════════════════════╣\n");
    printf("║ T: 0x%02X (%3d) | X: 0x%02X | Y: 0x%02X        ║\n",
           islemci->T, islemci->T, islemci->X, islemci->Y);
    printf("║ PS: 0x%04X | YG: 0x%02X | Çevrim: %-8llu ║\n",
           islemci->PS, islemci->YG, (unsigned long long)islemci->toplam_cevrim);
    printf("║ [ESC: Çıkış]  [Klavyeden yazı yazın...]  ║\n");
    printf("╚══════════════════════════════════════════╝\033[0m\n");
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
        /* 1. Klavyeden tuş kontrolü (non-blocking) */
#ifdef _WIN32
        if (_kbhit()) {
            char tus = (char)_getch();
            if (tus == 27) break;
            if (tus == '\r') tus = '\n';
            bellek_klavye_tusu_gonder(bellek, (bayt_t)tus);
        }
#else
        char tus = 0;
        if (read(STDIN_FILENO, &tus, 1) > 0) {
            if (tus == 27) { /* ESC */
                break;
            }
            if (tus == '\r') tus = '\n';
            bellek_klavye_tusu_gonder(bellek, (bayt_t)tus);
        }
#endif

        /* 2. İşlemciyi çalıştır (Her karede 200 komut döngüsü) */
        for (int i = 0; i < 200 && !islemci->durdu; i++) {
            islemci_tek_adim(islemci);
        }

        /* 3. Ekranı yenile */
        canli_arayuz_ciz(islemci, bellek);

        /* 4. ~50 FPS için 20 ms bekle */
        BEKLE_MS(20);
    }

    terminal_eski_hale_getir();
    printf("\n[SİSTEM] Canlı ekran modundan çıkıldı.\n");
}
