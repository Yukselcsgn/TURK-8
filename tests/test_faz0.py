#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRK-8 Faz 0 Testleri:
1. Python ISA tablosu (araclar/isa.py) ile C işlemci tablosunun (include/komutlar.h ve src/komutlar.c) birebir uyumu
2. Tablo tabanlı derleyici (araclar/derleyici.py) sözde komutları (.METİN, .BAYT, .KELİME, .BOŞLUK, .TANIM)
3. Başsız test kipi (--test) ve mevcut örnek programların (merhaba, toplam, kabuk, pong) hatasız derlenip çalışması
"""

import re
import tempfile
import unittest
from pathlib import Path

from araclar.isa import KOMUTLAR, OPKOD_TABLOSU
from tests.yardimci import (
    CIKIS_TEST_HATASI,
    CIKIS_ZAMAN_ASIMI,
    KOK,
    TurkTestCase,
    calistir,
    calistir_rom,
    derle_metin,
)


class TestFaz0Altyapi(TurkTestCase):
    def test_c_ve_python_komut_tablosu_uyumu(self):
        """include/komutlar.h ve src/komutlar.c içindeki opcode ve boyutların araclar/isa.py ile birebir aynı olduğunu doğrula."""
        komutlar_h = (KOK / "include" / "komutlar.h").read_text(encoding="utf-8")
        komutlar_c = (KOK / "src" / "komutlar.c").read_text(encoding="utf-8")

        # enum içindeki KMT_... = 0x.. eşleşmelerini çıkar
        kmt_degerleri = {}
        for ad, hex_kod in re.findall(r"\b(KMT_\w+)\s*=\s*(0x[0-9A-Fa-f]+)", komutlar_h):
            kmt_degerleri[ad] = int(hex_kod, 16)

        # [KMT_...] = { KMT_..., "...", boyut, cevrim } satırlarını çıkar
        c_tablo = {}
        for kmt_ad, boyut_str in re.findall(
            r"\[(KMT_\w+)\]\s*=\s*\{\s*\1\s*,\s*\"[^\"]*\"\s*,\s*(\d+)\s*,",
            komutlar_c,
        ):
            kod = kmt_degerleri[kmt_ad]
            c_tablo[kod] = (kmt_ad, int(boyut_str))

        self.assertEqual(
            len(c_tablo),
            len(KOMUTLAR),
            f"C tablosundaki komut sayısı ({len(c_tablo)}) ile Python ISA tablosu ({len(KOMUTLAR)}) farklı!",
        )

        for kod, (kmt_ad, c_boyut) in c_tablo.items():
            self.assertIn(kod, OPKOD_TABLOSU, f"{kmt_ad} (0x{kod:02X}) Python ISA tablosunda yok!")
            py_kmt = OPKOD_TABLOSU[kod]
            self.assertEqual(
                py_kmt.ad,
                kmt_ad,
                f"0x{kod:02X} için C adı ({kmt_ad}) != Python adı ({py_kmt.ad})",
            )
            self.assertEqual(
                py_kmt.boyut,
                c_boyut,
                f"{kmt_ad} (0x{kod:02X}) için C boyutu ({c_boyut}) != Python boyutu ({py_kmt.boyut})",
            )

    def test_derleyici_sozde_komutlar(self):
        """Derleyicideki .TANIM, .BAYT, .KELİME, .BOŞLUK ve .METİN direktiflerini doğrula."""
        kaynak = """
        .BAŞLANGIÇ 0x0200
        .TANIM DEGER 42
        .TANIM HEDEF_ADRES 0x1234

        DEGER T YÜKLE
        T [HEDEF_ADRES] SAKLA
        DUR

        veri_bayt:
        .BAYT 1, 2, 0xFF
        veri_kelime:
        .KELİME 0xABCD, 0x0102
        veri_bosluk:
        .BOŞLUK 3
        veri_metin:
        .METİN "A\\n"
        """
        rom = derle_metin(kaynak)
        # 42 T YÜKLE -> 0x10, 42 (2 bayt)
        # T [0x1234] SAKLA -> 0x15, 0x34, 0x12 (3 bayt)
        # DUR -> 0x01 (1 bayt)
        # .BAYT 1, 2, 0xFF -> 1, 2, 255 (3 bayt)
        # .KELİME 0xABCD, 0x0102 -> 0xCD, 0xAB, 0x02, 0x01 (4 bayt)
        # .BOŞLUK 3 -> 0, 0, 0 (3 bayt)
        # .METİN "A\n" -> 65, 10 (2 bayt)
        beklenen = bytes([
            0x10, 42,
            0x15, 0x34, 0x12,
            0x01,
            1, 2, 0xFF,
            0xCD, 0xAB, 0x02, 0x01,
            0, 0, 0,
            65, 10,
        ])
        self.assertEqual(rom, beklenen)

    def test_bassiz_kip_ve_test_portu(self):
        """--test kipinde işlemci yazmaçlarının ve PORT_TEST_SONUC (0xA0FF) çıkış kodunun çalıştığını doğrula."""
        s = calistir("""
        .BAŞLANGIÇ 0x0200
        15 T YÜKLE
        27 TOPLA
        T X AKTAR
        DUR
        """)
        self.assertBitti(s)
        self.assertRegs(s, T=42, X=42)

        # PORT_TEST_SONUC (0xA0FF -> port 0xFF) portuna 0'dan farklı bir değer yazılırsa test hatası (exit 1) döner
        s_hata = calistir("""
        .BAŞLANGIÇ 0x0200
        7 T YÜKLE
        0xFF ÇIKIŞ
        """)
        self.assertEqual(s_hata.neden, "test_portu")
        self.assertEqual(s_hata.test_kodu, 7)
        self.assertEqual(s_hata.cikis_kodu, CIKIS_TEST_HATASI)

    def test_ornek_programlar_derleme_ve_calisma(self):
        """Mevcut 4 örnek programın (merhaba, toplam, kabuk, pong) derlendiğini ve çalıştığını doğrula."""
        with tempfile.TemporaryDirectory() as klasor:
            gecici = Path(klasor)

            # 1. toplam.asm: 1..10 toplamı = 55 (0x37) -> toplam_sonuc etiketine yazar ve DUR ile biter
            toplam_rom = derle_metin((KOK / "programlar" / "toplam.asm").read_text(encoding="utf-8"))
            toplam_yol = gecici / "toplam.rom"
            toplam_yol.write_bytes(toplam_rom)
            sonuc_adresi = 0x0200 + len(toplam_rom) - 1
            s_toplam = calistir_rom(toplam_yol, max_cevrim=5000, dokum=[(sonuc_adresi, 1)])
            self.assertBitti(s_toplam)
            self.assertRegs(s_toplam, T=55)
            self.assertEqual(s_toplam.bellek(sonuc_adresi, 1), [55])

            # 2. merhaba.asm: ekrana başlık yazar ve DUR ile biter
            merhaba_rom = derle_metin((KOK / "programlar" / "merhaba.asm").read_text(encoding="utf-8"))
            merhaba_yol = gecici / "merhaba.rom"
            merhaba_yol.write_bytes(merhaba_rom)
            s_merhaba = calistir_rom(merhaba_yol, max_cevrim=5000, ekran=True)
            self.assertBitti(s_merhaba)
            self.assertIn("MERHABA DUNYA! TURK-8 CALISIYOR.", s_merhaba.ekran_metni())

            # 3. kabuk.asm ve pong.asm: sonsuz döngüde çalışan etkileşimli programlar;
            # ilk 5000 çevrimde geçersiz komuta düşmeden çalışmalı (zaman aşımı = sağlıklı döngü)
            for dosya in ("kabuk.asm", "pong.asm"):
                rom = derle_metin((KOK / "programlar" / dosya).read_text(encoding="utf-8"))
                yol = gecici / (dosya + ".rom")
                yol.write_bytes(rom)
                s = calistir_rom(yol, max_cevrim=5000)
                self.assertEqual(s.neden, "zaman_asimi", f"{dosya} beklenmedik şekilde durdu veya hata verdi: {s}")
                self.assertEqual(s.cikis_kodu, CIKIS_ZAMAN_ASIMI)


if __name__ == "__main__":
    unittest.main()
