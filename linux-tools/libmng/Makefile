CFLAGS +=  -I.. -D_DEBUG=0
LDFLAGS +=  -L../.libs

SRCS=$(wildcard *.c)
OBJS=$(patsubst %.c,%.o,$(SRCS))

TARGETS = mngtest

.c.o: 
	$(CC) $(CFLAGS) -c $< 

all:	$(TARGETS)

install: 
	ln -f libmng.sh ../../bin/

uninstall:
	rm -rf ../../bin/libmng.sh ; done

mngtest:	$(OBJS)	
	$(CC) $(CFLAGS) $(LDFLAGS) -lmng -o mngtest $(OBJS)

.PHONY: clean
clean:
	@rm -f *.o
	@for exefile in $(TARGETS) ; do rm -f $$exefile ; done
