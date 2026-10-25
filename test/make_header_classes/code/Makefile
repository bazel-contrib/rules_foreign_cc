-include config.mk

.DEFAULT_GOAL := all
CHECK_FLAGS := -Werror -Wunused-parameter

.PHONY: all install clean
all:
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(CHECK_FLAGS) -c system.cc -o system.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(CHECK_FLAGS) -c quote.cc -o quote.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(CHECK_FLAGS) -c angle.cc -o angle.o
	@if $(CXX) $(CPPFLAGS) $(CXXFLAGS) $(CHECK_FLAGS) -c ordinary.cc -o ordinary.o >ordinary.log 2>&1; then \
		echo "ordinary-header warning unexpectedly accepted"; exit 1; \
	fi
	grep 'unused parameter' ordinary.log
	@if $(CXX) $(CPPFLAGS) $(CXXFLAGS) $(CHECK_FLAGS) -c angle_quote.cc -o angle_quote.o >angle_quote.log 2>&1; then \
		echo "angle include unexpectedly found a quote-only header"; exit 1; \
	fi
	grep 'quote_only.h' angle_quote.log
	printf '%s\n' 'system and SDK warnings suppressed; ordinary warnings rejected; quote and angle lookup preserved' >checks.txt

install: all
	mkdir -p $(PREFIX)
	cp checks.txt $(PREFIX)/checks.txt

clean:
	rm -f *.o *.log checks.txt
