# -*- coding: utf-8 -*-
"""
TÜRK-8 komut seti tablosu (assembler için TEK KAYNAK).

Her komut bir söz dizimi deseniyle tanımlanır:
    {n}  -> 8 bitlik işlenen (1 bayt)
    {a}  -> 16 bitlik adres / hedef (2 bayt, küçük uçlu)

Komutun boyutu desenden türetilir (1 + işlenen baytları); elle tahmin edilmez.
Desen eşleştirme büyük/küçük harf ve Türkçe karakter (Ç, Ğ, İ, Ö, Ş, Ü)
duyarsızdır: "ÇIK" ile "cik" aynı kabul edilir. Adlar include/komutlar.h
içindeki KMT_* adlarıyla bire bir aynıdır; tutarlılık tests/ altında sınanır.
"""

import re

_KATLAMA = str.maketrans({
    'ç': 'C', 'Ç': 'C', 'ğ': 'G', 'Ğ': 'G', 'ı': 'I', 'İ': 'I', 'i': 'I',
    'ö': 'O', 'Ö': 'O', 'ş': 'S', 'Ş': 'S', 'ü': 'U', 'Ü': 'U',
})


def katla(metin):
    """Türkçe harfleri ASCII'ye katlayıp büyük harfe çevirir.

    Uzunluk her zaman korunur: konumlar özgün metinle birebir örtüşür.
    """
    sonuc = []
    for c in metin.translate(_KATLAMA):
        buyuk = c.upper()
        sonuc.append(buyuk if len(buyuk) == 1 else c)
    return "".join(sonuc)


# (opkod, C adı, söz dizimi deseni)
_HAM_TABLO = [
    # Sistem ve kontrol
    (0x00, "KMT_BOS",                "BOŞ"),
    (0x01, "KMT_DUR",                "DUR"),
    (0x02, "KMT_KESME_AC",           "KESME AÇ"),
    (0x03, "KMT_KESME_KAPAT",        "KESME KAPAT"),
    (0x04, "KMT_SIFIRLA",            "SIFIRLA"),

    # Veri yükleme, saklama, aktarma
    (0x10, "KMT_YUKLE_SABIT_T",      "{n} T YÜKLE"),
    (0x11, "KMT_YUKLE_ADRES_T",      "[{a}] T YÜKLE"),
    (0x12, "KMT_YUKLE_INDEKS_X_T",   "[{a} + X] T YÜKLE"),
    (0x13, "KMT_YUKLE_SABIT_X",      "{n} X YÜKLE"),
    (0x14, "KMT_YUKLE_SABIT_Y",      "{n} Y YÜKLE"),
    (0x15, "KMT_SAKLA_T_ADRES",      "T [{a}] SAKLA"),
    (0x16, "KMT_SAKLA_T_INDEKS_X",   "T [{a} + X] SAKLA"),
    (0x17, "KMT_SAKLA_X_ADRES",      "X [{a}] SAKLA"),
    (0x18, "KMT_SAKLA_Y_ADRES",      "Y [{a}] SAKLA"),
    (0x19, "KMT_AKTAR_X_T",          "X T AKTAR"),
    (0x1A, "KMT_AKTAR_T_X",          "T X AKTAR"),
    (0x1B, "KMT_AKTAR_Y_T",          "Y T AKTAR"),
    (0x1C, "KMT_AKTAR_T_Y",          "T Y AKTAR"),
    (0x1D, "KMT_YUKLE_DOLAYLI_T",    "[[{a}]] T YÜKLE"),
    (0x1E, "KMT_SAKLA_T_DOLAYLI",    "T [[{a}]] SAKLA"),

    # Aritmetik ve karşılaştırma
    (0x30, "KMT_TOPLA_SABIT",        "{n} TOPLA"),
    (0x31, "KMT_TOPLA_ADRES",        "[{a}] TOPLA"),
    (0x32, "KMT_TOPLA_ELDEYLE",      "{n} ELDEYLE TOPLA"),
    (0x33, "KMT_CIKAR_SABIT",        "{n} ÇIKAR"),
    (0x34, "KMT_CIKAR_ADRES",        "[{a}] ÇIKAR"),
    (0x35, "KMT_ARTIR_T",            "T ARTIR"),
    (0x36, "KMT_ARTIR_X",            "X ARTIR"),
    (0x37, "KMT_ARTIR_Y",            "Y ARTIR"),
    (0x38, "KMT_AZALT_T",            "T AZALT"),
    (0x39, "KMT_AZALT_X",            "X AZALT"),
    (0x3A, "KMT_AZALT_Y",            "Y AZALT"),
    (0x3B, "KMT_KARSILASTIR_SABIT",  "{n} KARŞILAŞTIR"),
    (0x3C, "KMT_KARSILASTIR_X",      "{n} X KARŞILAŞTIR"),

    # Mantık ve bit işlemleri
    (0x50, "KMT_VE_SABIT",           "{n} VE"),
    (0x51, "KMT_VEYA_SABIT",         "{n} VEYA"),
    (0x52, "KMT_OZELVEYA_SABIT",     "{n} ÖZELVEYA"),
    (0x53, "KMT_DEGILLE_T",          "T DEĞİLLE"),
    (0x54, "KMT_KAYDIR_SOLA",        "T SOLA KAYDIR"),
    (0x55, "KMT_KAYDIR_SAGA",        "T SAĞA KAYDIR"),

    # Akış kontrolü
    (0x70, "KMT_ATLA",               "{a} ATLA"),
    (0x71, "KMT_ESITSE_ATLA",        "{a} EŞİTSE ATLA"),
    (0x72, "KMT_FARKLIYSA_ATLA",     "{a} FARKLIYSA ATLA"),
    (0x73, "KMT_BUYUKSE_ATLA",       "{a} BÜYÜKSE ATLA"),
    (0x74, "KMT_KUCUKSE_ATLA",       "{a} KÜÇÜKSE ATLA"),
    (0x75, "KMT_ELDE_VARSA_ATLA",    "{a} ELDE VARSA ATLA"),

    # Alt programlar ve yığın
    (0x90, "KMT_CAGIR",              "{a} ÇAĞIR"),
    (0x91, "KMT_DON",                "DÖN"),
    (0x92, "KMT_KESMEDEN_DON",       "KESMEDEN DÖN"),
    (0x93, "KMT_IT_T",               "T İT"),
    (0x94, "KMT_CEK_T",              "T ÇEK"),
    (0x95, "KMT_IT_DURUM",           "DURUM İT"),
    (0x96, "KMT_CEK_DURUM",          "DURUM ÇEK"),

    # Giriş / çıkış
    (0xB0, "KMT_GIRIS",              "{n} GİRİŞ"),
    (0xB1, "KMT_CIKIS",              "{n} ÇIKIŞ"),
]

# İşlenen (sayı / adres / etiket) olarak kabul edilen metin: tek tırnaklı
# karakter ('A', ' ') ya da boşluk, köşeli parantez ve '+' içermeyen dizi.
_ISLENEN_RE = r"(?P<op>'.'|[^\s\[\]+]+)"


class Komut:
    """Tablodaki tek bir komut: opkod, ad, desen, boyut ve eşleştirme ifadesi."""

    def __init__(self, opkod, ad, desen):
        self.opkod = opkod
        self.ad = ad
        self.desen = desen
        # Katlanmış desende yer tutucular büyük harfli ({N}/{A}) olur.
        self.islenenler = re.findall(r"\{([NA])\}", katla(desen))
        self.boyut = 1 + sum(1 if t == "N" else 2 for t in self.islenenler)
        self._regex = re.compile(self._regex_olustur(desen))

    @staticmethod
    def _regex_olustur(desen):
        jetonlar = re.findall(
            r"\{N\}|\{A\}|\[\[|\]\]|\[|\]|\+|\s+|[^\s\[\]\+\{\}]+", katla(desen))
        parantez_veya_arti = {"[[", "]]", "[", "]", "+"}
        parcalar = []
        for sira, j in enumerate(jetonlar):
            if j in ("{N}", "{A}"):
                parcalar.append(_ISLENEN_RE)
            elif j == "[[":
                parcalar.append(r"\[\s*\[\s*")
            elif j == "]]":
                parcalar.append(r"\s*\]\s*\]")
            elif j == "[":
                parcalar.append(r"\[\s*")
            elif j == "]":
                parcalar.append(r"\s*\]")
            elif j == "+":
                parcalar.append(r"\s*\+\s*")
            elif j.isspace():
                onceki = jetonlar[sira - 1] if sira > 0 else ""
                sonraki = jetonlar[sira + 1] if sira + 1 < len(jetonlar) else ""
                if onceki in parantez_veya_arti or sonraki in parantez_veya_arti:
                    parcalar.append(r"\s*")
                else:
                    parcalar.append(r"\s+")
            else:
                parcalar.append(re.escape(j))
        return "".join(parcalar)

    def eslestir(self, katlanmis_satir):
        """Eşleşirse işlenenin (başlangıç, bitiş) konumunu, yoksa None döndürür.

        İşlenensiz komutlar için (0, 0) döner.
        """
        m = self._regex.fullmatch(katlanmis_satir)
        if not m:
            return None
        if "op" in m.groupdict() and m.group("op") is not None:
            return m.span("op")
        return (0, 0)

    def ornek(self, n="5", a="0x1234"):
        """Desenden örnek bir kaynak satırı üretir (testler için)."""
        return self.desen.replace("{n}", n).replace("{a}", a)


KOMUTLAR = [Komut(*satir) for satir in _HAM_TABLO]
OPKOD_TABLOSU = {k.opkod: k for k in KOMUTLAR}


def eslestir(satir):
    """Bir kaynak satırını tablodaki komutlarla eşleştirir.

    (komut, islenen_metni) çiftlerinin listesini döndürür. Doğru bir tabloda
    bir satır en fazla bir komutla eşleşir; birden fazlası belirsizlik demektir.
    """
    katli = katla(satir.strip())
    sonuclar = []
    for komut in KOMUTLAR:
        konum = komut.eslestir(katli)
        if konum is not None:
            # Konumlar katlanmış metne göre; katlama uzunluğu koruduğu için
            # özgün satırdan aynı aralık alınarak etiket büyük/küçük harfi korunur.
            baslangic, bitis = konum
            sonuclar.append((komut, satir.strip()[baslangic:bitis]))
    return sonuclar
