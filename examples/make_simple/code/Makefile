BUILD_DIR=build-out

UNAME:=$(shell uname)
CXX_FLAGS :=

ifneq (,$(findstring NT, $(UNAME)))
  # If Windows
  CXX_FLAGS := /MD
else
  CXX_FLAGS := -fPIC
endif

default all $(BUILD_DIR)/lib/liba.a: liba.cpp liba.h
	rm -rf $(BUILD_DIR)/lib
	mkdir -p $(BUILD_DIR)/lib
	$(CLANG_WRAPPER) $(CXX_FLAGS) -o $(BUILD_DIR)/lib/liba.o -c liba.cpp
	ar rcs $(BUILD_DIR)/lib/liba.a $(BUILD_DIR)/lib/liba.o

install: $(BUILD_DIR)/lib/liba.a
	mkdir -p $(PREFIX)/lib $(PREFIX)/include
	cp -rpv $(BUILD_DIR)/lib $(PREFIX)
	cp -p liba.h $(PREFIX)/include
