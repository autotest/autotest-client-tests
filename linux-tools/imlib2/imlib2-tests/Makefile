# this is the list of all sub-tests

TESTS = imlib2_basic_display imlib2_convert 

imlib2_include=$(shell ../../imlib2-config --libs)
imlib2_cflags=$(shell ../../imlib2-config --cflags)
CFLAGS += -I../../src/lib $(imlib2_cflags)
LDFLAGS+= -L../../src/lib/.libs -lImlib2 $(imlib2_include)

all: $(TESTS)

install: all

uninstall:

clean:
	@rm -f $(TESTS) *.o *.so core
