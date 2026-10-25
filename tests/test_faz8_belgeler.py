# -*- coding: utf-8 -*-
"""
Faz 8 Testleri: Dokümantasyon, ISA Tablosu Senkronizasyonu, Wiki ve CI Doğrulaması
"""

import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from yardimci import KOK, isa


class TestFaz8BelgelerVeWiki(unittest.TestCase):
    """4 ana .md belgesinin, otomatik üretilen ISA v1.0 tablolarının, Wiki sayfalarının ve CI iş akışının doğrulanması."""

    def test_ana_belgeler_ve_ci_mevcut(self):
        """README.md, OKUBENI.md, KULLANIM_KILAVUZU.md, USER_MANUAL.md ve .github/workflows/ci.yml mevcut olmalı."""
        zorunlu_dosyalar = [
            KOK / "README.md",
            KOK / "OKUBENI.md",
            KOK / "KULLANIM_KILAVUZU.md",
            KOK / "USER_MANUAL.md",
            KOK / ".github" / "workflows" / "ci.yml",
        ]
        for yol in zorunlu_dosyalar:
            self.assertTrue(yol.is_file(), f"Eksik dosya: {yol.name}")
            icerik = yol.read_text(encoding="utf-8")
            self.assertGreater(len(icerik), 200, f"Dosya çok kısa: {yol.name}")

    def test_isa_tablosu_belgelerle_birebir_senkron(self):
        """araclar/isa.py içindeki 91 komutun tamamı KULLANIM_KILAVUZU.md, USER_MANUAL.md ve TR/EN Wiki içinde yer almalı."""
        kilavuz_tr = (KOK / "KULLANIM_KILAVUZU.md").read_text(encoding="utf-8")
        kilavuz_en = (KOK / "USER_MANUAL.md").read_text(encoding="utf-8")
        wiki_isa_tr = (KOK / "wiki" / "Komut-Seti-Referansi-ISA-v1.md").read_text(encoding="utf-8")
        wiki_isa_en = (KOK / "wiki" / "Instruction-Set-Reference-ISA-v1.md").read_text(encoding="utf-8")

        for komut in isa.KOMUTLAR:
            op_hex = f"`0x{komut.opkod:02X}`"
            c_adi = f"`{komut.ad}`"
            desen = f"`{komut.desen}`"
            for ad, metin in [
                ("KULLANIM_KILAVUZU.md", kilavuz_tr),
                ("USER_MANUAL.md", kilavuz_en),
                ("wiki/Komut-Seti-Referansi-ISA-v1.md", wiki_isa_tr),
                ("wiki/Instruction-Set-Reference-ISA-v1.md", wiki_isa_en),
            ]:
                self.assertIn(op_hex, metin, f"{ad} içinde {op_hex} eksik!")
                self.assertIn(c_adi, metin, f"{ad} içinde {c_adi} eksik!")
                self.assertIn(desen, metin, f"{ad} içinde {desen} eksik!")

    def test_wiki_sayfalari_tam_ve_tutarli(self):
        """wiki/ dizinindeki tüm Türkçe ve İngilizce ansiklopedik sayfalar oluşturulmuş olmalı."""
        wiki_sayfalari = [
            "Home.md",
            "_Sidebar.md",
            "_Footer.md",
            # Türkçe sayfalar
            "Mimari-ve-Bellek-Haritasi.md",
            "Komut-Seti-Referansi-ISA-v1.md",
            "BIOS-ve-Kabuk-Komutlari.md",
            "Sanal-Disk-Sistemi.md",
            "Makine-Ici-Monitor-ve-Assembler.md",
            "Turkce-BASIC-Kilavuzu.md",
            # İngilizce birebir karşılık sayfalar
            "Architecture-and-Memory-Map.md",
            "Instruction-Set-Reference-ISA-v1.md",
            "BIOS-and-Shell-Commands.md",
            "Virtual-Disk-System.md",
            "On-Machine-Monitor-and-Assembler.md",
            "Turkish-BASIC-Guide.md",
            "English-Reference.md",
        ]
        for sayfa in wiki_sayfalari:
            yol = KOK / "wiki" / sayfa
            self.assertTrue(yol.is_file(), f"Eksik Wiki sayfası: {sayfa}")
            self.assertGreater(len(yol.read_text(encoding="utf-8")), 100)


if __name__ == "__main__":
    unittest.main()

