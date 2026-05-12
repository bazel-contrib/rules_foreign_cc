BUILD_DIR ?= build
CC ?= cc
CFLAGS ?=
CPPFLAGS ?=
LDFLAGS ?=
EXECUTABLE_LDFLAGS ?= $(LDFLAGS)
SHARED_LDFLAGS ?= $(LDFLAGS)
SHARED_LIBRARY_SUFFIX ?= so
SHARED_LIBRARY_LINK_FLAG ?= -shared
LEAF_INSTALL_NAME ?=
MIDDLE_INSTALL_NAME ?=

RUNTIME_CHAIN_CPPFLAGS = $(CPPFLAGS) -I$(SRC_DIR) -DRUNTIME_TEST_FAMILY=\"$(RUNTIME_TEST_FAMILY)\"
LEAF_SHARED_LIBRARY = libleaf.$(SHARED_LIBRARY_SUFFIX)
MIDDLE_SHARED_LIBRARY = libmiddle.$(SHARED_LIBRARY_SUFFIX)
LEAF_SHARED_LIBRARY_PATH = $(BUILD_DIR)/lib/$(LEAF_SHARED_LIBRARY)
MIDDLE_SHARED_LIBRARY_PATH = $(BUILD_DIR)/lib/$(MIDDLE_SHARED_LIBRARY)

.PHONY: all leaf middle app install-leaf install-middle install-app clean test

all: app

test: all

leaf: $(LEAF_SHARED_LIBRARY_PATH)

middle: leaf $(MIDDLE_SHARED_LIBRARY_PATH)

app: middle $(BUILD_DIR)/bin/runtime_app

$(LEAF_SHARED_LIBRARY_PATH): $(SRC_DIR)/leaf.c $(SRC_DIR)/runtime_chain.h
	mkdir -p $(BUILD_DIR)/lib
	$(CC) $(CFLAGS) $(RUNTIME_CHAIN_CPPFLAGS) -fPIC $(SHARED_LIBRARY_LINK_FLAG) $(SRC_DIR)/leaf.c -o $@ $(LEAF_INSTALL_NAME) $(SHARED_LDFLAGS)

$(MIDDLE_SHARED_LIBRARY_PATH): $(SRC_DIR)/middle.c $(SRC_DIR)/runtime_chain.h $(LEAF_SHARED_LIBRARY_PATH)
	mkdir -p $(BUILD_DIR)/lib
	$(CC) $(CFLAGS) $(RUNTIME_CHAIN_CPPFLAGS) -fPIC $(SHARED_LIBRARY_LINK_FLAG) $(SRC_DIR)/middle.c -o $@ $(MIDDLE_INSTALL_NAME) -L$(BUILD_DIR)/lib $(SHARED_LDFLAGS) -lleaf

$(BUILD_DIR)/bin/runtime_app: $(SRC_DIR)/app.c $(SRC_DIR)/runtime_chain.h $(MIDDLE_SHARED_LIBRARY_PATH)
	mkdir -p $(BUILD_DIR)/bin
	$(CC) $(CFLAGS) $(RUNTIME_CHAIN_CPPFLAGS) $(SRC_DIR)/app.c -o $@ -L$(BUILD_DIR)/lib $(EXECUTABLE_LDFLAGS) -lmiddle

install-leaf: leaf
	mkdir -p $(PREFIX)/lib
	cp -p $(LEAF_SHARED_LIBRARY_PATH) $(PREFIX)/lib/

install-middle: middle
	mkdir -p $(PREFIX)/lib
	cp -p $(MIDDLE_SHARED_LIBRARY_PATH) $(PREFIX)/lib/

install-app: app
	mkdir -p $(PREFIX)/bin
	cp -p $(BUILD_DIR)/bin/runtime_app $(PREFIX)/bin/

clean:
	rm -rf $(BUILD_DIR)
