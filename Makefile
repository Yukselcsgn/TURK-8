CC ?= clang
PYTHON ?= python3
CFLAGS = -Wall -Wextra -std=c11 -O2 -Iinclude

SRCS = src/ana.c src/islemci.c src/bellek.c src/komutlar.c src/ekran.c src/ayiklayici.c
HEADERS = $(wildcard include/*.h)
OBJS = $(SRCS:.c=.o)
HEDEF = turk8
BIOS_ROM = roms/bios.rom

all: $(HEDEF) $(BIOS_ROM)

$(HEDEF): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

$(BIOS_ROM): roms/bios.asm araclar/derleyici.py araclar/isa.py
	$(PYTHON) araclar/derleyici.py roms/bios.asm $(BIOS_ROM)

# Başlık dosyaları (.h) değişince .o dosyaları otomatik yeniden derlenir
%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

# Tüm testleri çalıştırır (derleyici + işlemci + program testleri)
test: $(HEDEF) $(BIOS_ROM)
	$(PYTHON) -m unittest discover -s tests -v

temizle:
	rm -f src/*.o src/*.d $(HEDEF) $(BIOS_ROM)

clean: temizle

.PHONY: all test temizle clean
