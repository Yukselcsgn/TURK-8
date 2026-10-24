#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRK-8 Faz 2 Testleri — Donanım:
1. Gerçek 50 Hz zamanlayıcı kesmesi (0xFFFE / RAM 0x00FE) ve KARE BEKLE uyumu
2. 16 baytlık klavye FIFO tamponu ve taşma koruması
3. Ses portları (0xA004 frekans, 0xA005 süre) ve kare bazlı süre azalması
4. Rastgele sayı üreteci (RASTGELE komutu ve 0xA006 portu) dağılımı
5. Disk denetleyici port alanı (0xA010 - 0xA017)
6. Pong oyununun KARE BEKLE ile çalışması
"""

import tempfile
import unittest
from pathlib import Path

from tests.yardimci import KOK, TurkTestCase, calistir, calistir_rom, derle_metin


class TestFaz2Donanim(TurkTestCase):
    def test_50hz_zamanlayici_kesmesi_ve_kare_bekle(self):
        """KESME AÇ sonrası KARE BEKLE ve 500 çevrimlik doğal 50 Hz kesmelerinin çalıştığını doğrula."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        ; Kesme işleyici adresini RAM kesme vektörüne (0x00FE-0x00FF) yaz
        [vektor_ptr] T YÜKLE
        T [0x00FE] SAKLA
        0x01 X YÜKLE
        [vektor_ptr + X] T YÜKLE
        T [0x00FF] SAKLA

        KESME AÇ
        KARE BEKLE
        KARE BEKLE
        KARE BEKLE
        KESME KAPAT
        KARE BEKLE

        [0x0300] T YÜKLE
        DUR

        kesme_isleyici:
        T İT
        [0x0300] ARTIR
        T ÇEK
        KESMEDEN DÖN

        vektor_ptr:
        .KELİME kesme_isleyici
        """, dokum=[(0x0300, 1)])
        self.assertBitti(s)
        # KESME AÇ iken 3 kez KARE BEKLE çağrıldı -> kesme sayacı 3 olmalı (KESME KAPAT iken artmamalı)
        self.assertRegs(s, T=3)
        self.assertEqual(s.bellek(0x0300, 1), [3])
        self.assertEqual(s.zaman, 4)

    def test_50hz_kesme_dongu_icinde_otomatik_tetiklenir(self):
        """KARE BEKLE olmadan da her 500 çevrimde 50 Hz zamanlayıcı kesmesinin tetiklendiğini doğrula."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        [vektor_ptr] T YÜKLE
        T [0x00FE] SAKLA
        0x01 X YÜKLE
        [vektor_ptr + X] T YÜKLE
        T [0x00FF] SAKLA

        KESME AÇ
        bekle_dongu:
        [0x0300] T YÜKLE
        3 KARŞILAŞTIR
        bekle_dongu KÜÇÜKSE ATLA
        DUR

        kesme_isleyici:
        T İT
        [0x0300] ARTIR
        T ÇEK
        KESMEDEN DÖN

        vektor_ptr:
        .KELİME kesme_isleyici
        """, dokum=[(0x0300, 1)])
        self.assertBitti(s)
        self.assertEqual(s.bellek(0x0300, 1), [3])
        self.assertGreaterEqual(s.zaman, 3)

    def test_klavye_16_bayt_fifo_tamponu(self):
        """16 baytlık klavye FIFO tamponunun sırayı koruduğunu ve taşmayı (17+ bayt) doğru yönettiğini doğrula."""
        kod = """
        .BAŞLANGIÇ 0x0200
        0 X YÜKLE
        oku_dongu:
        1 GİRİŞ
        0 KARŞILAŞTIR
        bitti EŞİTSE ATLA
        0 GİRİŞ
        T [0x0300 + X] SAKLA
        X ARTIR
        oku_dongu ATLA
        bitti:
        DUR
        """
        # 1. Tam 16 karakter gönder -> taşma olmamalı, 16 karakter sırayla okunmalı
        metin16 = "ABCDEFGHIJKLMNOP"
        s1 = calistir(kod, girdi=metin16, dokum=[(0x0300, 16)])
        self.assertBitti(s1)
        self.assertRegs(s1, X=16)
        self.assertEqual(bytes(s1.bellek(0x0300, 16)).decode("ascii"), metin16)
        self.assertEqual(s1.fifo_sayi, 0)
        self.assertFalse(s1.fifo_tasti)

        # 2. 20 karakter gönder -> ilk 16 karakter bozulmadan okunmalı ve fifo_tasti=True olmalı
        metin20 = "0123456789ABCDEFGHIJ"
        s2 = calistir(kod, girdi=metin20, dokum=[(0x0300, 16)])
        self.assertBitti(s2)
        self.assertRegs(s2, X=16)
        self.assertEqual(bytes(s2.bellek(0x0300, 16)).decode("ascii"), "0123456789ABCDEF")
        self.assertEqual(s2.fifo_sayi, 0)
        self.assertTrue(s2.fifo_tasti)

    def test_ses_portu_frekans_ve_sure(self):
        """0xA004 (frekans) ve 0xA005 (süre) portlarının çalışmasını ve her karede sürenin azalmasını doğrula."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        220 T YÜKLE
        4 ÇIKIŞ         ; PORT_SES_FREKANS = 220
        3 T YÜKLE
        5 ÇIKIŞ         ; PORT_SES_SURE = 3 (sesi tetikler)

        5 GİRİŞ
        T X AKTAR       ; X = 3 (başlangıç süresi)

        KARE BEKLE      ; kalan süre = 2
        KARE BEKLE      ; kalan süre = 1
        5 GİRİŞ
        T Y AKTAR       ; Y = 1

        KARE BEKLE      ; kalan süre = 0
        5 GİRİŞ         ; T = 0
        DUR
        """)
        self.assertBitti(s)
        self.assertRegs(s, T=0, X=3, Y=1)
        self.assertEqual(s.ses_frekans, 220)
        self.assertEqual(s.ses_sure, 0)
        self.assertEqual(s.ses_sayisi, 1)

    def test_rastgele_sayi_dagilimi(self):
        """Hem RASTGELE komutunun hem de PORT_RASTGELE (0xA006) portunun çeşitli değerler ürettiğini doğrula."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        0 X YÜKLE
        dongu:
        RASTGELE
        T [0x0300 + X] SAKLA
        6 GİRİŞ
        T [0x0320 + X] SAKLA
        X ARTIR
        32 X KARŞILAŞTIR
        dongu KÜÇÜKSE ATLA
        DUR
        """, dokum=[(0x0300, 32), (0x0320, 32)])
        self.assertBitti(s)
        komut_rng = set(s.bellek(0x0300, 32))
        port_rng = set(s.bellek(0x0320, 32))
        self.assertGreaterEqual(len(komut_rng), 20)
        self.assertGreaterEqual(len(port_rng), 20)

    def test_disk_port_alani_okuma_yazma(self):
        """0xA010 - 0xA017 sanal disk denetleyici port alanının ayrıldığını ve yazılıp okunabildiğini doğrula."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        5 T YÜKLE
        0x12 ÇIKIŞ      ; PORT_DISK_SEKTOR = 5
        0x00 T YÜKLE
        0x13 ÇIKIŞ      ; PORT_DISK_ADRES_ALT = 0x00
        0x20 T YÜKLE
        0x14 ÇIKIŞ      ; PORT_DISK_ADRES_UST = 0x20
        0x12 GİRİŞ
        T X AKTAR
        0x14 GİRİŞ
        T Y AKTAR
        DUR
        """)
        self.assertBitti(s)
        self.assertRegs(s, X=5, Y=0x20)

    def test_turkce_karakter_klavye_ve_vram(self):
        """ISO-8859-9 (Latin-5) 8-bit Türkçe karakterlerin klavye FIFO ve VRAM'de tek bayt olarak çalıştığını doğrula."""
        with tempfile.TemporaryDirectory() as klasor:
            rom_yolu = Path(klasor) / "kabuk.rom"
            rom_yolu.write_bytes(derle_metin((KOK / "programlar" / "kabuk.asm").read_text(encoding="utf-8")))
            s = calistir_rom(rom_yolu, max_cevrim=5000, girdi="ÇĞİÖŞÜçğıöşü", ekran=True)
            ekran = s.ekran_metni()
            self.assertIn("== TÜRK-8 CANLI KABUK (KLAVYE AKTİF) ===", ekran)
            self.assertIn("Yazı yazabilirsiniz (Çıkış için ESC)", ekran)
            self.assertIn("ÇĞİÖŞÜçğıöşü_", ekran)

    def test_pong_kare_bekle_ile_calisma(self):
        """Güncellenen Pong oyununun KARE BEKLE ve klavye girdisiyle (WWSS) hatasız çalıştığını doğrula."""
        with tempfile.TemporaryDirectory() as klasor:
            rom_yolu = Path(klasor) / "pong.rom"
            rom_yolu.write_bytes(derle_metin((KOK / "programlar" / "pong.asm").read_text(encoding="utf-8")))
            s = calistir_rom(rom_yolu, max_cevrim=15000, girdi="WWSS", ekran=True)
            self.assertEqual(s.neden, "zaman_asimi")
            self.assertIn("== TURK-8 PONG ==  SKOR: 00", s.ekran_metni())
            self.assertGreater(s.zaman, 10)


if __name__ == "__main__":
    unittest.main()
