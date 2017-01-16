CPPFLAGS += -DLT_DIAL_linux
LDFLAGS += LTlib.o

TARGETS = LTbasic LTnlink LTsock LTunix LTdnlc LTlock

all:	LTlib.o $(TARGETS)
	echo $(TARGETS) > ../testlist

install:	all

uninstall:

%.o : %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
	rm -rf *~ *.o $(TARGETS)
