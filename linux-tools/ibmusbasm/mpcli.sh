#!/bin/sh
#
# This is essentially a copy pf MPCLI.sh from the MPCLI utility package.
# Asside from this comment only one line has been added --
# the setting JRE_DIR to use the JRE shipped with MCP.
#
ROOTDIR=/opt/IBMmpcli 
JRE_DIR=${ROOTDIR}/IBMJava2-142-JRE
JRE_DIR=/opt/ibm/java2-i386-50/     # This line added for MCP5.1
JRE_DIR=/opt/ibm/java2-x86_64-50

PATH=${ROOTDIR}/bin:${JRE_DIR}/jre/bin:"$PATH"
export PATH
CLASSPATH=${ROOTDIR}/classfix:${ROOTDIR}/classes/asmcli.jar:${ROOTDIR}/classes/asmlibrary.jar:${ROOTDIR}/classes/asmlightpath.jar:"$CLASSPATH"
export CLASSPATH
LD_LIBRARY_PATH=${JRE_DIR}/jre/bin:${JRE_DIR}/jre/bin/classic:"$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH
#Store current working directory
IBMMPCLI_CURRENT_DIR=`pwd`
#Run the MPCLI application from its designated location
cd ${ROOTDIR}/bin
${JRE_DIR}/jre/bin/java -classpath "$CLASSPATH" com.ibm.sysmgt.app.cli.ASMCLIMain $*
#Restore user's working directory
cd "$IBMMPCLI_CURRENT_DIR"
