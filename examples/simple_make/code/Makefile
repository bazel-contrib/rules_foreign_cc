BUILD_DIR=build
default all $(BUILD_DIR)/lib/liba.a: liba.cpp liba.h
	rm -rf $(BUILD_DIR)/lib
	mkdir -p $(BUILD_DIR)/lib
	clang -fPIC -o $(BUILD_DIR)/lib/liba.o -c liba.cpp
	ar rcs $(BUILD_DIR)/lib/liba.a $(BUILD_DIR)/lib/liba.o

install: $(BUILD_DIR)/lib/liba.a
	cp -rv $(BUILD_DIR)/lib --target-directory=$(PREFIX)
	cp liba.h --target-directory=$(PREFIX)/include
