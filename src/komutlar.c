#include "turk8_tanimlar.h"
#include "komutlar.h"

static const komut_bilgi_t BILINMEYEN_KOMUT = {
    .kod = 0,
    .turkce_ad = "BILINMEYEN",
    .uzunluk_bayt = 1,
    .saat_cevrimi = 1
};

static const komut_bilgi_t KOMUT_TABLOSU[256] = {
    [KMT_BOS]              = { KMT_BOS,              "BOŞ",                  1, 1 },
    [KMT_DUR]              = { KMT_DUR,              "DUR",                  1, 1 },
    [KMT_KESME_AC]         = { KMT_KESME_AC,         "KESME AÇ",             1, 1 },
    [KMT_KESME_KAPAT]      = { KMT_KESME_KAPAT,      "KESME KAPAT",          1, 1 },
    [KMT_SIFIRLA]          = { KMT_SIFIRLA,          "SIFIRLA",              1, 2 },

    [KMT_YUKLE_SABIT_T]    = { KMT_YUKLE_SABIT_T,    "<sayı> T YÜKLE",       2, 2 },
    [KMT_YUKLE_ADRES_T]    = { KMT_YUKLE_ADRES_T,    "[adres] T YÜKLE",      3, 4 },
    [KMT_YUKLE_INDEKS_X_T] = { KMT_YUKLE_INDEKS_X_T, "[adres + X] T YÜKLE", 3, 4 },
    [KMT_YUKLE_SABIT_X]    = { KMT_YUKLE_SABIT_X,    "<sayı> X YÜKLE",       2, 2 },
    [KMT_YUKLE_SABIT_Y]    = { KMT_YUKLE_SABIT_Y,    "<sayı> Y YÜKLE",       2, 2 },
    [KMT_SAKLA_T_ADRES]    = { KMT_SAKLA_T_ADRES,    "T [adres] SAKLA",      3, 4 },
    [KMT_SAKLA_T_INDEKS_X] = { KMT_SAKLA_T_INDEKS_X, "T [adres + X] SAKLA", 3, 5 },
    [KMT_SAKLA_X_ADRES]    = { KMT_SAKLA_X_ADRES,    "X [adres] SAKLA",      3, 4 },
    [KMT_SAKLA_Y_ADRES]    = { KMT_SAKLA_Y_ADRES,    "Y [adres] SAKLA",      3, 4 },
    [KMT_AKTAR_X_T]        = { KMT_AKTAR_X_T,        "X T AKTAR",            1, 1 },
    [KMT_AKTAR_T_X]        = { KMT_AKTAR_T_X,        "T X AKTAR",            1, 1 },
    [KMT_AKTAR_Y_T]        = { KMT_AKTAR_Y_T,        "Y T AKTAR",            1, 1 },
    [KMT_AKTAR_T_Y]        = { KMT_AKTAR_T_Y,        "T Y AKTAR",            1, 1 },
    [KMT_YUKLE_DOLAYLI_T]  = { KMT_YUKLE_DOLAYLI_T,  "[[isaretci]] T YÜKLE", 3, 5 },
    [KMT_SAKLA_T_DOLAYLI]  = { KMT_SAKLA_T_DOLAYLI,  "T [[isaretci]] SAKLA", 3, 5 },

    [KMT_TOPLA_SABIT]      = { KMT_TOPLA_SABIT,      "<sayı> TOPLA",         2, 2 },
    [KMT_TOPLA_ADRES]      = { KMT_TOPLA_ADRES,      "[adres] TOPLA",        3, 4 },
    [KMT_TOPLA_ELDEYLE]    = { KMT_TOPLA_ELDEYLE,    "<sayı> ELDEYLE TOPLA", 2, 2 },
    [KMT_CIKAR_SABIT]      = { KMT_CIKAR_SABIT,      "<sayı> ÇIKAR",         2, 2 },
    [KMT_CIKAR_ADRES]      = { KMT_CIKAR_ADRES,      "[adres] ÇIKAR",        3, 4 },
    [KMT_ARTIR_T]          = { KMT_ARTIR_T,          "T ARTIR",              1, 1 },
    [KMT_ARTIR_X]          = { KMT_ARTIR_X,          "X ARTIR",              1, 1 },
    [KMT_ARTIR_Y]          = { KMT_ARTIR_Y,          "Y ARTIR",              1, 1 },
    [KMT_AZALT_T]          = { KMT_AZALT_T,          "T AZALT",              1, 1 },
    [KMT_AZALT_X]          = { KMT_AZALT_X,          "X AZALT",              1, 1 },
    [KMT_AZALT_Y]          = { KMT_AZALT_Y,          "Y AZALT",              1, 1 },
    [KMT_KARSILASTIR_SABIT]= { KMT_KARSILASTIR_SABIT,"<sayı> KARŞILAŞTIR",   2, 2 },
    [KMT_KARSILASTIR_X]    = { KMT_KARSILASTIR_X,    "<sayı> X KARŞILAŞTIR", 2, 2 },

    [KMT_VE_SABIT]         = { KMT_VE_SABIT,         "<sayı> VE",            2, 2 },
    [KMT_VEYA_SABIT]       = { KMT_VEYA_SABIT,       "<sayı> VEYA",          2, 2 },
    [KMT_OZELVEYA_SABIT]   = { KMT_OZELVEYA_SABIT,   "<sayı> ÖZELVEYA",      2, 2 },
    [KMT_DEGILLE_T]        = { KMT_DEGILLE_T,        "T DEĞİLLE",            1, 1 },
    [KMT_KAYDIR_SOLA]      = { KMT_KAYDIR_SOLA,      "T SOLA KAYDIR",        1, 1 },
    [KMT_KAYDIR_SAGA]      = { KMT_KAYDIR_SAGA,      "T SAĞA KAYDIR",        1, 1 },

    [KMT_ATLA]             = { KMT_ATLA,             "<hedef> ATLA",         3, 3 },
    [KMT_ESITSE_ATLA]      = { KMT_ESITSE_ATLA,      "<hedef> EŞİTSE ATLA",  3, 3 },
    [KMT_FARKLIYSA_ATLA]   = { KMT_FARKLIYSA_ATLA,   "<hedef> FARKLIYSA ATLA", 3, 3 },
    [KMT_BUYUKSE_ATLA]     = { KMT_BUYUKSE_ATLA,     "<hedef> BÜYÜKSE ATLA", 3, 3 },
    [KMT_KUCUKSE_ATLA]     = { KMT_KUCUKSE_ATLA,     "<hedef> KÜÇÜKSE ATLA", 3, 3 },
    [KMT_ELDE_VARSA_ATLA]  = { KMT_ELDE_VARSA_ATLA,  "<hedef> ELDE VARSA ATLA", 3, 3 },

    [KMT_CAGIR]            = { KMT_CAGIR,            "<hedef> ÇAĞIR",        3, 6 },
    [KMT_DON]              = { KMT_DON,              "DÖN",                  1, 4 },
    [KMT_KESMEDEN_DON]     = { KMT_KESMEDEN_DON,     "KESMEDEN DÖN",         1, 4 },
    [KMT_IT_T]             = { KMT_IT_T,             "T İT",                 1, 3 },
    [KMT_CEK_T]            = { KMT_CEK_T,            "T ÇEK",                1, 4 },
    [KMT_IT_DURUM]         = { KMT_IT_DURUM,         "DURUM İT",             1, 3 },
    [KMT_CEK_DURUM]        = { KMT_CEK_DURUM,        "DURUM ÇEK",            1, 4 },

    [KMT_GIRIS]            = { KMT_GIRIS,            "<port> GİRİŞ",         2, 2 },
    [KMT_CIKIS]            = { KMT_CIKIS,            "<port> ÇIKIŞ",         2, 2 }
};

const komut_bilgi_t* komut_bilgisi_al(bayt_t kod) {
    if (KOMUT_TABLOSU[kod].turkce_ad != NULL) {
        return &KOMUT_TABLOSU[kod];
    }
    return &BILINMEYEN_KOMUT;
}

