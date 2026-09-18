PREFIX ?= /usr/local

all: libhello.a

libhello.a: hello.o
	$(AR) rcs $@ $^

hello.o: hello.c
	$(CC) $(CFLAGS) -c -o $@ $<

install: libhello.a
	mkdir -p $(PREFIX)/lib
	cp libhello.a $(PREFIX)/lib/

.PHONY: all install
