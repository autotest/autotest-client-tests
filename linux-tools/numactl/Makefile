# all executables in this directory are considered testcases
TARGET=numactl.sh

all:

install:
	for i in $(TARGET) ; do ln -f $$i ../../bin/$$i || break ; done

uninstall:	
	for j in $(TARGET) ; do rm -f ../../bin/$$j ; done

clean:
	@rm -f *~
