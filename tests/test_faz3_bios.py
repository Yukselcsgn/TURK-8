# -*- coding: utf-8 -*-
"""
Faz 3 — BIOS ROM (roms/bios.asm) ve doğrudan açılış testleri.

Doğrulananlar:
- Çok bölümlü .BAŞLANGIÇ derleyici desteği (0xC000 + 0xFFFA vektör tablosu = 16 KB)
- Argümansız BIOS açılışı (POST bellek testi, başlık, ses, "> _" imleci)
- BIOS yazılım kesmesi servisleri (<n> SİSTEM, n = 0..8):
  0: Ekran temizle
  1: Karakter yaz (normal, '\n', Backspace, 40 sütun taşması, 25 satır kaydırma)
  2: Sıfır sonlandırmalı metin yaz (Türkçe karakterler dahil)
  3: Beklemesiz tuş oku
  4: Bloklamalı tuş bekle (KARE BEKLE ile)
  5: Satır oku (Backspace, Enter, 0x0080 tamponu)
  6: Ekranı 1 satır yukarı kaydır
  7: Ses çal (frekans, süre)
  8: 50 Hz çalışma süresi sayacını oku
"""

import unittest

import derleyici
from yardimci import KOK, TurkTestCase, calistir, calistir_bios


class TestFaz3Bios(TurkTestCase):

    def test_cok_bolumlu_baslangic_ve_bios_boyutu(self):
        """Çok bölümlü .BAŞLANGIÇ direktifi aradaki boşluğu 0 ile doldurup 16 KB ROM üretir."""
        bios_kaynak = (KOK / "roms" / "bios.asm").read_text(encoding="utf-8")
        baslangic, imaj = derleyici.derle(bios_kaynak)
        self.assertEqual(baslangic, 0xC000)
        self.assertEqual(len(imaj), 16384)  # 0xC000..0xFFFF = 16 KB

        # Son 6 bayt vektör tablosu olmalı (0xFFFA, 0xFFFC, 0xFFFE) ve 0xC000..0xFFFF içine işaret etmeli
        vektor_sistem = imaj[0x3FFA] | (imaj[0x3FFB] << 8)
        vektor_sifirla = imaj[0x3FFC] | (imaj[0x3FFD] << 8)
        vektor_kesme = imaj[0x3FFE] | (imaj[0x3FFF] << 8)
        self.assertGreaterEqual(vektor_sistem, 0xC000)
        self.assertEqual(vektor_sifirla, 0xC000)
        self.assertGreaterEqual(vektor_kesme, 0xC000)

    def test_argumansiz_bios_acilisi(self):
        """Argümansız başlatıldığında BIOS POST testini geçer, başlığı ve '> _' imlecini çizer."""
        s = calistir_bios(max_cevrim=100000, ekran=True)
        self.assertEqual(s.neden, "zaman_asimi")  # İmleçte tuş beklerken KARE BEKLE döngüsündedir
        ekran = s.ekran_metni()
        self.assertIn("TÜRK-8 KİŞİSEL BİLGİSAYAR", ekran)
        self.assertIn("31 KB SERBEST RAM", ekran)
        self.assertIn("HAZIR.", ekran)
        self.assertIn("> _", ekran)
        # Açılış bip sesi çalınmış olmalı
        self.assertGreaterEqual(s.ses_sayisi, 1)

    def test_bios_isteminde_satir_girisi_ve_geri_silme(self):
        """BIOS açılış isteminde Türkçe harf yazma, Backspace ile silme ve Enter çalışır."""
        s = calistir_bios(
            max_cevrim=100000,
            ekran=True,
            girdi="MERHABAX\x08 ŞĞİ\n",
            dokum=[(0x0080, 16)],
        )
        ekran = s.ekran_metni()
        self.assertIn("> MERHABA ŞĞİ", ekran)
        # Alt satırda yeni istem "> _" açılmış olmalı
        self.assertEqual(s.ekran_satirlari[6].strip(), "> _")
        # 0x0080 tamponunda "MERHABA ŞĞİ\0" (ISO-8859-9) bulunmalı
        beklenen = list("MERHABA ŞĞİ".encode("iso-8859-9")) + [0]
        self.assertEqual(s.bellek(0x0080, len(beklenen)), beklenen)

    def test_servis_0_1_2_ekran_karakter_ve_metin(self):
        """Servis 0 (temizle), 1 (karakter yaz) ve 2 (metin yaz) Türkçe metni doğru basar."""
        s = calistir("""
            .BAŞLANGIÇ 0x0200
            0 SİSTEM
            <yazi X YÜKLE
            >yazi Y YÜKLE
            2 SİSTEM
            '!' T YÜKLE
            1 SİSTEM
            DUR

        yazi:
            .METİN "ÇĞİÖŞÜ çğıöşü"
            .BAYT 0
        """, ekran=True)
        self.assertBitti(s)
        self.assertEqual(s.ekran_satirlari[0].strip(), "ÇĞİÖŞÜ çğıöşü!")

    def test_servis_3_ve_4_tus_oku_ve_bekle(self):
        """Servis 3 beklemesiz, Servis 4 bloklamalı tuş okur."""
        s = calistir("""
            .BAŞLANGIÇ 0x0200
            4 SİSTEM            ; İlk tuşu bekle ('A')
            T [0x0300] SAKLA
            3 SİSTEM            ; İkinci tuşu beklemesiz oku ('B')
            T [0x0301] SAKLA
            3 SİSTEM            ; Kuyruk boş -> 0 dönmeli
            T [0x0302] SAKLA
            DUR
        """, girdi="AB", dokum=[(0x0300, 3)])
        self.assertBitti(s)
        self.assertEqual(s.bellek(0x0300, 3), [ord("A"), ord("B"), 0])

    def test_servis_6_ekran_kaydirma(self):
        """Servis 6 ekranı 1 satır yukarı kaydırır ve 25. satır taşmasında otomatik çağrılır."""
        s = calistir("""
            .BAŞLANGIÇ 0x0200
            0 SİSTEM
            '1' T YÜKLE
            1 SİSTEM
            10 T YÜKLE
            1 SİSTEM
            '2' T YÜKLE
            1 SİSTEM
            6 SİSTEM            ; 1 satır yukarı kaydır -> '2' 0. satıra çıkmalı
            DUR
        """, ekran=True)
        self.assertBitti(s)
        self.assertEqual(s.ekran_satirlari[0].strip(), "2")

    def test_servis_7_ve_8_ses_ve_sure(self):
        """Servis 7 ses çalar, Servis 8 ise 50 Hz kesmesiyle artan süreyi döndürür."""
        s = calistir("""
            .BAŞLANGIÇ 0x0200
            KESME AÇ
            120 X YÜKLE
            3 Y YÜKLE
            7 SİSTEM
            KARE BEKLE
            KARE BEKLE
            KARE BEKLE
            8 SİSTEM
            DUR
        """)
        self.assertBitti(s)
        self.assertEqual(s.ses_frekans, 120)
        self.assertEqual(s.ses_sayisi, 1)
        self.assertGreaterEqual(s.T, 3)


if __name__ == "__main__":
    unittest.main()
