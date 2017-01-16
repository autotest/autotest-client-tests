#
# eval_tools.sh
#
# Output functions for script tests.  Source this from other test scripts
# to establish a standardized repertory of test functions.
#
#
# Except where noted, all functions return:
#	0	On success,	(Bourne Shell's ``true'')
#	non-0	Otherwise.
#
# Input arguments to each function are documented with each function.
#
#
# XXX  Suggestions:
#	DEBUG ON|OFF
#	dump CAPTURE output to stdout as well as to junkoutputfile.
#

#

#
# Only allow ourselves to be eval'ed once
#
if [ "x$EVAL_TOOLS_SH_EVALED" != "xyes" ]; then

EVAL_TOOLS_SH_EVALED=yes
 
if [ ! -s "`dirname $0`/TESTCONF.sh"  ] ; then
    tst_resm TBROK "Fatal error, No TESTCONF.sh was found."
    exit 3
fi
. `dirname $0`/TESTCONF.sh

#
# Variables used in global environment of calling script.
#
failcount=0
junkoutputfile="$SNMP_TMPDIR/output-`basename $0`$$"
seperator="-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
if [ -z "$OK_TO_SAVE_RESULT" ] ; then
    OK_TO_SAVE_RESULT=1
    export OK_TO_SAVE_RESULT
fi


#
# HEADER: returns a single line when SNMP_HEADERONLY mode and exits.
#
HEADER() {
    tst_resm TINFO "testing $* ... "
    headerStr="testing $*"
}


#------------------------------------ -o-
#
OUTPUT() {	# <any_arguments>
	cat <<GRONK


$*


GRONK
}

CAN_USLEEP() {
   if [ "$SNMP_CAN_USLEEP" = 0 -o "$SNMP_CAN_USLEEP" = 0 ] ; then
     return $SNMP_CAN_USLEEP
   fi
   sleep .1 > /dev/null 2>&1
   if [ $? = 0 ] ; then
     SNMP_CAN_USLEEP=1
   else
     SNMP_CAN_USLEEP=0
   fi
   export SNMP_CAN_USLEEP
}


#------------------------------------ -o-
#
SUCCESS() {	# <any_arguments>
	[ "$failcount" -ne 0 ] && return
	cat <<GROINK

SUCCESS: $*

GROINK
}



#------------------------------------ -o-
#
FAILED() {	# <return_value>, <any_arguments>
	[ "$1" -eq 0 ] && return
	shift

	failcount=`expr $failcount + 1`
	cat <<GRONIK

FAILED: $*

GRONIK
}

#------------------------------------ -o-
#
SKIP() {
	REMOVETESTDATA
	tst_resm TINFO "SKIPPED"
	exit 0
}

SKIPIFNOT() {
	grep "^#define $1 " $SNMP_UPDIR/include/net-snmp/net-snmp-config.h $SNMP_UPDIR/include/net-snmp/agent/mib_module_config.h $SNMP_UPDIR/include/net-snmp/agent/agent_module_config.h > /dev/null
	if [ $? != 0 ]; then
	    SKIP
	fi
}

SKIPIF() {
	grep "^#define $1 " $SNMP_UPDIR/include/net-snmp/net-snmp-config.h $SNMP_UPDIR/include/net-snmp/agent/mib_module_config.h $SNMP_UPDIR/include/net-snmp/agent/agent_module_config.h > /dev/null
	if [ $? = 0 ]; then
	    SKIP
	fi
}
	

#------------------------------------ -o-
#
VERIFY() {	# <path_to_file(s)>
	local	missingfiles=

	for f in $*; do
		[ -e "$f" ] && continue
		tst_resm TINFO "FAILED: Cannot find file \"$f\"."
		missingfiles=true
	done

	[ "$missingfiles" = true ] && exit 1000
}


#------------------------------------ -o-
#
STARTTEST() {	
	[ ! -e "$junkoutputfile" ] && {
		touch $junkoutputfile
		return
	}
	tst_resm TBROK "FAILED: Output file already exists: \"$junkoutputfile\"."
	exit 1000
}


#------------------------------------ -o-
#
STOPTEST() {
	rm -f "$junkoutputfile"
}


#------------------------------------ -o-
#
REMOVETESTDATA() {
	rm -rf $SNMP_TMPDIR/*

	if [ "x$SNMP_TMPDIR_REMOTE" != "x" ] ; then
	    ssh $SNMP_TEST_HOST rm -rf $SNMP_TMPDIR_REMOTE/*
	    rm -rf $SNMP_TMPDIR_REMOTE/*
	fi
}


#------------------------------------ -o-
# Captures output from command, and returns the command's exit code.
CAPTURE() {	# <command_with_arguments_to_execute>
    	echo $* >> $SNMP_TMPDIR/invoked

	if [ $SNMP_VERBOSE -gt 0 ]; then
		cat <<KNORG

EXECUTING: $*

KNORG

	fi
	( $* >$junkoutputfile 2>&1) >/dev/null
	RC=$?

	if [ $SNMP_VERBOSE -gt 1 ]; then
		echo "Command Output: "
		echo "MIBDIR $MIBDIRS $MIBS"
		echo "$seperator"
		cat $junkoutputfile | sed 's/^/  /'
		echo TINFO "$seperator"
	fi
	return $RC
}

#------------------------------------ -o-
# Delay to let processes settle
DELAY() {
    if [ "$SNMP_SLEEP" != "0" ] ; then
	sleep $SNMP_SLEEP
    fi
}

SAVE_RESULTS() {
   real_return_value=$return_value
}

#
# Checks the output result against what we expect.
#   Sets return_value to 0 or 1.
#
EXPECTRESULT() {
  if [ $OK_TO_SAVE_RESULT -ne 0 ] ; then
    if [ "$snmp_last_test_result" = "$1" ]; then
	return_value=0
    else
	return_value=1
    fi
  fi
}

#------------------------------------ -o-
# Returns: Count of matched lines.
#
CHECK() {	# <pattern_to_match>
    if [ $SNMP_VERBOSE -gt 0 ]; then
	echo "checking output for \"$*\"..."
    fi

    # if the output file is in $SNMP_TMPDIR_REMOTE, 
    # fetch it from remote host.
    if [ "`dirname $junkoutputfile`" = "$SNMP_TMPDIR_REMOTE" ] ; then
	scp $SNMP_TEST_HOST:$junkoutputfile $SNMP_TMPDIR_REMOTE &> /dev/null
    fi
    rval=`grep -c "$*" "$junkoutputfile" 2>/dev/null`

    if [ $SNMP_VERBOSE -gt 0 ]; then
	echo "$rval matches found"
    fi

    snmp_last_test_result=$rval
    EXPECTRESULT 1  # default
    return $rval
}

CHECKFILE() {
    local mcount

    file=$1
    if [ "x$file" = "x" ] ; then
        file=$junkoutputfile
    fi
    shift
    myoldjunkoutputfile="$junkoutputfile"
    junkoutputfile="$file"
    CHECK $*
    mcount=$?

    # one or more pattern matches are counted as success -- Wangtao
    if [ $OK_TO_SAVE_RESULT -ne 0 ] ; then
    	[ $mcount > 0 ] && return_value=0 || return_value=1
    fi

    junkoutputfile="$myoldjunkoutputfile"
}

CHECKTRAPD() {
    CHECKFILE $SNMP_SNMPTRAPD_LOG_FILE $@
}

CHECKTRAPDORDIE() {
    CHECKORDIE $@ $SNMP_SNMPTRAPD_LOG_FILE
}

CHECKAGENT() {
    CHECKFILE $SNMP_SNMPD_LOG_FILE $@
}

WAITFORAGENT() {
    WAITFOR "$@" $SNMP_SNMPD_LOG_FILE
}

WAITFORTRAPD() {
    WAITFOR "$@" $SNMP_SNMPTRAPD_LOG_FILE
}

WAITFOR() {
  ## save the previous save state and test result
    save_state=$OK_TO_SAVE_RESULT
    save_test=$snmp_last_test_result
    OK_TO_SAVE_RESULT=0

    sleeptime=$SNMP_SLEEP
    oldsleeptime=$SNMP_SLEEP
    if [ "$1" != "" ] ; then
	CAN_USLEEP
	if [ $SNMP_CAN_USLEEP = 1 ] ; then
	  sleeptime=`expr $SNMP_SLEEP '*' 50`
          SNMP_SLEEP=.1
	else 
	  sleeptime=`expr $SNMP_SLEEP '*' 5`
	  SNMP_SLEEP=1
	fi
        while [ $sleeptime -gt 0 ] ; do
	  if [ "$2" = "" ] ; then
            CHECK "$@"
          else
	    CHECKFILE "$2" "$1"
	  fi
          if [ "$snmp_last_test_result" != "" ] ; then
              if [ "$snmp_last_test_result" -gt 0 ] ; then
	         break;
              fi
	  fi
          DELAY
          sleeptime=`expr $sleeptime - 1`
        done
        SNMP_SLEEP=$oldsleeptime
    else
        if [ $SNMP_SLEEP -ne 0 ] ; then
	    sleep $SNMP_SLEEP
        fi
    fi

  ## restore the previous save state and test result
    OK_TO_SAVE_RESULT=$save_state
    snmp_last_test_result=$save_test
}    

# WAITFORORDIE "grep string" ["file"]
WAITFORORDIE() {
    WAITFOR "$1" "$2"
    if [ "$snmp_last_test_result" != 0 ] ; then
        FINISHED
    fi
}

# CHECKORDIE "grep string" ["file"] .. FAIL if "grep string" is *not* found
CHECKORDIE() {
    CHECKFILE "$2" "$1"
    if [ "$snmp_last_test_result" = 0 ] ; then
        FINISHED
    fi
}

# CHECKANDDIE "grep string" ["file"] .. FAIL if "grep string" *is* found
CHECKANDDIE() {
    CHECKFILE "$2" "$1"
    EXPECTRESULT 0 # make sure return_value gets set correctly
    if [ "$snmp_last_test_result" != 0 ] ; then
        FINISHED
    fi
}

#------------------------------------ -o-
# Returns: Count of matched lines.
#
CHECKEXACT() {	# <pattern_to_match_exactly>
	#rval=`grep -wc "$*" "$junkoutputfile" 2>/dev/null`

	#### Bug 64261 fix ######
	m="$*"
	rval=`grep -c "\([^a-zA-Z_0-9]\+$m[^a-zA-Z_0-9]*\$\)\|\(^[^a-zA-Z_0-9]*$m[^a-zA-Z_0-9]\+\)\|\(^$m$\)" "$junkoutputfile" 2>/dev/null`
	#### Bug Fix end ########

	snmp_last_test_result=$rval
	EXPECTRESULT 1  # default
	return $rval
}

CONFIGAGENT() {
    if [ "x$SNMP_CONFIG_FILE" = "x" ]; then
	tst_resm TBROK "$0: failed because var: SNMP_CONFIG_FILE wasn't set"
	exit 1;
    fi
    echo $* >> $SNMP_CONFIG_FILE
}

CONFIGTRAPD() {
    if [ "x$SNMPTRAPD_CONFIG_FILE" = "x" ]; then
	tst_resm TBROK "$0: failed because var: SNMPTRAPD_CONFIG_FILE wasn't set"
	exit 1;
    fi
    echo $* >> $SNMPTRAPD_CONFIG_FILE
}

#
# common to STARTAGENT and STARTTRAPD
# log command to "invoked" file
# delay after command to allow for settle
#
STARTPROG() {
    if [ "x$SNMP_TEST_HOST" != "x" ]; then
	COMMAND="ssh $SNMP_TEST_HOST $COMMAND"
    fi

    if [ $SNMP_VERBOSE -gt 1 ]; then
	echo "$CFG_FILE contains: "
	if [ -f $CFG_FILE ]; then
	    cat $CFG_FILE
	else
	    echo "[no config file]"
	fi
    fi
    if test -f $CFG_FILE; then
	COMMAND="$COMMAND -C -c $CFG_FILE"

	# if to start daemon remotely, first copy
	# CFG_FILE to remote.
	if [ "x$SNMP_TEST_HOST" != "x" ]; then
	    scp $CFG_FILE $SNMP_TEST_HOST:$SNMP_TMPDIR_REMOTE &> /dev/null
	fi
    fi
    if [ $SNMP_VERBOSE -gt 0 ]; then
	echo "running: $COMMAND"
    fi
    if [ "x$PORT_SPEC" != "x" ]; then
        COMMAND="$COMMAND $PORT_SPEC"
    fi
    echo $COMMAND >> $SNMP_TMPDIR/invoked
    if [ "x$OSTYPE" = "xmsys" ]; then
      ## $COMMAND > $LOG_FILE.stdout 2>&1 &
      COMMAND="cmd.exe //c start //min $COMMAND"
      start $COMMAND > $LOG_FILE.stdout 2>&1
    else
      $COMMAND > $LOG_FILE.stdout 2>&1
      if [ $? -ne 0 ] ; then
          tst_resm TFAIL "STARTPROG failed!"
          cat $LOG_FILE.stdout
          exit 357
      fi
    fi
}

#------------------------------------ -o-
STARTAGENT() {
    SNMPDSTARTED=1
    COMMAND="snmpd $SNMP_FLAGS -r -U -p $SNMP_SNMPD_PID_FILE -Lf $SNMP_SNMPD_LOG_FILE $AGENT_FLAGS"
    CFG_FILE=$SNMP_CONFIG_FILE
    LOG_FILE=$SNMP_SNMPD_LOG_FILE
    PORT_SPEC="$SNMP_SNMPD_PORT"
    if [ "x$SNMP_TRANSPORT_SPEC" != "x" ]; then
        PORT_SPEC="$SNMP_TRANSPORT_SPEC:$PORT_SPEC"
    fi
    STARTPROG
    WAITFORAGENT "NET-SNMP version"
}

#------------------------------------ -o-
STARTTRAPD() {
    TRAPDSTARTED=1
    COMMAND="snmptrapd -d -p $SNMP_SNMPTRAPD_PID_FILE -Lf $SNMP_SNMPTRAPD_LOG_FILE $TRAPD_FLAGS"
    CFG_FILE=$SNMPTRAPD_CONFIG_FILE
    LOG_FILE=$SNMP_SNMPTRAPD_LOG_FILE
    PORT_SPEC="$SNMP_SNMPTRAPD_PORT"
    if [ "x$SNMP_TRANSPORT_SPEC" != "x" ]; then
        PORT_SPEC="$SNMP_TRANSPORT_SPEC:$PORT_SPEC"
    fi
    STARTPROG
    WAITFORTRAPD "NET-SNMP version"
}


## used by STOPAGENT and STOPTRAPD
# delay before kill to allow previous action to finish
#    this is especially important for interaction between
#    master agent and sub agent.
STOPPROG() {
    if [ "x$SNMP_TEST_HOST" != "x" ]; then
	if ssh $SNMP_TEST_HOST [ -f $1 ]; then
	    COMMAND="ssh $SNMP_TEST_HOST kill -TERM `ssh $SNMP_TEST_HOST cat $1`"

	    echo $COMMAND >> $SNMP_TMPDIR/invoked
	    $COMMAND > /dev/null 2>&1
	    sleep 2
	fi
    else
        if [ "x$OSTYPE" = "xmsys" ]; then
          COMMAND="kill.exe `cat $1`"
        else
          COMMAND="kill -TERM `cat $1`"
        fi
        echo $COMMAND >> $SNMP_TMPDIR/invoked
        $COMMAND > /dev/null 2>&1
    fi
}

#------------------------------------ -o-
#
STOPAGENT() {
    SAVE_RESULTS
    STOPPROG $SNMP_SNMPD_PID_FILE
    if [ "x$OSTYPE" != "xmsys" ]; then
        WAITFORAGENT "shutting down"
    fi
    if [ $SNMP_VERBOSE -gt 1 ]; then
	echo "Agent Output:"
	echo "$seperator [stdout]"
	cat $SNMP_SNMPD_LOG_FILE.stdout
	echo "$seperator [logfile]"
	cat $SNMP_SNMPD_LOG_FILE
	echo "$seperator"
    fi
}

#------------------------------------ -o-
#
STOPTRAPD() {
    SAVE_RESULTS
    STOPPROG $SNMP_SNMPTRAPD_PID_FILE
    if [ "x$OSTYPE" != "xmsys" ]; then
        WAITFORTRAPD "Stopped"
    fi
    if [ $SNMP_VERBOSE -gt 1 ]; then
	echo "snmptrapd Output:"
	echo "$seperator [stdout]"
	cat $SNMP_SNMPTRAPD_LOG_FILE.stdout
	echo "$seperator [logfile]"
	cat $SNMP_SNMPTRAPD_LOG_FILE
	echo "$seperator"
    fi
}

#------------------------------------ -o-
#
FINISHED() {

    ## no more changes to test result.
    OK_TO_SAVE_RESULT=0

    if [ "$SNMPDSTARTED" = "1" ] ; then
      STOPAGENT
    fi
    if [ "$TRAPDSTARTED" = "1" ] ; then
      STOPTRAPD
    fi
    if [ "x$SNMP_TEST_HOST" = "x" ] ; then
	for pfile in $SNMP_TMPDIR/*pid* ; do
	    if [ "x$pfile" = "x$SNMP_TMPDIR/*pid*" ]; then
		ECHO "(no pid file(s) found) "
		break
	    fi
	    if [ ! -f $pfile ]; then
		ECHO "('$pfile' disappeared) "
		continue
	    fi
	    pid=`cat $pfile`
	    ps -e | egrep "^[	 ]*$pid[	 ]+" > /dev/null 2>&1
	    if [ $? = 0 ] ; then
		SNMP_SAVE_TMPDIR=yes
		if [ "x$OSTYPE" = "xmsys" ]; then
		    COMMAND="kill.exe $pid"
		else
		    COMMAND="kill -9 $pid"
		fi
		echo $COMMAND "($pfile)" >> $SNMP_TMPDIR/invoked
		$COMMAND > /dev/null 2>&1
		return_value=1
	    fi
	done
    else
	for pfile in `ssh $SNMP_TEST_HOST ls $SNMP_TMPDIR_REMOTE/*pid*` ; do
	    pid=`ssh $SNMP_TEST_HOST cat $pfile`
	    ssh $SNMP_TEST_HOST kill -9 $pid &> /dev/null
	    return_value=`expr 1 - $?`
	done
    fi

    if [ "x$real_return_value" != "x0" ]; then
	if [ -s core ] ; then
	    # XX hope that only one prog cores !
	    cp core $SNMP_TMPDIR/core.$$
	    rm -f core
	fi
	echo "$headerStr...FAIL" >> $SNMP_TMPDIR/invoked
	exit $real_return_value
    fi

    echo "$headerStr...ok" >> $SNMP_TMPDIR/invoked

    if [ "x$SNMP_SAVE_TMPDIR" != "xyes" ]; then
	REMOVETESTDATA
    fi
    exit $real_return_value
}

#------------------------------------ -o-
#
VERBOSE_OUT() {
    if [ $SNMP_VERBOSE > $1 ]; then
	shift
	echo -n "$*"
    fi
}

fi # Only allow ourselves to be eval'ed once
