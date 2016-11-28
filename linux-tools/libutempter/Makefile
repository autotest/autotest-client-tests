CFLAGS+=  -Wall -g
SRCS=$(wildcard *.c)
CTARGETS=$(patsubst %.c,%,$(SRCS))
TARGETS=utempter.sh

all: $(CTARGETS)

install:
	@for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done ;

uninstall:
	@for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done ;

clean:
	rm -f $(CTARGETS)
