###########################################################################
# name of file  : Makefile                                                #
# description   : make(1) description file for Perl-pod-perldoc package   #
###########################################################################


TARGETS=test_perldoc.sh

all:

install: all
	for i in $(TARGETS) ; do ln -f $$i ../../bin || break ; done

uninstall:
	for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done

clean:
	@rm -f *~
