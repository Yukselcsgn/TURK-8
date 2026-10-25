# -*- coding: utf-8 -*-
"""
TÜRK-8 test yardımcıları.

calistir()  : Türkçe assembly metnini derler, emülatörü başsız (--test) çalıştırır
              ve sonucu Sonuc nesnesi olarak döndürür.
calistir_rom: Hazır bir .rom dosyası için aynısı.
"""

import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(KOK / "araclar"))

import derleyici  # noqa: E402
import isa  # noqa: E402,F401

EMULATOR = KOK / ("turk8.exe" if os.name == "nt" else "turk8")

BAYRAKLAR = {"E": 0x01, "S": 0x02, "K": 0x04, "N": 0x08, "T": 0x10}

CIKIS_TAMAM = 0
CIKIS_TEST_HATASI = 1
CIKIS_ISLEMCI_HATA = 2
CIKIS_ZAMAN_ASIMI = 3
CIKIS_ARGUMAN = 4


class Sonuc:
    """Emülatörün test modu çıktısının ayrıştırılmış hali."""

    def __init__(self, cikis_kodu, stdout, stderr):
        self.cikis_kodu = cikis_kodu
        self.stdout = stdout
        self.stderr = stderr

        self.neden = None
        self.test_kodu = None
        self.T = self.X = self.Y = self.YG = self.PS = self.DURUM = None
        self.cevrim = None
        self.zaman = self.ses_frekans = self.ses_sure = self.ses_sayisi = None
        self.fifo_sayi = None
        self.fifo_tasti = False
        self.bellek_dokumleri = {}
        self.ekran_satirlari = []

        # Programın kendi terminal çıktısı: ilk "T8:" satırından önceki kısım.
        ilk = stdout.find("\nT8:")
        self.terminal = stdout if ilk < 0 else stdout[:ilk]

        for satir in stdout.splitlines():
            if satir.startswith("T8:| "):
                self.ekran_satirlari.append(satir[5:])
                continue
            if satir == "T8:|":
                self.ekran_satirlari.append("")
                continue
            if not satir.startswith("T8:"):
                continue
            kisim = satir[3:]
            if kisim.startswith("DURUM "):
                self.neden = kisim[6:].strip()
            elif kisim.startswith("TEST_KODU "):
                self.test_kodu = int(kisim.split()[1], 16)
            elif kisim.startswith("SONUC "):
                degerler = dict(p.split("=") for p in kisim[6:].split())
                self.T = int(degerler["T"], 16)
                self.X = int(degerler["X"], 16)
                self.Y = int(degerler["Y"], 16)
                self.YG = int(degerler["YG"], 16)
                self.PS = int(degerler["PS"], 16)
                self.DURUM = int(degerler["DURUM"], 16)
                self.cevrim = int(degerler["CEVRIM"])
            elif kisim.startswith("DONANIM "):
                degerler = dict(p.split("=") for p in kisim[8:].split())
                self.zaman = int(degerler["ZAMAN"], 16)
                self.ses_frekans = int(degerler["SES_F"], 16)
                self.ses_sure = int(degerler["SES_S"], 16)
                self.ses_sayisi = int(degerler["SES_SAYI"])
                self.fifo_sayi = int(degerler["FIFO"])
                self.fifo_tasti = bool(int(degerler["TASTI"]))
            elif kisim.startswith("BELLEK "):
                parcalar = kisim.split()
                adres = int(parcalar[1], 16)
                self.bellek_dokumleri[adres] = [int(b, 16) for b in parcalar[2:]]

    def bayrak(self, ad):
        """Bayrak değerini (E, S, K, N, T) bool olarak verir."""
        return bool(self.DURUM & BAYRAKLAR[ad])

    def bayraklar(self):
        """Kurulu bayrakların harf dizisi, örn. 'ES'."""
        return "".join(ad for ad in "ESKNT" if self.bayrak(ad))

    def bellek(self, adres, uzunluk=1):
        """İstenen dökümden baytları verir (calistir(dokum=...) ile istenmiş olmalı)."""
        for baslangic, baytlar in self.bellek_dokumleri.items():
            if baslangic <= adres and adres + uzunluk <= baslangic + len(baytlar):
                ofset = adres - baslangic
                return baytlar[ofset:ofset + uzunluk]
        raise KeyError("0x%04X adresinden %d bayt dökülmemiş" % (adres, uzunluk))

    def ekran_metni(self):
        return "\n".join(self.ekran_satirlari)

    def __repr__(self):
        return ("Sonuc(cikis=%s neden=%s T=%02X X=%02X Y=%02X YG=%02X PS=%04X bayrak=%s)"
                % (self.cikis_kodu, self.neden, self.T or 0, self.X or 0, self.Y or 0,
                   self.YG or 0, self.PS or 0, self.bayraklar() if self.DURUM is not None else "?"))


def _emulatoru_hazirla():
    if not EMULATOR.exists():
        raise unittest.SkipTest(
            "%s bulunamadı; önce 'make' çalıştırın (ya da 'make test')" % EMULATOR.name)


def calistir_rom(rom_yolu=None, max_cevrim=200000, dokum=(), ekran=False, adres=None, girdi=None, disk=None, zaman_siniri=60):
    """Hazır .rom dosyasını (veya rom_yolu=None ise doğrudan BIOS ROM'u) başsız çalıştırır.

    dokum: [(adres, uzunluk), ...] bitişte dökülecek bellek aralıkları
    """
    _emulatoru_hazirla()
    komut = [str(EMULATOR), "--test", "--max-cevrim", str(max_cevrim)]
    if adres is not None:
        komut += ["--adres", "0x%04X" % adres]
    if disk is not None:
        komut += ["--disk", str(disk)]
    if girdi is not None:
        komut += ["--girdi", str(girdi)]
    for a, u in dokum:
        komut += ["--bellek-dokum", "0x%04X:%d" % (a, u)]
    if ekran:
        komut.append("--ekran-metin")
    if rom_yolu is not None:
        komut.append(str(rom_yolu))

    islem = subprocess.run(komut, capture_output=True, timeout=zaman_siniri)
    return Sonuc(islem.returncode,
                 islem.stdout.decode("utf-8", errors="replace"),
                 islem.stderr.decode("utf-8", errors="replace"))


def calistir_bios(max_cevrim=30000, dokum=(), ekran=True, girdi=None, disk=None):
    """Argümansız olarak doğrudan BIOS ROM'dan (0xFFFC vektörü) başsız başlatır."""
    return calistir_rom(None, max_cevrim=max_cevrim, dokum=dokum, ekran=ekran, girdi=girdi, disk=disk)


def derle_metin(kaynak, dur_ekle=True):
    """Türkçe assembly metnini derleyip ROM baytlarını verir.

    dur_ekle=True ise, program kendi DUR'unu yazmadıysa diye sona bir DUR eklenmez;
    bunun yerine kaynak olduğu gibi derlenir. (Testlerde açık DUR yazılır.)
    """
    _, imaj = derleyici.derle(kaynak)
    return bytes(imaj)


def calistir(kaynak, max_cevrim=200000, dokum=(), ekran=False, girdi=None, disk=None):
    """Assembly metnini derle + çalıştır. Başlangıç adresi 0x0200 olmalıdır.

    Programın sonuna DUR yazmayı unutmayın; zaman aşımı exit 3 verir.
    """
    _emulatoru_hazirla()
    baslangic, imaj = derleyici.derle(kaynak)
    if baslangic != 0x0200:
        raise ValueError("test programları 0x0200'de başlamalı (başlangıç: 0x%04X)" % baslangic)

    with tempfile.TemporaryDirectory() as klasor:
        yol = Path(klasor) / "test.rom"
        yol.write_bytes(bytes(imaj))
        return calistir_rom(yol, max_cevrim=max_cevrim, dokum=dokum, ekran=ekran, girdi=girdi, disk=disk)


class TurkTestCase(unittest.TestCase):
    """Ortak doğrulama yardımcıları."""

    def assertRegs(self, s, T=None, X=None, Y=None):
        if T is not None:
            self.assertEqual(s.T, T, "T beklenen %02X, gerçek %02X (%r)" % (T, s.T, s))
        if X is not None:
            self.assertEqual(s.X, X, "X beklenen %02X, gerçek %02X (%r)" % (X, s.X, s))
        if Y is not None:
            self.assertEqual(s.Y, Y, "Y beklenen %02X, gerçek %02X (%r)" % (Y, s.Y, s))

    def assertBayraklar(self, s, kurulu, kontrol="ESNT"):
        """'kontrol' içindeki bayraklardan yalnızca 'kurulu' olanların kurulu olduğunu doğrular.

        K (kesme) bayrağı varsayılan olarak kontrol edilmez.
        """
        gercek = "".join(b for b in kontrol if s.bayrak(b))
        beklenen = "".join(b for b in kontrol if b in kurulu)
        self.assertEqual(gercek, beklenen,
                         "bayraklar beklenen '%s', gerçek '%s' (%r)" % (beklenen, gercek, s))

    def assertBitti(self, s):
        self.assertEqual(s.neden, "bitti", "program DUR ile bitmedi: %r" % s)
        self.assertEqual(s.cikis_kodu, CIKIS_TAMAM)
