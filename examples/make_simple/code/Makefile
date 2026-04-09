BUILD_DIR := build-out

all: $(BUILD_DIR)/lib/liba.a

$(BUILD_DIR)/lib/liba.a: liba.cpp liba.h
	rm -rf $(BUILD_DIR)/lib
	mkdir -p $(BUILD_DIR)/lib
	bash $(CC_WRAPPER) compile liba.cpp $(BUILD_DIR)/lib/liba.o
	bash $(CC_WRAPPER) static_link $(BUILD_DIR)/lib/liba.o $(BUILD_DIR)/lib/liba.a

.PHONY: all

install: $(BUILD_DIR)/lib/liba.a
	mkdir -p $(PREFIX)/lib $(PREFIX)/include $(PREFIX)/share
	cp -rpv $(BUILD_DIR)/lib $(PREFIX)
	cp -p liba.h $(PREFIX)/include
	cp $(README_DIR)/README.md $(PREFIX)/share/

clean:
	rm -rf $(BUILD_DIR)

.PHONY: clean

test: all

.PHONY: test
