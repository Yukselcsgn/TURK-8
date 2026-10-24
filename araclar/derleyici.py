#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRK-8 İki Geçişli Türkçe Assembler (Çevirici)

Doğal Türkçe söz dizimine (Özne/Nesne -> Yüklem sonda) sahip .asm dosyalarını
TÜRK-8 ikili makine koduna (.rom) çevirir.

Komut seti araclar/isa.py tablosundan okunur (tek kaynak). Komut boyutları
tahmin edilmez, söz dizimi deseninden hesaplanır.

Direktifler:
    .BAŞLANGIÇ <adres>        Üretilecek kodun adresini belirler (.ORG)
    .METİN "metin"            Metni bayt olarak yerleştirir (\\n \\t \\0 \\\\ \\" desteklenir)
    .BAYT a, b, "dizge", ...  Bayt listesi
    .KELİME a, b, ...         16 bitlik değerler (küçük uçlu)
    .BOŞLUK <n>               n adet sıfır bayt ayırır (tampon bellek için)
    .TANIM ad değer           Adlandırılmış sabit (kullanımdan önce tanımlanmalı)
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import isa  # noqa: E402

VARSAYILAN_BASLANGIC = 0x0200

_ETIKET_RE = re.compile(r"^\s*([^\s:\"';\[\]+]+)\s*:")
_TANIMLAYICI_RE = re.compile(r"^[^\W\d]\w*$")


class DerlemeHatasi(Exception):
    """Bir ya da birden çok derleme hatasını taşır."""

    def __init__(self, hatalar):
        # hatalar: [(satır_no, mesaj, ham_satır), ...]
        super().__init__("; ".join("satır %d: %s" % (n, m) for n, m, _ in hatalar))
        self.hatalar = hatalar


class _SatirHatasi(Exception):
    pass


def yorumu_at(satir):
    """Tırnak içindeki ';' karakterlerini koruyarak satır sonu yorumunu siler."""
    cift = tek = False
    i = 0
    while i < len(satir):
        c = satir[i]
        if c == "\\" and cift:
            i += 2
            continue
        if c == '"' and not tek:
            cift = not cift
        elif c == "'" and not cift:
            tek = not tek
        elif c == ";" and not cift and not tek:
            return satir[:i]
        i += 1
    return satir


def virgulle_ayir(metin):
    """Tırnak dışındaki virgüllerden böler."""
    parcalar, tampon = [], []
    cift = tek = False
    i = 0
    while i < len(metin):
        c = metin[i]
        if c == "\\" and cift:
            tampon.append(c)
            if i + 1 < len(metin):
                tampon.append(metin[i + 1])
            i += 2
            continue
        if c == '"' and not tek:
            cift = not cift
        elif c == "'" and not cift:
            tek = not tek
        if c == "," and not cift and not tek:
            parcalar.append("".join(tampon).strip())
            tampon = []
        else:
            tampon.append(c)
        i += 1
    parcalar.append("".join(tampon).strip())
    return parcalar


_KACIS = {"n": 10, "t": 9, "r": 13, "0": 0, "\\": 92, '"': 34, "'": 39}


def _karakter_kodu(c):
    """Tek bir karakteri 8-bit ISO-8859-9 (Latin-5 Türkçe) bayt değerine çevirir."""
    try:
        return c.encode("iso-8859-9")[0]
    except UnicodeEncodeError:
        kod = ord(c)
        if kod <= 255:
            return kod
        raise _SatirHatasi("karakter 8 bite (ISO-8859-9) sığmıyor: '%s'" % c)


def dizge_coz(metin):
    """"..." biçimli dizgeyi bayt listesine çevirir."""
    metin = metin.strip()
    if len(metin) < 2 or metin[0] != '"' or metin[-1] != '"':
        raise _SatirHatasi("dizge çift tırnak içinde olmalı: %s" % metin)
    iclerik = metin[1:-1]
    baytlar = []
    i = 0
    while i < len(iclerik):
        c = iclerik[i]
        if c == "\\":
            i += 1
            if i >= len(iclerik) or iclerik[i] not in _KACIS:
                raise _SatirHatasi("geçersiz kaçış dizisi: \\%s" % (iclerik[i:i + 1],))
            baytlar.append(_KACIS[iclerik[i]])
        else:
            baytlar.append(_karakter_kodu(c))
        i += 1
    return baytlar


def sayi_coz(metin, semboller):
    """Sayı (10'luk, 0x/$ onaltılık, 0b ikili), 'c' karakteri, sabit ya da etiket.
    Başında '<' varsa 16-bit değerin alt baytını, '>' varsa üst baytını verir."""
    m = metin.strip()
    if m.startswith("#"):
        m = m[1:].strip()
    if m.startswith("<") and len(m) > 1:
        return sayi_coz(m[1:], semboller) & 0xFF
    if m.startswith(">") and len(m) > 1:
        return (sayi_coz(m[1:], semboller) >> 8) & 0xFF
    if len(m) == 3 and m[0] == "'" and m[2] == "'":
        return _karakter_kodu(m[1])
    try:
        alt = m.lower()
        if alt.startswith("0x"):
            return int(m[2:], 16)
        if alt.startswith("$"):
            return int(m[1:], 16)
        if alt.startswith("0b"):
            return int(m[2:], 2)
        return int(m, 10)
    except ValueError:
        pass
    if m in semboller:
        return semboller[m]
    raise _SatirHatasi("tanımsız etiket ya da geçersiz sayı: '%s'" % metin.strip())


def _bayt_degeri(deger, metin):
    if not -128 <= deger <= 255:
        raise _SatirHatasi("değer 8 bite sığmıyor (-128..255): %s = %d" % (metin, deger))
    return deger & 0xFF


def _adres_degeri(deger, metin):
    if not 0 <= deger <= 0xFFFF:
        raise _SatirHatasi("adres 16 bite sığmıyor (0..65535): %s = %d" % (metin, deger))
    return deger


def _direktif_adi(katli):
    return katli.split()[0]


def derle_ayrintili(kaynak_metin):
    """Kaynağı derler. (başlangıç_adresi, bayt_dizisi, liste) döndürür.

    liste: [(adres, bayt_listesi, kaynak_satırı), ...] — hata ayıklama içindir.
    Hata varsa DerlemeHatasi fırlatır (tüm hatalar toplu).
    """
    satirlar = kaynak_metin.splitlines()
    semboller = {}
    ogeler = []   # (adres, satir_no, ham, tip, veri)
    hatalar = []
    adres = VARSAYILAN_BASLANGIC

    # ---------------- 1. GEÇİŞ: boyutlar ve etiket adresleri ----------------
    for satir_no, ham in enumerate(satirlar, 1):
        try:
            satir = yorumu_at(ham).strip()

            while True:
                m = _ETIKET_RE.match(satir)
                if not m:
                    break
                ad = m.group(1)
                if not _TANIMLAYICI_RE.match(ad):
                    raise _SatirHatasi("geçersiz etiket adı: '%s'" % ad)
                if ad in semboller:
                    raise _SatirHatasi("etiket birden çok kez tanımlı: '%s'" % ad)
                semboller[ad] = adres
                satir = satir[m.end():].strip()

            if not satir:
                continue

            if satir.startswith("."):
                parcalar = satir.split(None, 1)
                ad = isa.katla(parcalar[0])
                arg = parcalar[1].strip() if len(parcalar) > 1 else ""

                if ad in (".BASLANGIC", ".ORG"):
                    if not arg:
                        raise _SatirHatasi("%s bir adres bekler" % parcalar[0])
                    adres = _adres_degeri(sayi_coz(arg, semboller), arg)
                elif ad in (".METIN", ".TEXT"):
                    baytlar = dizge_coz(arg)
                    ogeler.append((adres, satir_no, ham, "VERI", baytlar))
                    adres += len(baytlar)
                elif ad in (".BAYT", ".BYTE"):
                    if not arg:
                        raise _SatirHatasi("%s bir değer listesi bekler" % parcalar[0])
                    ogeler.append((adres, satir_no, ham, "BAYT", virgulle_ayir(arg)))
                    for oge in virgulle_ayir(arg):
                        adres += len(dizge_coz(oge)) if oge.startswith('"') else 1
                elif ad in (".KELIME", ".WORD"):
                    if not arg:
                        raise _SatirHatasi("%s bir değer listesi bekler" % parcalar[0])
                    liste = virgulle_ayir(arg)
                    ogeler.append((adres, satir_no, ham, "KELIME", liste))
                    adres += 2 * len(liste)
                elif ad in (".BOSLUK", ".RESERVE"):
                    n = sayi_coz(arg, semboller)
                    if not 0 <= n <= 0x10000:
                        raise _SatirHatasi(".BOŞLUK değeri 0..65536 olmalı: %d" % n)
                    ogeler.append((adres, satir_no, ham, "VERI", [0] * n))
                    adres += n
                elif ad in (".TANIM", ".EQU"):
                    kisimlar = arg.split(None, 1)
                    if len(kisimlar) != 2:
                        raise _SatirHatasi(".TANIM kullanımı: .TANIM ad değer")
                    sabit_ad, deger_metni = kisimlar
                    if not _TANIMLAYICI_RE.match(sabit_ad):
                        raise _SatirHatasi("geçersiz sabit adı: '%s'" % sabit_ad)
                    if sabit_ad in semboller:
                        raise _SatirHatasi("ad birden çok kez tanımlı: '%s'" % sabit_ad)
                    semboller[sabit_ad] = sayi_coz(deger_metni, semboller)
                else:
                    raise _SatirHatasi("bilinmeyen direktif: %s" % parcalar[0])

                if adres > 0x10000:
                    raise _SatirHatasi("program 64 KB bellek sınırını aşıyor")
                continue

            eslesmeler = isa.eslestir(satir)
            if not eslesmeler:
                raise _SatirHatasi("anlaşılamayan Türkçe söz dizimi: '%s'" % satir)
            if len(eslesmeler) > 1:
                adlar = ", ".join(k.ad for k, _ in eslesmeler)
                raise _SatirHatasi("belirsiz söz dizimi (%s): '%s'" % (adlar, satir))
            komut, islenen = eslesmeler[0]
            ogeler.append((adres, satir_no, ham, "KOMUT", (komut, islenen)))
            adres += komut.boyut
            if adres > 0x10000:
                raise _SatirHatasi("program 64 KB bellek sınırını aşıyor")

        except _SatirHatasi as e:
            hatalar.append((satir_no, str(e), ham))

    if hatalar:
        raise DerlemeHatasi(hatalar)

    # ---------------- 2. GEÇİŞ: makine kodunu üret ----------------
    parcalar = []   # (adres, bayt_listesi, ham)
    for oge_adres, satir_no, ham, tip, veri in ogeler:
        try:
            if tip == "VERI":
                baytlar = list(veri)
            elif tip == "BAYT":
                baytlar = []
                for oge in veri:
                    if oge.startswith('"'):
                        baytlar.extend(dizge_coz(oge))
                    else:
                        baytlar.append(_bayt_degeri(sayi_coz(oge, semboller), oge))
            elif tip == "KELIME":
                baytlar = []
                for oge in veri:
                    deger = sayi_coz(oge, semboller)
                    if not -32768 <= deger <= 0xFFFF:
                        raise _SatirHatasi("değer 16 bite sığmıyor: %s = %d" % (oge, deger))
                    deger &= 0xFFFF
                    baytlar.extend([deger & 0xFF, deger >> 8])
            else:  # KOMUT
                komut, islenen = veri
                baytlar = [komut.opkod]
                if komut.islenenler:
                    deger = sayi_coz(islenen, semboller)
                    if komut.islenenler[0] == "N":
                        baytlar.append(_bayt_degeri(deger, islenen))
                    else:
                        deger = _adres_degeri(deger, islenen)
                        baytlar.extend([deger & 0xFF, deger >> 8])
            parcalar.append((oge_adres, baytlar, ham))
        except _SatirHatasi as e:
            hatalar.append((satir_no, str(e), ham))

    if hatalar:
        raise DerlemeHatasi(hatalar)

    if not parcalar:
        return VARSAYILAN_BASLANGIC, bytearray(), []

    # Parçaları adres sırasıyla birleştir; aradaki boşluk sıfırla dolar.
    sirali_parcalar = sorted(enumerate(parcalar), key=lambda x: (x[1][0], x[0]))
    baslangic = sirali_parcalar[0][1][0]
    imaj = bytearray()
    for _, (oge_adres, baytlar, ham) in sirali_parcalar:
        konum = oge_adres - baslangic
        if konum < len(imaj):
            satir_no = next(n for a, n, h, t, v in ogeler if a == oge_adres and h == ham)
            raise DerlemeHatasi([(satir_no,
                                  "kod parçaları çakışıyor (0x%04X)" % oge_adres,
                                  ham)])
        imaj.extend(b"\x00" * (konum - len(imaj)))
        imaj.extend(baytlar)

    return baslangic, imaj, [p for _, p in sirali_parcalar]


def derle(kaynak_metin):
    """(başlangıç_adresi, bayt_dizisi) döndürür."""
    baslangic, imaj, _ = derle_ayrintili(kaynak_metin)
    return baslangic, imaj


def liste_yazdir(parcalar, cikti=sys.stdout):
    for adres, baytlar, ham in parcalar:
        for ofset in range(0, max(len(baytlar), 1), 4):
            dilim = baytlar[ofset:ofset + 4]
            hex_metni = " ".join("%02X" % b for b in dilim)
            if ofset == 0:
                cikti.write("%04X  %-11s %s\n" % (adres, hex_metni, ham.rstrip()))
            else:
                cikti.write("%04X  %s\n" % (adres + ofset, hex_metni))


def main(argv=None):
    ap = argparse.ArgumentParser(description="TÜRK-8 Türkçe Assembler")
    ap.add_argument("kaynak", help="kaynak .asm dosyası")
    ap.add_argument("hedef", nargs="?", help="çıktı .rom dosyası (varsayılan: kaynak adı + .rom)")
    ap.add_argument("-l", "--liste", action="store_true", help="adres/bayt/kaynak listesini yazdır")
    args = ap.parse_args(argv)

    hedef = args.hedef or args.kaynak.rsplit(".", 1)[0] + ".rom"

    try:
        with open(args.kaynak, "r", encoding="utf-8") as f:
            kaynak = f.read()
    except OSError as e:
        print("[HATA] %s" % e, file=sys.stderr)
        return 1

    try:
        baslangic, imaj, parcalar = derle_ayrintili(kaynak)
    except DerlemeHatasi as e:
        for satir_no, mesaj, ham in e.hatalar:
            print("[HATA] %s satır %d: %s" % (args.kaynak, satir_no, mesaj), file=sys.stderr)
            print("       %s" % ham.strip(), file=sys.stderr)
        print("[HATA] %d hata, derleme durduruldu." % len(e.hatalar), file=sys.stderr)
        return 1

    if args.liste:
        liste_yazdir(parcalar)

    with open(hedef, "wb") as f:
        f.write(imaj)
    print("[BAŞARILI] '%s' derlendi -> '%s'" % (args.kaynak, hedef))
    print("[BİLGİ] Başlangıç Adresi: 0x%04X, Toplam Boyut: %d bayt" % (baslangic, len(imaj)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
