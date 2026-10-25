# -*- coding: utf-8 -*-
"""
Faz 6a ve 6b — Woz Tarzı Bellek Monitörü ve Etkileşimli Satır Assembler Testleri.

Doğrulananlar:
- Faz 6a (Woz Monitör):
  - '0300: 10 2A 15 00 04 91' komutuyla ardışık baytların 0x0300 adresine yazılması
  - '0300:' komutuyla tek satırlık (8 bayt) hızlı bellek dökümü
  - Yazılan makine kodunun '0300 ÇALIŞTIR' ile doğrudan çalıştırılması
- Faz 6b (Satır Assembler — [adres] KODLA):
  - '0300 KODLA' ile etkileşimli satır assembler kipine giriş ('0300 ? _')
  - Doğal Türkçe assembly satırlarının (örn. '2A T YÜKLE', 'T [0400] SAKLA', 'DÖN')
    makine koduna çevrilip belleğe yazılması ve adresin (0300 -> 0302 -> 0305 -> 0306) ilerlemesi
  - Boş satır ile çıkış, ardından '0300 ÇALIŞTIR' ve diske 'KAYDET' ile kalıcı kayıt
  - Karakter sabitleri ('A' T YÜKLE), indeksli ([0400 + X] T YÜKLE) ve dolaylı ([[0010] + Y] T YÜKLE)
    adresleme biçimlerinin doğru derlenmesi
  - Geçersiz söz diziminde 'SÖZ DİZİMİ HATASI!' verip aynı adreste kalması
"""

import tempfile
import unittest
from pathlib import Path

from araclar import disk
from yardimci import TurkTestCase, calistir_bios


class TestFaz6MonitorVeKodla(TurkTestCase):

    def test_faz6a_woz_monitor_bayt_giris_dokum_ve_calistir(self):
        """Woz tarzı '0300: 10 5A 15 00 04 91' girişi belleği doldurur, '0300:' döker ve '0300 ÇALIŞTIR' çalıştırır."""
        girdi = (
            "0300: 10 5A 15 00 04 91\n"
            "0300:\n"
            "0300 ÇALIŞTIR\n"
        )
        s = calistir_bios(
            max_cevrim=300000,
            ekran=True,
            girdi=girdi,
            dokum=[(0x0300, 6), (0x0400, 1)],
        )
        ekran = s.ekran_metni()
        self.assertEqual(s.bellek(0x0300, 6), [0x10, 0x5A, 0x15, 0x00, 0x04, 0x91])
        self.assertIn("0300: 10 5A 15 00 04 91", ekran)
        self.assertEqual(s.bellek(0x0400, 1), [0x5A])

    def test_faz6b_satir_assembler_kodla_calistir_ve_diske_kaydet(self):
        """'0300 KODLA' ile Türkçe assembly satırları derlenir, çalıştırılır ve diske kaydedilir."""
        with tempfile.TemporaryDirectory() as klasor:
            gecici_disk = Path(klasor) / "kodla_disk.t8"
            disk.imaj_kaydet(gecici_disk, disk.bos_imaj_olustur())

            # Makinenin içinde Türkçe assembly ile küçük bir program yaz:
            #   0300 ? 'K' T YÜKLE      -> 10 4B       (2 bayt)
            #   0302 ? T [0410] SAKLA   -> 15 10 04    (3 bayt)
            #   0305 ? 5 X YÜKLE        -> 13 05       (2 bayt)
            #   0307 ? X ARTIR          -> 36          (1 bayt)
            #   0308 ? X [0411] SAKLA   -> 17 11 04    (3 bayt)
            #   030B ? DÖN              -> 91          (1 bayt)
            #   030C ? (boş satır -> çıkış)
            girdi = (
                "0300 KODLA\n"
                "'K' T YÜKLE\n"
                "T [0410] SAKLA\n"
                "5 X YÜKLE\n"
                "X ARTIR\n"
                "X [0411] SAKLA\n"
                "DÖN\n"
                "\n"
                "0300 ÇALIŞTIR\n"
                "KODUM 0300 KAYDET\n"
            )
            s1 = calistir_bios(
                max_cevrim=600000,
                ekran=True,
                girdi=girdi,
                disk=gecici_disk,
                dokum=[(0x0300, 12), (0x0410, 2)],
            )
            ekran1 = s1.ekran_metni()
            self.assertIn("SATIR ASSEMBLER", ekran1)
            self.assertIn("0300 ? 'K' T YÜKLE", ekran1)
            self.assertIn("0302 ? T [0410] SAKLA", ekran1)
            self.assertIn("030B ? DÖN", ekran1)
            self.assertIn("DİSKE KAYDEDİLDİ.", ekran1)

            beklenen_kod = [
                0x10, ord("K"),
                0x15, 0x10, 0x04,
                0x13, 0x05,
                0x36,
                0x17, 0x11, 0x04,
                0x91,
            ]
            self.assertEqual(s1.bellek(0x0300, 12), beklenen_kod)
            self.assertEqual(s1.bellek(0x0410, 2), [ord("K"), 6])

            # Yeni oturumda diskten 'KODUM ÇALIŞTIR' ile doğrudan çalıştır
            s2 = calistir_bios(
                max_cevrim=300000,
                ekran=True,
                girdi="KODUM ÇALIŞTIR\n",
                disk=gecici_disk,
                dokum=[(0x0410, 2)],
            )
            self.assertEqual(s2.bellek(0x0410, 2), [ord("K"), 6])

    def test_faz6b_indeksli_dolayli_ve_soz_dizimi_hatasi(self):
        """İndeksli/dolaylı komutlar derlenir, hatalı satırda ise adres ilerlemez ve uyarı basılır."""
        girdi = (
            "0300 KODLA\n"
            "[0400 + X] T YÜKLE\n"
            "T [[0010] + Y] SAKLA\n"
            "YANLIS KOMUT SATIRI\n"
            "DUR\n"
            "\n"
        )
        s = calistir_bios(
            max_cevrim=500000,
            ekran=True,
            girdi=girdi,
            dokum=[(0x0300, 7)],
        )
        ekran = s.ekran_metni()
        self.assertIn("SÖZ DİZİMİ HATASI!", ekran)
        # [0400 + X] T YÜKLE -> 12 00 04 (3B)
        # T [[0010] + Y] SAKLA -> 25 10 00 (3B)
        # DUR -> 01 (1B, hatalı satır adresi ilerletmediği için 0306'ya yazılır)
        self.assertEqual(s.bellek(0x0300, 7), [0x12, 0x00, 0x04, 0x25, 0x10, 0x00, 0x01])

    def test_faz6c_duzenle_etiketli_derle_ve_calistir(self):
        """DÜZENLE ile etiketli, .TANIM, .METİN, <etiket/>etiket içeren program yazılıp DERLE ve ÇALIŞTIR ile çalışır."""
        girdi = (
            "DÜZENLE\n"
            ".TANIM HEDEF 0420\n"
            ".BAŞLANGIÇ 0300\n"
            "0 T YÜKLE ; sayaç sıfırla\n"
            "DÖNGÜ:\n"
            "1 TOPLA\n"
            "5 KARŞILAŞTIR\n"
            "DÖNGÜ FARKLIYSA ATLA\n"
            "T [HEDEF] SAKLA\n"
            "<MESAJ X YÜKLE\n"
            ">MESAJ Y YÜKLE\n"
            "2 SİSTEM\n"
            "DÖN\n"
            "MESAJ:\n"
            '.METİN "TAMAM!"\n'
            ".BAYT 0A, 0\n"
            "\n"
            "KAYNAK\n"
            "DERLE\n"
            "ÇALIŞTIR\n"
        )
        s = calistir_bios(
            max_cevrim=1200000,
            ekran=True,
            girdi=girdi,
            dokum=[(0x0420, 1)],
        )
        ekran = s.ekran_metni()
        self.assertIn("DERLENDİ: 0x0300 - 0x031B", ekran)
        self.assertIn("TAMAM!", ekran)
        self.assertEqual(s.bellek(0x0420, 1), [5])

    def test_faz6c_dogrudan_diske_derle_ve_yukle(self):
        """'<AD> DERLE' kaynak kodu derleyip diske kaydeder; yeni oturumda '<AD> ÇALIŞTIR' ile çalışır."""
        with tempfile.TemporaryDirectory() as klasor:
            gecici_disk = Path(klasor) / "derle_disk.t8"
            disk.imaj_kaydet(gecici_disk, disk.bos_imaj_olustur())

            girdi = (
                "DÜZENLE\n"
                ".BAŞLANGIÇ 0350\n"
                "ATLA_ETIKET ATLA\n"
                ".BAYT FF, FF\n"
                "ATLA_ETIKET:\n"
                "99 T YÜKLE\n"
                "T [0450] SAKLA\n"
                "DÖN\n"
                ".\n"
                "TESTPRG DERLE\n"
            )
            s1 = calistir_bios(
                max_cevrim=900000,
                ekran=True,
                girdi=girdi,
                disk=gecici_disk,
            )
            ekran1 = s1.ekran_metni()
            self.assertIn("DERLENDİ: 0x0350 - 0x035B", ekran1)
            self.assertIn("DİSKE KAYDEDİLDİ.", ekran1)

            # Yeni oturumda diskten 'TESTPRG ÇALIŞTIR'
            s2 = calistir_bios(
                max_cevrim=300000,
                ekran=True,
                girdi="TESTPRG ÇALIŞTIR\n",
                disk=gecici_disk,
                dokum=[(0x0450, 1)],
            )
            self.assertEqual(s2.bellek(0x0450, 1), [0x99])

    def test_faz6c_sil_yeni_ve_tanimsiz_etiket_hatasi(self):
        """DÜZENLE içinde SİL son satırı siler, tanımsız etiket ise 2. geçişte satır numarasıyla hata verir."""
        girdi = (
            "DÜZENLE\n"
            "YOK_ETIKET ATLA\n"
            "SİL\n"
            "12 T YÜKLE\n"
            "HATALI_HEDEF ATLA\n"
            "\n"
            "DERLE\n"
        )
        s = calistir_bios(
            max_cevrim=700000,
            ekran=True,
            girdi=girdi,
        )
        ekran = s.ekran_metni()
        self.assertIn("SATIR 02: SÖZ DİZİMİ HATASI!", ekran)


if __name__ == "__main__":
    unittest.main()

