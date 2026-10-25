# -*- coding: utf-8 -*-
"""
Faz 5 — Sanal Disk (disk.t8), araclar/disk.py ve ROM Kabuğu Disk Komutları Testleri.

Doğrulananlar:
- araclar/disk.py: imaj oluşturma, dosya ekleme (.asm/.rom), listeleme, çıkarma, silme
- Emülatör disk denetleyicisi (0xA010 - 0xA017): sektör okuma (1), sektör yazma (2), durum (3)
- ROM kabuğunda LİSTE, YÜKLE <ad>, ÇALIŞTIR <ad>, KAYDET <ad> [adres] [boyut], SİL <ad>
- Kaydet -> yeniden başlat -> yükle / çalıştır kalıcılık döngüsü
- Varsayılan disk.t8 içinden PONG ve MERHABA açılışı
"""

import tempfile
import unittest
from pathlib import Path

from araclar import disk
from yardimci import KOK, TurkTestCase, calistir, calistir_bios


class TestFaz5Disk(TurkTestCase):

    def test_disk_py_olustur_ekle_cikar_sil(self):
        """araclar/disk.py ile disk imajı oluşturma, dosya ekleme, çıkarma ve silme çalışır."""
        imaj = disk.bos_imaj_olustur()
        self.assertEqual(len(imaj), 65536)
        self.assertEqual(disk.dizin_oku(imaj), [])

        disk.dosya_ekle(imaj, "merhaba", b"\x10\x2A\x01", yukle_adresi=0x0200)
        disk.dosya_ekle(imaj, "ikinci", b"\xAA" * 300, yukle_adresi=0x0400)

        girisler = disk.dizin_oku(imaj)
        self.assertEqual(len(girisler), 2)
        self.assertEqual(girisler[0]["ad"], "MERHABA")
        self.assertEqual(girisler[0]["baslangic"], 1)
        self.assertEqual(girisler[0]["sektor_sayisi"], 1)
        self.assertEqual(girisler[0]["adres"], 0x0200)
        self.assertEqual(girisler[0]["boyut"], 3)

        self.assertEqual(girisler[1]["ad"], "IKINCI")
        self.assertEqual(girisler[1]["baslangic"], 2)
        self.assertEqual(girisler[1]["sektor_sayisi"], 2)
        self.assertEqual(girisler[1]["adres"], 0x0400)
        self.assertEqual(girisler[1]["boyut"], 300)

        veri, bilgi = disk.dosya_cikar(imaj, "merhaba")
        self.assertEqual(veri, b"\x10\x2A\x01")
        self.assertEqual(bilgi["adres"], 0x0200)

        self.assertTrue(disk.dosya_sil(imaj, "MERHABA"))
        self.assertEqual(len(disk.dizin_oku(imaj)), 1)

    def test_varsayilan_disk_liste_ve_calistir_merhaba_pong(self):
        """Varsayılan disk.t8 imajında LİSTE komutu ve ÇALIŞTIR MERHABA / ÇALIŞTIR PONG çalışır."""
        s_liste = calistir_bios(max_cevrim=250000, ekran=True, girdi="LİSTE\n")
        ekran_liste = s_liste.ekran_metni()
        self.assertIn("DOSYA    ADRES   BOYUT", ekran_liste)
        self.assertIn("MERHABA  0x0200  001 SEKTÖR", ekran_liste)
        self.assertIn("TOPLAM   0x0200  001 SEKTÖR", ekran_liste)
        self.assertIn("PONG     0x0200  003 SEKTÖR", ekran_liste)

        # Kabuktan doğrudan doğal Türkçe (SOV) sırayla 'MERHABA ÇALIŞTIR'
        s_merhaba = calistir_bios(max_cevrim=200000, ekran=True, girdi="MERHABA ÇALIŞTIR\n")
        self.assertBitti(s_merhaba)
        self.assertIn("MERHABA DUNYA! TURK-8 CALISIYOR.", s_merhaba.ekran_metni())

        # Kabuktan doğrudan 'PONG ÇALIŞTIR'
        s_pong = calistir_bios(max_cevrim=250000, ekran=True, girdi="PONG ÇALIŞTIR\n")
        self.assertIn("== TURK-8 PONG ==", s_pong.ekran_metni())

    def test_kaydet_yeniden_baslat_yukle_calistir_ve_sil_dongusu(self):
        """Bellekteki bir programı KAYDET ile diske yazar, yeni oturumda YÜKLE/ÇALIŞTIR ile açar ve SİL ile siler."""
        with tempfile.TemporaryDirectory() as klasor:
            gecici_disk = Path(klasor) / "test_disk.t8"
            disk.imaj_kaydet(gecici_disk, disk.bos_imaj_olustur())

            # 1. Oturum: 0x0300 adresine küçük bir program yaz (0x77 T YÜKLE; T [0x0500] SAKLA; DÖN)
            # ve kabuktan 'KAYDET DENEME 0300 0100' komutunu ver
            s1 = calistir("""
                .BAŞLANGIÇ 0x0200
                0x10 T YÜKLE
                T [0x0300] SAKLA
                0x77 T YÜKLE
                T [0x0301] SAKLA
                0x15 T YÜKLE
                T [0x0302] SAKLA
                0x00 T YÜKLE
                T [0x0303] SAKLA
                0x05 T YÜKLE
                T [0x0304] SAKLA
                0x91 T YÜKLE
                T [0x0305] SAKLA

                [0xFFFC] ATLA
            """, max_cevrim=300000, ekran=True, girdi="DENEME 0300 KAYDET\n", disk=gecici_disk)
            self.assertIn("DİSKE KAYDEDİLDİ.", s1.ekran_metni())

            # Python tarafında da dizine gerçekten yazıldığını doğrula
            girisler = disk.dizin_oku(disk.imaj_yukle(gecici_disk))
            self.assertEqual(len(girisler), 1)
            self.assertEqual(girisler[0]["ad"], "DENEME")
            self.assertEqual(girisler[0]["adres"], 0x0300)

            # 2. Oturum (Yeniden Başlatma — RAM sıfırlanmış):
            # Kabuktan 'DENEME ÇALIŞTIR' yaz -> diskten 0x0300'e yükleyip çalıştırmalı ve 0x0500 = 0x77 olmalı
            s2 = calistir_bios(
                max_cevrim=250000,
                ekran=True,
                girdi="DENEME ÇALIŞTIR\n",
                disk=gecici_disk,
                dokum=[(0x0500, 1)],
            )
            self.assertEqual(s2.bellek(0x0500, 1), [0x77])

            # 3. Oturum: DENEME YÜKLE ve ardından DENEME SİL
            s3 = calistir_bios(
                max_cevrim=250000,
                ekran=True,
                girdi="DENEME YÜKLE\n",
                disk=gecici_disk,
                dokum=[(0x0300, 6)],
            )
            self.assertIn("YÜKLENDİ: 0x0300", s3.ekran_metni())
            self.assertEqual(s3.bellek(0x0300, 6), [0x10, 0x77, 0x15, 0x00, 0x05, 0x91])

            s4 = calistir_bios(
                max_cevrim=250000,
                ekran=True,
                girdi="DENEME SİL\nLİSTE\n",
                disk=gecici_disk,
            )
            ekran4 = s4.ekran_metni()
            self.assertIn("DOSYA SİLİNDİ.", ekran4)
            self.assertIn("(DİSK BOŞ)", ekran4)


if __name__ == "__main__":
    unittest.main()

