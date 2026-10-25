CC ?= clang
PYTHON ?= python3
CFLAGS = -Wall -Wextra -std=c11 -O2 -Iinclude

SRCS = src/ana.c src/islemci.c src/bellek.c src/komutlar.c src/ekran.c src/ayiklayici.c
HEADERS = $(wildcard include/*.h)
OBJS = $(SRCS:.c=.o)
HEDEF = turk8
BIOS_ROM = roms/bios.rom
DISK_IMAJI = disk.t8

all: $(HEDEF) $(BIOS_ROM) $(DISK_IMAJI)

$(HEDEF): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

$(BIOS_ROM): roms/bios.asm araclar/derleyici.py araclar/isa.py
	$(PYTHON) araclar/derleyici.py roms/bios.asm $(BIOS_ROM)

$(DISK_IMAJI): araclar/disk.py araclar/derleyici.py programlar/merhaba.asm programlar/toplam.asm programlar/pong.asm programlar/kabuk.asm programlar/basic.asm
	$(PYTHON) araclar/disk.py olustur $(DISK_IMAJI) MERHABA:programlar/merhaba.asm TOPLAM:programlar/toplam.asm PONG:programlar/pong.asm KABUK:programlar/kabuk.asm BASIC:programlar/basic.asm

# Başlık dosyaları (.h) değişince .o dosyaları otomatik yeniden derlenir
%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

# Tüm testleri çalıştırır (derleyici + işlemci + program testleri)
test: $(HEDEF) $(BIOS_ROM) $(DISK_IMAJI)
	$(PYTHON) -m unittest discover -s tests -v

temizle:
	rm -f src/*.o src/*.d $(HEDEF) $(BIOS_ROM) $(DISK_IMAJI)

clean: temizle

.PHONY: all test temizle clean
