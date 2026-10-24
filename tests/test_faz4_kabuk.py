# -*- coding: utf-8 -*-
"""
Faz 4 — ROM Komut Kabuğu (roms/bios.asm içinde) testleri.

Doğrulanan komutlar:
- YARDIM         : Komut listesini ekrana yazar
- TEMİZLE        : Ekranı temizler ve yeni '> _' istemini en üstte açar
- BİLGİ          : İşlemci, RAM, Ekran ve BIOS ROM özetini yazar
- BELLEK [adres] : Belirtilen adresten (varsayılan 0x0200) 32 baytlık hex döküm verir
- ÇALIŞTIR [adr] : Belirtilen adresteki (varsayılan 0x0200) makine kodunu çalıştırır
- SÜRE           : 50 Hz çalışma süresi sayacını hex ve onluk olarak yazar
- Küçük/büyük harf ve Türkçe karakter duyarsızlığı (ör. 'yardım', 'temizle', 'çalıştır')
- Bilinmeyen komut ve geçersiz adres hata mesajları
"""

import unittest

from yardimci import TurkTestCase, calistir, calistir_bios


class TestFaz4Kabuk(TurkTestCase):

    def test_yardim_komutu_buyuk_ve_kucuk_harf(self):
        """'yardım' (küçük harf + Türkçe ı) komutu yardım tablosunu ekrana basar."""
        s = calistir_bios(max_cevrim=120000, ekran=True, girdi="yardım\n")
        ekran = s.ekran_metni()
        self.assertIn("KOMUTLAR:", ekran)
        self.assertIn("YARDIM", ekran)
        self.assertIn("TEMİZLE", ekran)
        self.assertIn("BELLEK [ADR]", ekran)
        self.assertIn("ÇALIŞTIR [A]", ekran)

    def test_temizle_komutu(self):
        """TEMİZLE komutu açılış başlığını siler ve 0. satırda '> _' istemini gösterir."""
        s = calistir_bios(max_cevrim=120000, ekran=True, girdi="TEMİZLE\n")
        self.assertEqual(s.ekran_satirlari[0].strip(), "> _")
        self.assertNotIn("31 KB SERBEST RAM", s.ekran_metni())

    def test_bilgi_komutu(self):
        """BİLGİ komutu donanım özetini ekrana yazar."""
        s = calistir_bios(max_cevrim=120000, ekran=True, girdi="bilgi\n")
        ekran = s.ekran_metni()
        self.assertIn("İŞLEMCİ : TÜRK-8 (8-BİT, 91 KOMUT)", ekran)
        self.assertIn("RAM     : 31 KB (0x0200-0x7FFF)", ekran)
        self.assertIn("BIOS ROM: 16 KB (0xC000-0xFFFF)", ekran)

    def test_sure_komutu(self):
        """SÜRE komutu 50 Hz çalışma süresi sayacını ekrana yazar."""
        s = calistir_bios(max_cevrim=120000, ekran=True, girdi="SÜRE\n")
        ekran = s.ekran_metni()
        self.assertIn("SÜRE: 0x", ekran)
        self.assertIn("KARE (50 HZ)", ekran)

    def test_bellek_dokumu_varsayilan_ve_argumanli(self):
        """BELLEK komutu argümansız 0x0200'ü, argümanlı ise verilen adresi (ör. FFFA) döker."""
        s1 = calistir_bios(max_cevrim=150000, ekran=True, girdi="BELLEK\n")
        ekran1 = s1.ekran_metni()
        self.assertIn("0200: 00 00 00 00 00 00 00 00", ekran1)
        self.assertIn("0218: 00 00 00 00 00 00 00 00", ekran1)

        s2 = calistir_bios(max_cevrim=150000, ekran=True, girdi="BELLEK FFFA\n")
        ekran2 = s2.ekran_metni()
        # 0xFFFC sıfırlama vektörü 0xC000 (küçük uçlu: 00 C0) içerir
        self.assertIn("FFFA:", ekran2)
        self.assertIn("00 C0", ekran2)

    def test_calistir_komutu_ile_program_calistirma(self):
        """Belleğe yüklenen bir programı kabuğa girip 'ÇALIŞTIR 0305' yazarak çalıştırır."""
        # 0x0200'deki başlangıç programı 0x0305'e küçük bir makine kodu yazar ve kabuğa atlar
        # (POST 256 baytlık sayfa başlarını 0x0300, 0x0400 vb. sınadığı için 0x0305 ve 0x0405 kullanılır):
        # 0x0305: 0x10 0x42 (0x42 T YÜKLE)
        # 0x0307: 0x15 0x05 0x04 (T [0x0405] SAKLA)
        # 0x030A: 0x91 (DÖN -> tekrar kabuğa döner!)
        s = calistir("""
            .BAŞLANGIÇ 0x0200
            0x10 T YÜKLE
            T [0x0305] SAKLA
            0x42 T YÜKLE
            T [0x0306] SAKLA
            0x15 T YÜKLE
            T [0x0307] SAKLA
            0x05 T YÜKLE
            T [0x0308] SAKLA
            0x04 T YÜKLE
            T [0x0309] SAKLA
            0x91 T YÜKLE
            T [0x030A] SAKLA

            ; BIOS açılış vektörüne atla
            [0xFFFC] ATLA
        """, max_cevrim=150000, ekran=True, girdi="çalıştır 0305\n", dokum=[(0x0405, 1)])
        self.assertEqual(s.bellek(0x0405, 1), [0x42])
        self.assertIn("> ÇALIŞTIR 0305", s.ekran_metni().upper())

    def test_bilinmeyen_komut_ve_gecersiz_adres_hatasi(self):
        """Tanınmayan komut veya bozuk hex adres girildiğinde uygun hata mesajı verir."""
        s1 = calistir_bios(max_cevrim=120000, ekran=True, girdi="MERHABA\n")
        self.assertIn("BİLİNMEYEN KOMUT!", s1.ekran_metni())

        s2 = calistir_bios(max_cevrim=120000, ekran=True, girdi="BELLEK GGGG\n")
        self.assertIn("GEÇERSİZ ADRES!", s2.ekran_metni())

    def test_ardisik_komutlarda_satirlar_ust_uste_binmez(self):
        """Satır >= 16 olduğunda imleç adresi hesabı taşmaz ve yazılar üst üste binmez."""
        s = calistir_bios(
            max_cevrim=400000,
            ekran=True,
            girdi="YARDIM\nBİLGİ\n",
        )
        ekran = s.ekran_metni()
        self.assertIn(" SÜRE          ÇALIŞMA SÜRESİ", ekran)
        self.assertIn("İŞLEMCİ : TÜRK-8 (8-BİT, 91 KOMUT)", ekran)
        self.assertIn("BIOS ROM: 16 KB (0xC000-0xFFFF)", ekran)


if __name__ == "__main__":
    unittest.main()
