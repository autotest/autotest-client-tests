#!/bin/sh
#
# eval_onescript.sh SCRIPT  [TESTNUMBER [HEADERONLY] ]
#
# Evaluates one test program, and helps it out by doing a bit of setup
# for it.  It does this by sourcing some configuration files for it
# first, and if it exited without calling FINISHED, call it.
#


. `dirname $0`/TESTCONF.sh
. $1

# We shouldn't get here...
# If we do, it means they didn't exit properly.
# So we will.
tst_resm TBROK "$1 FAILED to execute"
FINISHED
