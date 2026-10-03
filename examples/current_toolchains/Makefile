# Exercises a tool reached through a `current_*_toolchain` hub listed in
# `toolchains`: `$(MESON)` is a Python launcher that needs its runfiles tree
# at run time, so this only works if the hub's tool targets are staged.
all: meson_version.txt

meson_version.txt:
	$(MESON_BIN) --version > $@

install: all
	mkdir -p $(PREFIX)
	cp meson_version.txt $(PREFIX)/

test: all
	test -s meson_version.txt

clean:
	rm -f meson_version.txt

.PHONY: all clean install test
