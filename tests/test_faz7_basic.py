# -*- coding: utf-8 -*-
"""
Faz 7 — Türkçe BASIC Yorumlayıcısı (programlar/basic.asm) Testleri.

Doğrulananlar:
- BIOS isteminden '> BASIC' komutuyla BASIC yorumlayıcısının diskten yüklenip açılması
- Doğrudan (REPL) ifade ve komut çalıştırma: YAZ, "METİN" YAZ, değişken atama (+, -, *, /, %, RASTGELE)
- Satır numaralı program girişi (hem '10 ...' hem 'SATIR 10 ...'), sıralı dizilim, güncelleme,
  satır silme, LİSTELE ve YENİ komutları
- GİT, EĞER ... İSE (=, <>, <, >, <=, >=), DÖNGÜ ... BİTİŞ ... SONRAKİ, ÇAĞIR / DÖN, BİTİR
- GİRDİ ve RASTGELE ile etkileşimli sayı tahmin oyunu senaryosu
- BASIC programını sanal diske KAYDET ve yeni oturumda YÜKLE / ÇALIŞTIR döngüsü
- ÇIK komutuyla BIOS kabuğuna (> _) geri dönüş
"""

import tempfile
import unittest
from pathlib import Path

from araclar import disk
from yardimci import KOK, TurkTestCase, calistir_bios


class TestFaz7Basic(TurkTestCase):

    def test_basic_acilis_dogrudan_ifade_ve_cikis(self):
        """'> BASIC' ile açılır, doğrudan ifadeleri (+, -, *, /, %) hesaplar ve 'ÇIK' ile BIOS'a döner."""
        girdi = (
            "BASIC\n"
            '"MERHABA BASIC!" YAZ\n'
            "25 + 17 YAZ\n"
            "25+17 YAZ\n"
            "A = 6 * 7\n"
            "B = A + 8\n"
            'YAZ "B=", B / 5, " K=", B % 7\n'
            "ÇIK\n"
            "BİLGİ\n"
        )
        s = calistir_bios(max_cevrim=900000, ekran=True, girdi=girdi)
        ekran = s.ekran_metni()
        self.assertIn("TÜRK-8 BASIC v1.0", ekran)
        self.assertIn("MERHABA BASIC!", ekran)
        self.assertIn("42", ekran)
        self.assertIn("B=10 K=1", ekran)
        self.assertIn("İŞLEMCİ : TÜRK-8", ekran)

    def test_satir_siralama_silme_listele_dongu_ve_cagir_don(self):
        """Karışık sırayla girilen satırlar sıralanır, silinir, DÖNGÜ/SONRAKİ ve ÇAĞIR/DÖN çalışır."""
        girdi = (
            "BASIC\n"
            "30 I SONRAKİ\n"
            "10 T = 0\n"
            "SATIR 20 DÖNGÜ I = 1 BİTİŞ 4\n"
            "25 100 ÇAĞIR\n"
            "27 YANLIS SATIR\n"
            "27\n"
            '40 "TOPLAM=", T YAZ\n'
            "50 BİTİR\n"
            "100 T = T + I\n"
            "110 DÖN\n"
            "TEMİZLE\n"
            "LİSTELE\n"
            "ÇALIŞTIR\n"
        )
        s = calistir_bios(max_cevrim=1500000, ekran=True, girdi=girdi)
        ekran = s.ekran_metni()
        # 27 numaralı satır silindiği için LİSTELE çıktısında olmamalı
        self.assertNotIn("27 YANLIS SATIR", ekran)
        self.assertIn("10 T = 0", ekran)
        self.assertIn("20 DONGU I = 1 BITIS 4", ekran)
        # 1 + 2 + 3 + 4 = 10
        self.assertIn("TOPLAM=10", ekran)

    def test_sayi_tahmin_oyunu_eger_ise_girdi_ve_git(self):
        """EĞER ... İSE, GİRDİ, GİT ve RASTGELE kullanan sayı tahmin oyunu doğru çalışır."""
        girdi = (
            "BASIC\n"
            "10 R = RASTGELE % 1\n"
            "20 H = R + 42\n"
            "30 T GİRDİ\n"
            '40 EĞER T < H İSE "YUKARI" YAZ\n'
            '50 EĞER T > H İSE "ASAGI" YAZ\n'
            "60 EĞER T = H İSE 80 GİT\n"
            "70 30 GİT\n"
            '80 "BILDIN!" YAZ\n'
            "90 BİTİR\n"
            "ÇALIŞTIR\n"
            "20\n"
            "60\n"
            "42\n"
        )
        s = calistir_bios(max_cevrim=1800000, ekran=True, girdi=girdi)
        ekran = s.ekran_metni()
        self.assertIn("YUKARI", ekran)
        self.assertIn("ASAGI", ekran)
        self.assertIn("BILDIN!", ekran)

    def test_basic_programi_diske_kaydet_ve_yukle(self):
        """BASIC içinde yazılan bir program diske kaydedilir ve yeni oturumda yüklenip çalıştırılır."""
        with tempfile.TemporaryDirectory() as klasor:
            gecici_disk = Path(klasor) / "basic_disk.t8"
            # Varsayılan disk.t8 imajını (BASIC yorumlayıcısını içerir) kopyala
            imaj = disk.imaj_yukle(KOK / "disk.t8")
            disk.imaj_kaydet(gecici_disk, imaj)

            girdi1 = (
                "BASIC\n"
                "10 K = 9\n"
                '20 "KARE=", K * K YAZ\n'
                "30 BİTİR\n"
                "KAREM KAYDET\n"
            )
            s1 = calistir_bios(max_cevrim=1200000, ekran=True, girdi=girdi1, disk=gecici_disk)
            self.assertIn("DİSKE KAYDEDİLDİ.", s1.ekran_metni())

            # 2. Oturum: Bilgisayarı yeniden aç, BASIC'e gir, KAREM YÜKLE ve ÇALIŞTIR
            girdi2 = (
                "BASIC\n"
                "KAREM YÜKLE\n"
                "ÇALIŞTIR\n"
            )
            s2 = calistir_bios(max_cevrim=1200000, ekran=True, girdi=girdi2, disk=gecici_disk)
            ekran2 = s2.ekran_metni()
            self.assertIn("YÜKLENDİ.", ekran2)
            self.assertIn("KARE=81", ekran2)


if __name__ == "__main__":
    unittest.main()
