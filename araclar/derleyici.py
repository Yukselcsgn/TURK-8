#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRK-8 İki Geçişli Türkçe Assembler (Çevirici)
Doğal Türkçe söz dizimine (Özne/Nesne -> Yüklem Sonda) sahip .asm dosyalarını
TÜRK-8 ikili makine koduna (.rom) çevirir.
"""

import sys
import re

def sayi_coz(metin, etiketler=None, adres=0):
    metin = metin.strip()
    if metin.startswith("'") and metin.endswith("'") and len(metin) == 3:
        return ord(metin[1])
    if metin.startswith("0x") or metin.startswith("0X"):
        return int(metin, 16)
    if metin.startswith("$"):
        return int(metin[1:], 16)
    if metin.startswith("#"):
        return sayi_coz(metin[1:], etiketler, adres)
    if metin.isdigit() or (metin.startswith("-") and metin[1:].isdigit()):
        return int(metin)
    if etiketler and metin in etiketler:
        return etiketler[metin]
    raise ValueError(f"Geçersiz sayı veya tanımsız etiket: '{metin}'")

def derle(kaynak_metin):
    satirlar = kaynak_metin.splitlines()

    # 1. GEÇİŞ: Etiketleri ve Adresleri Topla
    etiketler = {}
    mevcut_adres = 0x0200 # Varsayılan RAM başlangıcı
    temizlenmis_komutlar = []

    for satir_no, ham_satir in enumerate(satirlar, 1):
        satir = ham_satir.split(";")[0].strip()
        if not satir:
            continue

        # Etiket tanımları: örn. "basla:" veya "dongu:"
        while ":" in satir:
            ilk_tirnak = satir.find('"')
            iki_nokta = satir.find(':')
            if ilk_tirnak != -1 and iki_nokta > ilk_tirnak:
                # İki nokta tırnak işaretinin içinde, etiket değil
                break
            parcalar = satir.split(":", 1)
            etiket = parcalar[0].strip()
            etiketler[etiket] = mevcut_adres
            satir = parcalar[1].strip()
            if not satir:
                break

        if not satir:
            continue

        # Direktifler
        ust_satir = satir.upper()
        if ust_satir.startswith(".BAŞLANGIÇ") or ust_satir.startswith(".BASLANGIC") or ust_satir.startswith(".ORG"):
            param = satir.split(None, 1)[1].strip()
            mevcut_adres = sayi_coz(param)
            continue
        elif ust_satir.startswith(".METİN") or ust_satir.startswith(".METIN"):
            # Metin direktifi: örn: .METİN "MERHABA"
            eslesme = re.search(r'"([^"]*)"', satir)
            if eslesme:
                metin = eslesme.group(1)
                boyut = len(metin.encode("latin-1", "replace"))
                temizlenmis_komutlar.append((mevcut_adres, satir_no, "METIN", metin))
                mevcut_adres += boyut
            continue
        elif ust_satir.startswith(".BAYT") or ust_satir.startswith(".BYTE"):
            param = satir.split(None, 1)[1].strip()
            parcalar = [p.strip() for p in param.split(",") if p.strip()]
            for p in parcalar:
                temizlenmis_komutlar.append((mevcut_adres, satir_no, "BAYT", p))
                mevcut_adres += 1
            continue
        elif ust_satir.startswith(".KELİME") or ust_satir.startswith(".KELIME"):
            param = satir.split(None, 1)[1].strip()
            temizlenmis_komutlar.append((mevcut_adres, satir_no, "KELIME", param))
            mevcut_adres += 2
            continue

        # Normal Komutlar
        # Komut boyutunu tahmin et
        kelimeler = satir.split()
        son_kelime = kelimeler[-1].upper()

        boyut = 1
        # 3 baytlık komutlar (16-bit adres alanlar)
        if any(son_kelime.endswith(k) for k in ["ATLA", "ÇAĞIR", "CAGIR"]):
            boyut = 3
        elif "SAKLA" in ust_satir:
            boyut = 3
        elif "YÜKLE" in ust_satir or "YUKLE" in ust_satir:
            if "[" in satir:
                boyut = 3
            else:
                boyut = 2
        elif any(k in ust_satir for k in ["TOPLA", "ÇIKAR", "CIKAR", "KARŞILAŞTIR", "KARSILASTIR", "VE", "VEYA", "ÖZELVEYA", "OZELVEYA", "GİRİŞ", "GIRIS", "ÇIKIŞ", "CIKIS"]):
            if "[" in satir:
                boyut = 3
            elif any(k in ust_satir for k in ["ARTIR", "AZALT", "DEĞİLLE", "DEGILLE", "KAYDIR"]):
                boyut = 1
            else:
                boyut = 2
        elif any(k in ust_satir for k in ["ARTIR", "AZALT", "DEĞİLLE", "DEGILLE", "KAYDIR", "AKTAR", "İT", "IT", "ÇEK", "CEK", "DÖN", "DON", "DUR", "BOŞ", "BOS", "KESME", "SIFIRLA"]):
            boyut = 1

        temizlenmis_komutlar.append((mevcut_adres, satir_no, "KOMUT", satir))
        mevcut_adres += boyut

    # 2. GEÇİŞ: Makine Kodunu (Baytları) Üret
    baytlar = bytearray()
    program_baslangic = temizlenmis_komutlar[0][0] if temizlenmis_komutlar else 0x0200

    su_anki_adres = program_baslangic

    for adres, satir_no, tip, satir in temizlenmis_komutlar:
        # Gerekirse aradaki boşlukları 0 ile doldur
        while su_anki_adres < adres:
            baytlar.append(0x00)
            su_anki_adres += 1

        if tip == "METIN":
            for c in satir.encode("latin-1", "replace"):
                baytlar.append(c)
                su_anki_adres += 1
            continue
        elif tip == "BAYT":
            val = sayi_coz(satir, etiketler, adres) & 0xFF
            baytlar.append(val)
            su_anki_adres += 1
            continue
        elif tip == "KELIME":
            val = sayi_coz(satir, etiketler, adres) & 0xFFFF
            baytlar.append(val & 0xFF)
            baytlar.append((val >> 8) & 0xFF)
            su_anki_adres += 2
            continue

        # Komut Çözümleme
        ust = satir.upper().strip()

        # 1-Baytlık Komutlar
        if ust in ["BOŞ", "BOS", "NOP"]:
            baytlar.append(0x00)
            su_anki_adres += 1
        elif ust in ["DUR", "HALT", "HLT"]:
            baytlar.append(0x01)
            su_anki_adres += 1
        elif ust in ["KESME AÇ", "KESME AC"]:
            baytlar.append(0x02)
            su_anki_adres += 1
        elif ust in ["KESME KAPAT"]:
            baytlar.append(0x03)
            su_anki_adres += 1
        elif ust in ["SIFIRLA"]:
            baytlar.append(0x04)
            su_anki_adres += 1

        # Aktarma
        elif ust in ["X T AKTAR"]:
            baytlar.append(0x19)
            su_anki_adres += 1
        elif ust in ["T X AKTAR"]:
            baytlar.append(0x1A)
            su_anki_adres += 1
        elif ust in ["Y T AKTAR"]:
            baytlar.append(0x1B)
            su_anki_adres += 1
        elif ust in ["T Y AKTAR"]:
            baytlar.append(0x1C)
            su_anki_adres += 1

        # Artır / Azalt
        elif ust in ["T ARTIR"]:
            baytlar.append(0x35)
            su_anki_adres += 1
        elif ust in ["X ARTIR"]:
            baytlar.append(0x36)
            su_anki_adres += 1
        elif ust in ["Y ARTIR"]:
            baytlar.append(0x37)
            su_anki_adres += 1
        elif ust in ["T AZALT"]:
            baytlar.append(0x38)
            su_anki_adres += 1
        elif ust in ["X AZALT"]:
            baytlar.append(0x39)
            su_anki_adres += 1
        elif ust in ["Y AZALT"]:
            baytlar.append(0x3A)
            su_anki_adres += 1

        # Mantık & Bit
        elif ust in ["T DEĞİLLE", "T DEGILLE"]:
            baytlar.append(0x53)
            su_anki_adres += 1
        elif ust in ["T SOLA KAYDIR"]:
            baytlar.append(0x54)
            su_anki_adres += 1
        elif ust in ["T SAĞA KAYDIR", "T SAGA KAYDIR"]:
            baytlar.append(0x55)
            su_anki_adres += 1

        # Yığın & Dönüş
        elif ust in ["DÖN", "DON"]:
            baytlar.append(0x91)
            su_anki_adres += 1
        elif ust in ["KESMEDEN DÖN", "KESMEDEN DON"]:
            baytlar.append(0x92)
            su_anki_adres += 1
        elif ust in ["T İT", "T IT"]:
            baytlar.append(0x93)
            su_anki_adres += 1
        elif ust in ["T ÇEK", "T CEK"]:
            baytlar.append(0x94)
            su_anki_adres += 1
        elif ust in ["DURUM İT", "DURUM IT"]:
            baytlar.append(0x95)
            su_anki_adres += 1
        elif ust in ["DURUM ÇEK", "DURUM CEK"]:
            baytlar.append(0x96)
            su_anki_adres += 1

        # 2-Baytlık ve 3-Baytlık Komutlar
        elif "YÜKLE" in ust or "YUKLE" in ust:
            if "[[" in ust:
                ic = re.search(r'\[\[([^\]]+)\]\]', satir).group(1).strip()
                hedef_adr = sayi_coz(ic, etiketler, adres)
                baytlar.append(0x1D)
                baytlar.append(hedef_adr & 0xFF)
                baytlar.append((hedef_adr >> 8) & 0xFF)
                su_anki_adres += 3
            elif "[adres + X]" in ust or ("[" in ust and "+ X" in ust):
                # İndeksli yükleme
                ic = re.search(r'\[([^\]]+)\]', satir).group(1)
                ana_etiket = ic.replace("+ X", "").replace("+X", "").strip()
                hedef_adr = sayi_coz(ana_etiket, etiketler, adres)
                baytlar.append(0x12)
                baytlar.append(hedef_adr & 0xFF)
                baytlar.append((hedef_adr >> 8) & 0xFF)
                su_anki_adres += 3
            elif "[" in ust:
                # Adresten yükleme
                ic = re.search(r'\[([^\]]+)\]', satir).group(1).strip()
                hedef_adr = sayi_coz(ic, etiketler, adres)
                baytlar.append(0x11)
                baytlar.append(hedef_adr & 0xFF)
                baytlar.append((hedef_adr >> 8) & 0xFF)
                su_anki_adres += 3
            elif " X " in ust:
                # Sayı X YÜKLE
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x13)
                baytlar.append(val)
                su_anki_adres += 2
            elif " Y " in ust:
                # Sayı Y YÜKLE
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x14)
                baytlar.append(val)
                su_anki_adres += 2
            else:
                # Sayı T YÜKLE
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x10)
                baytlar.append(val)
                su_anki_adres += 2

        elif "SAKLA" in ust:
            if "[[" in ust:
                ic = re.search(r'\[\[([^\]]+)\]\]', satir).group(1).strip()
                hedef_adr = sayi_coz(ic, etiketler, adres)
                baytlar.append(0x1E)
                baytlar.append(hedef_adr & 0xFF)
                baytlar.append((hedef_adr >> 8) & 0xFF)
                su_anki_adres += 3
            else:
                ic = re.search(r'\[([^\]]+)\]', satir).group(1).strip()
                if "+ X" in ic.upper() or "+X" in ic.upper():
                    ana_etiket = ic.upper().replace("+ X", "").replace("+X", "").strip()
                    hedef_adr = sayi_coz(ana_etiket, etiketler, adres)
                    baytlar.append(0x16) # T [adres + X] SAKLA
                    baytlar.append(hedef_adr & 0xFF)
                    baytlar.append((hedef_adr >> 8) & 0xFF)
                    su_anki_adres += 3
                elif ust.startswith("X"):
                    hedef_adr = sayi_coz(ic, etiketler, adres)
                    baytlar.append(0x17)
                    baytlar.append(hedef_adr & 0xFF)
                    baytlar.append((hedef_adr >> 8) & 0xFF)
                    su_anki_adres += 3
                elif ust.startswith("Y"):
                    hedef_adr = sayi_coz(ic, etiketler, adres)
                    baytlar.append(0x18)
                    baytlar.append(hedef_adr & 0xFF)
                    baytlar.append((hedef_adr >> 8) & 0xFF)
                    su_anki_adres += 3
                else:
                    hedef_adr = sayi_coz(ic, etiketler, adres)
                    baytlar.append(0x15) # T [adres] SAKLA
                    baytlar.append(hedef_adr & 0xFF)
                    baytlar.append((hedef_adr >> 8) & 0xFF)
                    su_anki_adres += 3

        # Aritmetik
        elif "TOPLA" in ust:
            if "ELDEYLE" in ust:
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x32)
                baytlar.append(val)
                su_anki_adres += 2
            elif "[" in ust:
                ic = re.search(r'\[([^\]]+)\]', satir).group(1).strip()
                hedef_adr = sayi_coz(ic, etiketler, adres)
                baytlar.append(0x31)
                baytlar.append(hedef_adr & 0xFF)
                baytlar.append((hedef_adr >> 8) & 0xFF)
                su_anki_adres += 3
            else:
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x30)
                baytlar.append(val)
                su_anki_adres += 2

        elif "ÇIKAR" in ust or "CIKAR" in ust:
            if "[" in ust:
                ic = re.search(r'\[([^\]]+)\]', satir).group(1).strip()
                hedef_adr = sayi_coz(ic, etiketler, adres)
                baytlar.append(0x34)
                baytlar.append(hedef_adr & 0xFF)
                baytlar.append((hedef_adr >> 8) & 0xFF)
                su_anki_adres += 3
            else:
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x33)
                baytlar.append(val)
                su_anki_adres += 2

        elif "KARŞILAŞTIR" in ust or "KARSILASTIR" in ust:
            if " X " in ust:
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x3C)
                baytlar.append(val)
                su_anki_adres += 2
            else:
                val_str = satir.split()[0]
                val = sayi_coz(val_str, etiketler, adres) & 0xFF
                baytlar.append(0x3B)
                baytlar.append(val)
                su_anki_adres += 2

        # Mantık
        elif ust.endswith(" VE"):
            val_str = satir.split()[0]
            val = sayi_coz(val_str, etiketler, adres) & 0xFF
            baytlar.append(0x50)
            baytlar.append(val)
            su_anki_adres += 2
        elif ust.endswith(" VEYA"):
            val_str = satir.split()[0]
            val = sayi_coz(val_str, etiketler, adres) & 0xFF
            baytlar.append(0x51)
            baytlar.append(val)
            su_anki_adres += 2
        elif ust.endswith(" ÖZELVEYA") or ust.endswith(" OZELVEYA"):
            val_str = satir.split()[0]
            val = sayi_coz(val_str, etiketler, adres) & 0xFF
            baytlar.append(0x52)
            baytlar.append(val)
            su_anki_adres += 2

        # Atlamalar
        elif "ATLA" in ust:
            hedef_str = satir.split()[0]
            hedef_adr = sayi_coz(hedef_str, etiketler, adres)
            if "EŞİTSE" in ust or "ESITSE" in ust:
                baytlar.append(0x71)
            elif "FARKLIYSA" in ust:
                baytlar.append(0x72)
            elif "BÜYÜKSE" in ust or "BUYUKSE" in ust:
                baytlar.append(0x73)
            elif "KÜÇÜKSE" in ust or "KUCUKSE" in ust:
                baytlar.append(0x74)
            elif "ELDE VARSA" in ust:
                baytlar.append(0x75)
            else:
                baytlar.append(0x70)
            baytlar.append(hedef_adr & 0xFF)
            baytlar.append((hedef_adr >> 8) & 0xFF)
            su_anki_adres += 3

        # Fonksiyon Çağırma
        elif "ÇAĞIR" in ust or "CAGIR" in ust:
            hedef_str = satir.split()[0]
            hedef_adr = sayi_coz(hedef_str, etiketler, adres)
            baytlar.append(0x90)
            baytlar.append(hedef_adr & 0xFF)
            baytlar.append((hedef_adr >> 8) & 0xFF)
            su_anki_adres += 3

        # Port I/O
        elif "GİRİŞ" in ust or "GIRIS" in ust:
            port_str = satir.split()[0]
            port = sayi_coz(port_str, etiketler, adres) & 0xFF
            baytlar.append(0xB0)
            baytlar.append(port)
            su_anki_adres += 2
        elif "ÇIKIŞ" in ust or "CIKIS" in ust:
            port_str = satir.split()[0]
            port = sayi_coz(port_str, etiketler, adres) & 0xFF
            baytlar.append(0xB1)
            baytlar.append(port)
            su_anki_adres += 2

        else:
            raise SyntaxError(f"Satır {satir_no}: Anlaşılamayan Türkçe söz dizimi: '{satir}'")

    return program_baslangic, baytlar

def main():
    if len(sys.argv) < 2:
        print("TÜRK-8 Türkçe Assembler")
        print("Kullanım: python3 araclar/derleyici.py <kaynak.asm> [hedef.rom]")
        sys.exit(1)

    kaynak_dosya = sys.argv[1]
    hedef_dosya = sys.argv[2] if len(sys.argv) > 2 else kaynak_dosya.rsplit(".", 1)[0] + ".rom"

    with open(kaynak_dosya, "r", encoding="utf-8") as f:
        kaynak = f.read()

    try:
        baslangic, baytlar = derle(kaynak)
        with open(hedef_dosya, "wb") as f:
            f.write(baytlar)
        print(f"[BAŞARILI] '{kaynak_dosya}' derlendi -> '{hedef_dosya}'")
        print(f"[BİLGİ] Başlangıç Adresi: 0x{baslangic:04X}, Toplam Boyut: {len(baytlar)} bayt")
    except Exception as e:
        print(f"[HATA] {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

