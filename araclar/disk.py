#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRK-8 Sanal Disk Aracı (disk.t8)

Disk Biçimi (Toplam 64 KB = 256 sektör x 256 bayt):
- Sektör 0 (0x0000 - 0x00FF): 16 girişli kök dizin tablosu (her giriş 16 bayt)
  - [0..7]   : Dosya adı (8 bayt, büyük ASCII, sağdan boşluk ' ' dolgulu;
               0x00 ise giriş hiç kullanılmamış/boş, 0xE5 ise silinmiş)
  - [8]      : Başlangıç sektörü (1..255)
  - [9]      : Sektör sayısı (1..255)
  - [10..11] : Yükleme adresi (16-bit küçük uçlu, varsayılan 0x0200)
  - [12..13] : Bayt cinsinden gerçek boyut (16-bit küçük uçlu)
  - [14]     : Dosya tipi / bayraklar (1 = çalıştırılabilir .rom, 2 = veri/kaynak)
  - [15]     : Ayrılmış (0)
- Sektör 1..255: Dosya veri sektörleri

Komut satırı kullanımı:
  python3 araclar/disk.py olustur disk.t8 [AD:dosya.asm_veya_rom ...]
  python3 araclar/disk.py liste disk.t8
  python3 araclar/disk.py ekle disk.t8 AD dosya.rom [--adres 0x0200]
  python3 araclar/disk.py cikar disk.t8 AD hedef.rom
  python3 araclar/disk.py sil disk.t8 AD
"""

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import derleyici  # noqa: E402
import isa  # noqa: E402

SEKTOR_BOYUTU = 256
TOPLAM_SEKTOR = 256
DISK_BOYUTU = SEKTOR_BOYUTU * TOPLAM_SEKTOR
DIZIN_GIRIS_SAYISI = 16
DIZIN_GIRIS_BOYUTU = 16
VARSAYILAN_YUKLE_ADRESI = 0x0200


def dosya_adi_katla(ad):
    """Dosya adını 8 baytlık büyük ASCII (sağdan boşluk dolgulu) bayt dizisine çevirir."""
    temiz = isa.katla(ad.strip())
    if not temiz or len(temiz) > 8:
        raise ValueError("dosya adı 1..8 karakter olmalı: '%s'" % ad)
    for c in temiz:
        if not ("A" <= c <= "Z" or "0" <= c <= "9" or c in ("_", "-")):
            raise ValueError("dosya adında geçersiz karakter: '%s'" % ad)
    return temiz.ljust(8, " ").encode("ascii")


def bos_imaj_olustur():
    """64 KB sıfır dolu boş bir disk imajı döndürür."""
    return bytearray(DISK_BOYUTU)


def dizin_oku(imaj):
    """Disk imajının 0. sektöründeki etkin dizin girişlerini döndürür.

    Dönüş: [{"indeks": i, "ad": str, "baslangic": int, "sektor_sayisi": int,
             "adres": int, "boyut": int, "tip": int}, ...]
    """
    if len(imaj) < SEKTOR_BOYUTU:
        return []
    liste = []
    for i in range(DIZIN_GIRIS_SAYISI):
        ofset = i * DIZIN_GIRIS_BOYUTU
        giris = imaj[ofset:ofset + DIZIN_GIRIS_BOYUTU]
        ilk = giris[0]
        if ilk == 0x00 or ilk == 0xE5:
            continue
        ad = bytes(giris[0:8]).decode("ascii", errors="replace").rstrip(" ")
        baslangic = giris[8]
        sektor_sayisi = giris[9]
        adres = giris[10] | (giris[11] << 8)
        boyut = giris[12] | (giris[13] << 8)
        tip = giris[14]
        liste.append({
            "indeks": i,
            "ad": ad,
            "baslangic": baslangic,
            "sektor_sayisi": sektor_sayisi,
            "adres": adres,
            "boyut": boyut,
            "tip": tip,
        })
    return liste


def dosya_sil(imaj, ad):
    """Belirtilen adlı dosyayı dizinden siler (ilk baytını 0xE5 yapar). Bulunursa True döner."""
    hedef_ad = isa.katla(ad.strip())
    for i in range(DIZIN_GIRIS_SAYISI):
        ofset = i * DIZIN_GIRIS_BOYUTU
        ilk = imaj[ofset]
        if ilk in (0x00, 0xE5):
            continue
        mevcut_ad = bytes(imaj[ofset:ofset + 8]).decode("ascii", errors="replace").rstrip(" ")
        if mevcut_ad == hedef_ad:
            imaj[ofset] = 0xE5
            return True
    return False


def dosya_ekle(imaj, ad, veri, yukle_adresi=VARSAYILAN_YUKLE_ADRESI, tip=1):
    """İmaja yeni bir dosya ekler (aynı ad varsa üzerine yazar)."""
    ad_bayt = dosya_adi_katla(ad)
    veri = bytes(veri)
    if len(veri) == 0:
        veri = b"\x00"
    boyut = len(veri)
    sektor_sayisi = (boyut + SEKTOR_BOYUTU - 1) // SEKTOR_BOYUTU

    # Aynı isimde dosya varsa önce sil
    dosya_sil(imaj, ad)

    # Boş dizin girişi bul ve mevcut en yüksek kullanılan sektörü hesapla
    bos_giris = None
    son_sektor = 1
    for i in range(DIZIN_GIRIS_SAYISI):
        ofset = i * DIZIN_GIRIS_BOYUTU
        ilk = imaj[ofset]
        if ilk in (0x00, 0xE5):
            if bos_giris is None:
                bos_giris = i
        else:
            bitis = imaj[ofset + 8] + imaj[ofset + 9]
            if bitis > son_sektor:
                son_sektor = bitis

    if bos_giris is None:
        raise RuntimeError("disk dizini dolu (en fazla 16 dosya)")
    if son_sektor + sektor_sayisi > TOPLAM_SEKTOR:
        raise RuntimeError("diskte yeterli boş sektör yok")

    # Dizin girişini yaz
    ofset = bos_giris * DIZIN_GIRIS_BOYUTU
    imaj[ofset:ofset + 8] = ad_bayt
    imaj[ofset + 8] = son_sektor
    imaj[ofset + 9] = sektor_sayisi
    imaj[ofset + 10] = yukle_adresi & 0xFF
    imaj[ofset + 11] = (yukle_adresi >> 8) & 0xFF
    imaj[ofset + 12] = boyut & 0xFF
    imaj[ofset + 13] = (boyut >> 8) & 0xFF
    imaj[ofset + 14] = tip & 0xFF
    imaj[ofset + 15] = 0

    # Veri sektörlerini yaz
    veri_ofset = son_sektor * SEKTOR_BOYUTU
    ayrilan_bayt = sektor_sayisi * SEKTOR_BOYUTU
    imaj[veri_ofset:veri_ofset + ayrilan_bayt] = b"\x00" * ayrilan_bayt
    imaj[veri_ofset:veri_ofset + boyut] = veri


def dosya_cikar(imaj, ad):
    """Diskteki dosyayı (veri_baytlari, giris_sozlugu) olarak döndürür."""
    hedef_ad = isa.katla(ad.strip())
    for g in dizin_oku(imaj):
        if g["ad"] == hedef_ad:
            bas = g["baslangic"] * SEKTOR_BOYUTU
            return bytes(imaj[bas:bas + g["boyut"]]), g
    raise KeyError("dosya bulunamadı: '%s'" % ad)


def _kaynaktan_rom_ve_adres(yol):
    p = Path(yol)
    if p.suffix.lower() == ".asm":
        baslangic, veri = derleyici.derle(p.read_text(encoding="utf-8"))
        return bytes(veri), baslangic
    return p.read_bytes(), VARSAYILAN_YUKLE_ADRESI


def imaj_yukle(yol):
    p = Path(yol)
    if not p.exists():
        return bos_imaj_olustur()
    veri = bytearray(p.read_bytes())
    if len(veri) < DISK_BOYUTU:
        veri.extend(b"\x00" * (DISK_BOYUTU - len(veri)))
    return veri[:DISK_BOYUTU]


def imaj_kaydet(yol, imaj):
    Path(yol).write_bytes(bytes(imaj))


def main(argv=None):
    ap = argparse.ArgumentParser(description="TÜRK-8 Sanal Disk Aracı (disk.t8)")
    alt = ap.add_subparsers(dest="komut", required=True)

    p_olustur = alt.add_parser("olustur", help="Yeni disk.t8 imajı oluşturur ve dosyaları ekler")
    p_olustur.add_argument("disk", help="disk imajı yolu (örn. disk.t8)")
    p_olustur.add_argument("dosyalar", nargs="*", help="[AD:]dosya.asm/.rom çiftleri")

    p_liste = alt.add_parser("liste", help="Diskteki dosyaları listeler")
    p_liste.add_argument("disk", help="disk imajı yolu")

    p_ekle = alt.add_parser("ekle", help="Diske .rom veya .asm dosyası ekler")
    p_ekle.add_argument("disk", help="disk imajı yolu")
    p_ekle.add_argument("ad", help="diskteki dosya adı (en çok 8 karakter)")
    p_ekle.add_argument("kaynak", help="eklenecek .rom veya .asm dosyası")
    p_ekle.add_argument("--adres", type=lambda x: int(x, 0), default=None, help="yükleme adresi")

    p_cikar = alt.add_parser("cikar", help="Diskten dosyayı dışarı çıkarır")
    p_cikar.add_argument("disk", help="disk imajı yolu")
    p_cikar.add_argument("ad", help="diskteki dosya adı")
    p_cikar.add_argument("hedef", help="yazılacak hedef dosya yolu")

    p_sil = alt.add_parser("sil", help="Diskten dosyayı siler")
    p_sil.add_argument("disk", help="disk imajı yolu")
    p_sil.add_argument("ad", help="silinecek dosya adı")

    args = ap.parse_args(argv)

    if args.komut == "olustur":
        imaj = bos_imaj_olustur()
        for oge in args.dosyalar:
            if ":" in oge:
                ad, yol = oge.split(":", 1)
            else:
                yol = oge
                ad = Path(yol).stem
            veri, adr = _kaynaktan_rom_ve_adres(yol)
            dosya_ekle(imaj, ad, veri, yukle_adresi=adr)
        imaj_kaydet(args.disk, imaj)
        print("[DİSK] '%s' oluşturuldu (%d dosya)." % (args.disk, len(dizin_oku(imaj))))
        return 0

    if args.komut == "liste":
        imaj = imaj_yukle(args.disk)
        girisler = dizin_oku(imaj)
        print("AD       SEKTÖR  SAYI  ADRES   BOYUT")
        print("-------- ------  ----  ------  -----")
        for g in girisler:
            print("%-8s %6d  %4d  0x%04X  %5d B" % (
                g["ad"], g["baslangic"], g["sektor_sayisi"], g["adres"], g["boyut"]))
        print("Toplam: %d dosya" % len(girisler))
        return 0

    if args.komut == "ekle":
        imaj = imaj_yukle(args.disk)
        veri, adr = _kaynaktan_rom_ve_adres(args.kaynak)
        if args.adres is not None:
            adr = args.adres
        dosya_ekle(imaj, args.ad, veri, yukle_adresi=adr)
        imaj_kaydet(args.disk, imaj)
        print("[DİSK] '%s' -> '%s' eklendi (%d bayt, adres 0x%04X)." % (
            args.kaynak, isa.katla(args.ad), len(veri), adr))
        return 0

    if args.komut == "cikar":
        imaj = imaj_yukle(args.disk)
        veri, g = dosya_cikar(imaj, args.ad)
        Path(args.hedef).write_bytes(veri)
        print("[DİSK] '%s' -> '%s' çıkarıldı (%d bayt)." % (g["ad"], args.hedef, len(veri)))
        return 0

    if args.komut == "sil":
        imaj = imaj_yukle(args.disk)
        if not dosya_sil(imaj, args.ad):
            print("[HATA] Dosya bulunamadı: %s" % args.ad, file=sys.stderr)
            return 1
        imaj_kaydet(args.disk, imaj)
        print("[DİSK] '%s' silindi." % isa.katla(args.ad))
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())

