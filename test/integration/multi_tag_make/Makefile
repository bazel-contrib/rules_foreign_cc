PREFIX ?= /usr/local

all: libhello.a

libhello.a: hello.o
	$(AR) rcs $@ $^

hello.o: hello.c
	$(CC) $(CFLAGS) -c -o $@ $<

install: libhello.a
	mkdir -p $(PREFIX)/lib
	cp libhello.a $(PREFIX)/lib/

# `clean` and `test` exist to satisfy checkmake's minphony rule, which requires
# both of every Makefile in the tree; examples/make_simple/code/Makefile carries
# them for the same reason. Nothing here invokes them -- this scenario's make
# toolchain is a fake that fails before reading this file at all.
clean:
	rm -f libhello.a hello.o

test: all

.PHONY: all clean install test
