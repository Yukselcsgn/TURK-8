#ifndef KOMUTLAR_H
#define KOMUTLAR_H

/* TÜRK-8 İşlem Kodları (Opcodes) */
typedef enum {
    /* 1. Sistem ve Kontrol Grubu (0x00 - 0x0F) */
    KMT_BOS                 = 0x00, /* BOŞ: 1 saat vuruşu bekler (NOP) */
    KMT_DUR                 = 0x01, /* DUR: İşlemciyi durdurur (HALT) */
    KMT_KESME_AC            = 0x02, /* KESME AÇ: Kesmeleri etkinleştir */
    KMT_KESME_KAPAT         = 0x03, /* KESME KAPAT: Kesmeleri engelle */
    KMT_SIFIRLA             = 0x04, /* SIFIRLA: İşlemciyi resetle */

    /* 2. Veri Yükleme, Saklama ve Aktarma (0x10 - 0x2F) */
    KMT_YUKLE_SABIT_T       = 0x10, /* <sayı> T YÜKLE: Sabit sayıyı Toplaca koy */
    KMT_YUKLE_ADRES_T       = 0x11, /* [adres] T YÜKLE: Adresteki baytı T'ye al */
    KMT_YUKLE_INDEKS_X_T    = 0x12, /* [adres + X] T YÜKLE: X indeksli adresten T'ye al */
    KMT_YUKLE_SABIT_X       = 0x13, /* <sayı> X YÜKLE: Sabit sayıyı X'e koy */
    KMT_YUKLE_SABIT_Y       = 0x14, /* <sayı> Y YÜKLE: Sabit sayıyı Y'ye koy */
    KMT_SAKLA_T_ADRES       = 0x15, /* T [adres] SAKLA: T'yi adrese yaz */
    KMT_SAKLA_T_INDEKS_X    = 0x16, /* T [adres + X] SAKLA: T'yi X indeksli adrese yaz */
    KMT_SAKLA_X_ADRES       = 0x17, /* X [adres] SAKLA: X'i adrese yaz */
    KMT_SAKLA_Y_ADRES       = 0x18, /* Y [adres] SAKLA: Y'yi adrese yaz */
    KMT_AKTAR_X_T           = 0x19, /* X T AKTAR: X'i T'ye kopyala */
    KMT_AKTAR_T_X           = 0x1A, /* T X AKTAR: T'yi X'e kopyala */
    KMT_AKTAR_Y_T           = 0x1B, /* Y T AKTAR: Y'yi T'ye kopyala */
    KMT_AKTAR_T_Y           = 0x1C, /* T Y AKTAR: T'yi Y'ye kopyala */

    /* 3. Aritmetik ve Karşılaştırma (0x30 - 0x4F) */
    KMT_TOPLA_SABIT         = 0x30, /* <sayı> TOPLA: T = T + sayı */
    KMT_TOPLA_ADRES         = 0x31, /* [adres] TOPLA: T = T + [adres] */
    KMT_TOPLA_ELDEYLE       = 0x32, /* <sayı> ELDEYLE TOPLA: T = T + sayı + Elde */
    KMT_CIKAR_SABIT         = 0x33, /* <sayı> ÇIKAR: T = T - sayı */
    KMT_CIKAR_ADRES         = 0x34, /* [adres] ÇIKAR: T = T - [adres] */
    KMT_ARTIR_T             = 0x35, /* T ARTIR: T++ */
    KMT_ARTIR_X             = 0x36, /* X ARTIR: X++ */
    KMT_ARTIR_Y             = 0x37, /* Y ARTIR: Y++ */
    KMT_AZALT_T             = 0x38, /* T AZALT: T-- */
    KMT_AZALT_X             = 0x39, /* X AZALT: X-- */
    KMT_AZALT_Y             = 0x3A, /* Y AZALT: Y-- */
    KMT_KARSILASTIR_SABIT   = 0x3B, /* <sayı> KARŞILAŞTIR: T ile kıyasla */
    KMT_KARSILASTIR_X       = 0x3C, /* <sayı> X KARŞILAŞTIR: X ile kıyasla */

    /* 4. Mantık ve Bit İşlemleri (0x50 - 0x6F) */
    KMT_VE_SABIT            = 0x50, /* <sayı> VE: T = T & sayı */
    KMT_VEYA_SABIT          = 0x51, /* <sayı> VEYA: T = T | sayı */
    KMT_OZELVEYA_SABIT      = 0x52, /* <sayı> ÖZELVEYA: T = T ^ sayı */
    KMT_DEGILLE_T           = 0x53, /* T DEĞİLLE: T = ~T */
    KMT_KAYDIR_SOLA         = 0x54, /* T SOLA KAYDIR: T = T << 1 */
    KMT_KAYDIR_SAGA         = 0x55, /* T SAĞA KAYDIR: T = T >> 1 */

    /* 5. Akış Kontrolü ve Şartlı Atlamalar (0x70 - 0x8F) */
    KMT_ATLA                = 0x70, /* <hedef> ATLA: Koşulsuz atla */
    KMT_ESITSE_ATLA         = 0x71, /* <hedef> EŞİTSE ATLA: Sıfır bayrağı 1 ise atla */
    KMT_FARKLIYSA_ATLA      = 0x72, /* <hedef> FARKLIYSA ATLA: Sıfır bayrağı 0 ise atla */
    KMT_BUYUKSE_ATLA        = 0x73, /* <hedef> BÜYÜKSE ATLA: Sıfır=0 ve Negatif=0 ise */
    KMT_KUCUKSE_ATLA        = 0x74, /* <hedef> KÜÇÜKSE ATLA: Negatif=1 ise atla */
    KMT_ELDE_VARSA_ATLA     = 0x75, /* <hedef> ELDE VARSA ATLA: Elde bayrağı 1 ise atla */

    /* 6. Alt Programlar ve Yığın (Stack) (0x90 - 0xAF) */
    KMT_CAGIR               = 0x90, /* <fonksiyon> ÇAĞIR: Alt programa git (CALL) */
    KMT_DON                 = 0x91, /* DÖN: Alt programdan dön (RET) */
    KMT_KESMEDEN_DON        = 0x92, /* KESMEDEN DÖN: Kesmeden dön (RTI) */
    KMT_IT_T                = 0x93, /* T İT: Toplacı yığına it (PUSH T) */
    KMT_CEK_T               = 0x94, /* T ÇEK: Yığından Toplaca çek (POP T) */
    KMT_IT_DURUM            = 0x95, /* DURUM İT: Bayrakları yığına it (PUSH FLAGS) */
    KMT_CEK_DURUM           = 0x96, /* DURUM ÇEK: Bayrakları yığından çek (POP FLAGS) */

    /* 7. Giriş / Çıkış (I/O) (0xB0 - 0xBF) */
    KMT_GIRIS               = 0xB0, /* <port> GİRİŞ: Porttan T'ye oku */
    KMT_CIKIS               = 0xB1  /* <port> ÇIKIŞ: T'yi porta yaz */
} komut_kodu_t;

/* Komut hakkında bilgi veren yapı */
typedef struct {
    komut_kodu_t kod;
    const char  *turkce_ad;
    uint8_t      uzunluk_bayt; /* 1, 2 veya 3 bayt */
    uint8_t      saat_cevrimi; /* Çalışma süresi (cycle) */
} komut_bilgi_t;

const komut_bilgi_t* komut_bilgisi_al(bayt_t kod);

#endif /* KOMUTLAR_H */

