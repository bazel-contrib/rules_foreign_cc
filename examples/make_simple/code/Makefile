BUILD_DIR=build-out
default all $(BUILD_DIR)/lib/liba.a: liba.cpp liba.h
	rm -rf $(BUILD_DIR)/lib
	mkdir -p $(BUILD_DIR)/lib
	$(CLANG_WRAPPER) -fPIC -o $(BUILD_DIR)/lib/liba.o -c liba.cpp
	ar rcs $(BUILD_DIR)/lib/liba.a $(BUILD_DIR)/lib/liba.o

install: $(BUILD_DIR)/lib/liba.a
	mkdir -p $(PREFIX)/lib $(PREFIX)/include
	cp -rv $(BUILD_DIR)/lib $(PREFIX)
	cp liba.h $(PREFIX)/include
