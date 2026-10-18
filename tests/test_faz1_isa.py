#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRK-8 Faz 1 Testleri — ISA v1.0 (85 Komut, Bayraklar ve Sınır Değerler)

Her yeni komut, işaretli taşma (BAYRAK_TASMA), işaretsiz karşılaştırma düzeltmesi
(BÜYÜKSE/KÜÇÜKSE) ve sıfır sayfa blok işlemleri kapsamlı olarak sınanır.
"""

import unittest
from araclar.isa import KOMUTLAR, TAKMA_ADLAR, eslestir
from tests.yardimci import TurkTestCase, calistir, derle_metin


class TestFaz1ISA(TurkTestCase):
    def test_tum_91_komut_tekil_eslesme_ve_derleme(self):
        """91 komutun her birinin örnek söz dizimi yalnızca tek bir komutla eşleşmeli."""
        self.assertEqual(len(KOMUTLAR), 91)
        for komut in KOMUTLAR:
            ornek_satir = komut.ornek(n="0x2A", a="0x1234")
            eslesmeler = eslestir(ornek_satir)
            self.assertEqual(
                len(eslesmeler),
                1,
                f"'{ornek_satir}' ({komut.ad}) için {len(eslesmeler)} eşleşme bulundu!",
            )
            eslesen_komut, _ = eslesmeler[0]
            self.assertEqual(eslesen_komut.opkod, komut.opkod)

            rom = derle_metin(f".BAŞLANGIÇ 0x0200\n{ornek_satir}\n")
            self.assertEqual(len(rom), komut.boyut)
            self.assertEqual(rom[0], komut.opkod)

        # Takma ad kontrolü: BÜYÜK VEYA EŞİTSE ATLA -> KMT_ELDE_VARSA_ATLA (0x75)
        self.assertEqual(len(TAKMA_ADLAR), 1)
        rom_takma = derle_metin(".BAŞLANGIÇ 0x0200\n0x1234 BÜYÜK VEYA EŞİTSE ATLA\n")
        self.assertEqual(rom_takma, bytes([0x75, 0x34, 0x12]))

    def test_isaretsiz_karsilastirma_ve_atlamalar(self):
        """BÜYÜKSE, KÜÇÜKSE, KÜÇÜK VEYA EŞİTSE, BÜYÜK VEYA EŞİTSE sınır değerleri (0, 10, 127, 128, 200, 255)."""
        # 200 ile 10 karşılaştırıldığında (işaretsiz 200 > 10) BÜYÜKSE ATLA çalışmalı!
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        200 T YÜKLE
        10 KARŞILAŞTIR
        yanlis KÜÇÜKSE ATLA
        dogru BÜYÜKSE ATLA
        yanlis:
        0 T YÜKLE
        DUR
        dogru:
        200 T YÜKLE
        200 KARŞILAŞTIR
        yanlis BÜYÜKSE ATLA
        esit_dal KÜÇÜK VEYA EŞİTSE ATLA
        0 T YÜKLE
        DUR
        esit_dal:
        10 T YÜKLE
        200 KARŞILAŞTIR
        bitir KÜÇÜKSE ATLA
        0 T YÜKLE
        DUR
        bitir:
        200 T YÜKLE
        200 KARŞILAŞTIR
        basari BÜYÜK VEYA EŞİTSE ATLA
        0 T YÜKLE
        DUR
        basari:
        1 T YÜKLE
        DUR
        """)
        self.assertBitti(s)
        self.assertRegs(s, T=1)

    def test_tasma_bayragi_ve_atlamasi(self):
        """İşaretli taşma (BAYRAK_TASMA) ve TAŞMA VARSA ATLA (0x79) testi."""
        # 127 + 1 = 128 (-128) -> Pozitif + Pozitif = Negatif -> Taşma (T=1, N=1, E=0)
        s1 = calistir("""
        .BAŞLANGIÇ 0x0200
        1 T YÜKLE
        T X AKTAR
        127 T YÜKLE
        1 TOPLA
        tasti TAŞMA VARSA ATLA
        0 X YÜKLE
        tasti:
        DUR
        """)
        self.assertBitti(s1)
        self.assertRegs(s1, T=128, X=1)
        self.assertBayraklar(s1, "NT")

        # 100 + 20 = 120 -> Taşma yok (T=0)
        s2 = calistir("""
        .BAŞLANGIÇ 0x0200
        100 T YÜKLE
        20 TOPLA
        DUR
        """)
        self.assertBitti(s2)
        self.assertRegs(s2, T=120)
        self.assertBayraklar(s2, "")

        # 128 (-128) - 1 = 127 (+127) -> Negatif - Pozitif = Pozitif -> Taşma (T=1, E=1)
        s3 = calistir("""
        .BAŞLANGIÇ 0x0200
        128 T YÜKLE
        1 ÇIKAR
        DUR
        """)
        self.assertBitti(s3)
        self.assertRegs(s3, T=127)
        self.assertBayraklar(s3, "ET")

    def test_elde_kur_temizle_ve_borcla_cikar(self):
        """ELDE KUR (0x40), ELDE TEMİZLE (0x41) ve BORÇLA ÇIKAR (0x3F) ile 16-bit çıkarma: 0x0200 - 0x0001 = 0x01FF."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        ELDE TEMİZLE
        elde_yok ELDE YOKSA ATLA
        DUR
        elde_yok:
        ELDE KUR
        ; Alt bayt: 0x00 - 0x01 = 0xFF (borç oluşur -> E=0)
        0x00 T YÜKLE
        0x01 ÇIKAR
        T X AKTAR
        ; Üst bayt: 0x02 - 0x00 - borç(1) = 0x01 (borç yok -> E=1)
        0x02 T YÜKLE
        0x00 BORÇLA ÇIKAR
        T Y AKTAR
        DUR
        """)
        self.assertBitti(s)
        self.assertRegs(s, X=0xFF, Y=0x01)
        self.assertBayraklar(s, "E")

    def test_y_indeks_dolayli_ve_bellek_yukle_sakla(self):
        """[adres] X/Y YÜKLE, [adres + Y] T YÜKLE/SAKLA ve [[işaretçi] + Y] T YÜKLE/SAKLA testleri."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        [bas_x] X YÜKLE
        [bas_y] Y YÜKLE

        ; [tablo + Y] T YÜKLE (Y=2 -> 30)
        [tablo + Y] T YÜKLE
        1 TOPLA
        T [tablo + Y] SAKLA

        ; Dolaylı + Y: [[ptr] + Y] (ptr -> 0x0300, Y=2 -> 0x0302)
        0x00 T YÜKLE
        T [0x0010] SAKLA
        0x03 T YÜKLE
        T [0x0011] SAKLA

        77 T YÜKLE
        T [[0x0010] + Y] SAKLA
        0 T YÜKLE
        [[0x0010] + Y] T YÜKLE
        DUR

        bas_x: .BAYT 9
        bas_y: .BAYT 2
        tablo: .BAYT 10, 20, 30, 40
        """, dokum=[(0x0302, 1)])
        self.assertBitti(s)
        self.assertRegs(s, T=77, X=9, Y=2)
        self.assertEqual(s.bellek(0x0302, 1), [77])

    def test_yigin_x_y_ve_yg_aktar(self):
        """YG T AKTAR, T YG AKTAR, X İT/ÇEK, Y İT/ÇEK testleri."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        0xE0 T YÜKLE
        T YG AKTAR
        11 X YÜKLE
        22 Y YÜKLE
        X İT
        Y İT
        0 X YÜKLE
        0 Y YÜKLE
        X ÇEK
        Y ÇEK
        YG T AKTAR
        DUR
        """)
        self.assertBitti(s)
        # Y son itildiği için ilk X ÇEK ile X=22, ikinci Y ÇEK ile Y=11 olur; YG tekrar 0xE0 olur
        self.assertRegs(s, T=0xE0, X=22, Y=11)
        self.assertEqual(s.YG, 0xE0)

    def test_bellekte_artir_azalt_ve_karsilastir(self):
        """[adres] ARTIR (0x42), [adres] AZALT (0x43), [adres] KARŞILAŞTIR (0x3E) ve <n> Y KARŞILAŞTIR (0x3D)."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        [sayac] ARTIR
        [sayac] ARTIR
        [sayac] AZALT
        11 T YÜKLE
        [sayac] KARŞILAŞTIR
        esit EŞİTSE ATLA
        DUR
        esit:
        5 Y YÜKLE
        5 Y KARŞILAŞTIR
        y_esit EŞİTSE ATLA
        DUR
        y_esit:
        [sayac] T YÜKLE
        DUR
        sayac: .BAYT 10
        """)
        self.assertBitti(s)
        self.assertRegs(s, T=11, Y=5)

    def test_dondurme_bit_sina_ve_bellek_mantik(self):
        """T SOLA DÖNDÜR (0x56), T SAĞA DÖNDÜR (0x57), BİT SINA (0x58), [adres] VE/VEYA (0x59/0x5A)."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        ELDE KUR
        0x80 T YÜKLE
        T SOLA DÖNDÜR       ; T = 0x01, Elde = 1
        T X AKTAR
        T SAĞA DÖNDÜR       ; T = 0x80 | 0x00 = 0x80, Elde = 1
        [maske_ve] VE       ; 0x80 & 0xF0 = 0x80
        [maske_veya] VEYA   ; 0x80 | 0x05 = 0x85
        0x04 BİT SINA       ; 0x85 & 0x04 = 0x04 -> S=0, T değişmez (0x85)
        DUR
        maske_ve:   .BAYT 0xF0
        maske_veya: .BAYT 0x05
        """)
        self.assertBitti(s)
        self.assertRegs(s, T=0x85, X=0x01)
        self.assertBayraklar(s, "E")

    def test_negatif_pozitif_ve_dolayli_atlama_cagirma(self):
        """NEGATİFSE ATLA (0x77), POZİTİFSE ATLA (0x78), [adres] ATLA (0x7B), [adres] ÇAĞIR (0x7C)."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        0x80 T YÜKLE
        neg_dal NEGATİFSE ATLA
        DUR
        neg_dal:
        0x01 T YÜKLE
        poz_dal POZİTİFSE ATLA
        DUR
        poz_dal:
        [alt_ptr] ÇAĞIR
        [son_ptr] ATLA

        alt_program:
        55 X YÜKLE
        DÖN

        bitis:
        99 Y YÜKLE
        DUR

        alt_ptr: .KELİME alt_program
        son_ptr: .KELİME bitis
        """)
        self.assertBitti(s)
        self.assertRegs(s, X=55, Y=99)

    def test_rakamlara_ayir_rastgele_kare_bekle_ve_sistem(self):
        """T RAKAMLARA AYIR (0x44), RASTGELE (0x07), KARE BEKLE (0x06) ve <n> SİSTEM (0x05)."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        ; 1. T RAKAMLARA AYIR: 247 -> Y='2'(50), X='4'(52), T='7'(55)
        247 T YÜKLE
        T RAKAMLARA AYIR
        T [0x0300] SAKLA
        X [0x0301] SAKLA
        Y [0x0302] SAKLA

        ; 2. KARE BEKLE: zamanlayıcı portunu (port 2) 1 artırır
        2 GİRİŞ
        T [0x0303] SAKLA
        KARE BEKLE
        2 GİRİŞ
        T [0x0304] SAKLA

        ; 3. RASTGELE: ardışık iki çağrı farklı değer üretmeli
        RASTGELE
        T X AKTAR
        RASTGELE
        T Y AKTAR
        DUR
        """, dokum=[(0x0300, 5)])
        self.assertBitti(s)
        self.assertEqual(s.bellek(0x0300, 3), [ord('7'), ord('4'), ord('2')])
        # KARE BEKLE sonrası zamanlayıcı 1 artmış olmalı
        onceki_zaman, sonraki_zaman = s.bellek(0x0303, 2)
        self.assertEqual((sonraki_zaman - onceki_zaman) & 0xFF, 1)
        # RASTGELE iki farklı sayı üretmeli
        self.assertNotEqual(s.X, s.Y)

    def test_sistem_cagrisi_ve_kesmeden_don(self):
        """<n> SİSTEM komutunun [0x00FA] servis kodunu yazıp [0x00FC] vektörü üzerinden döndüğünü doğrula."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        ; 0x00FC (ADRES_SISTEM_VEKTOR) içine isleyici adresini (0x020D) yaz
        0x0D T YÜKLE
        T [0x00FC] SAKLA
        0x02 T YÜKLE
        T [0x00FD] SAKLA

        0x42 SİSTEM
        DUR

        ; Adres 0x020D:
        [0x00FA] T YÜKLE
        T X AKTAR
        KESMEDEN DÖN
        """)
        self.assertBitti(s)
        self.assertRegs(s, T=0x42, X=0x42)

    def test_kopyala_ve_doldur(self):
        """DOLDUR (0x29) ve KOPYALA (0x28 — örtüşen bellek bölgesi dahil) testleri."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        ; 1. 0x0400 adresinden itibaren 6 baytı 0xAA ile DOLDUR
        0x00 T YÜKLE
        T [0x0002] SAKLA
        0x04 T YÜKLE
        T [0x0003] SAKLA
        6 T YÜKLE
        T [0x0004] SAKLA
        0 T YÜKLE
        T [0x0005] SAKLA
        0xAA T YÜKLE
        DOLDUR

        ; 2. Kaynak diziyi (1,2,3,4) 0x0410 adresine yaz, sonra örtüşen 0x0411 adresine KOPYALA
        1 T YÜKLE
        T [0x0410] SAKLA
        2 T YÜKLE
        T [0x0411] SAKLA
        3 T YÜKLE
        T [0x0412] SAKLA
        4 T YÜKLE
        T [0x0413] SAKLA

        0x10 T YÜKLE
        T [0x0000] SAKLA
        0x04 T YÜKLE
        T [0x0001] SAKLA
        0x11 T YÜKLE
        T [0x0002] SAKLA
        0x04 T YÜKLE
        T [0x0003] SAKLA
        4 T YÜKLE
        T [0x0004] SAKLA
        0 T YÜKLE
        T [0x0005] SAKLA
        KOPYALA
        DUR
        """, dokum=[(0x0400, 6), (0x0410, 5)])
        self.assertBitti(s)
        self.assertEqual(s.bellek(0x0400, 6), [0xAA] * 6)
        self.assertEqual(s.bellek(0x0410, 5), [1, 1, 2, 3, 4])


if __name__ == "__main__":
    unittest.main()
