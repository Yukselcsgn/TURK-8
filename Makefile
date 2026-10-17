CC = clang
CFLAGS = -Wall -Wextra -std=c11 -O2 -Iinclude

SRCS = src/ana.c src/islemci.c src/bellek.c src/komutlar.c src/ekran.c src/ayiklayici.c
OBJS = $(SRCS:.c=.o)
HEDEF = turk8

all: $(HEDEF)

$(HEDEF): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

temizle:
	rm -f src/*.o $(HEDEF)

clean: temizle

.PHONY: all temizle clean

