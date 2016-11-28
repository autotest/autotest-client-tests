#!/bin/sh
cd /tmp
gzip -d asmcli.tgz
tar -xf asmcli.tar
mkdir -p /opt/IBMmpcli/bin
mkdir -p /opt/IBMmpcli/data
mkdir -p /opt/IBMmpcli/lib
mkdir -p /opt/IBMmpcli/classes
mkdir -p /opt/IBMmpcli/classes/extensions
mkdir -p /opt/IBMmpcli/samplescripts
chmod 750 /opt/IBMmpcli
cp asmcli/*.xml   /opt/IBMmpcli/data
cp asmcli/*.xsd   /opt/IBMmpcli/data
cp asmcli/MPCLI.sh   /opt/IBMmpcli/bin
chmod 750         /opt/IBMmpcli/bin/MPCLI.sh
cp asmcli/*.SMDef /opt/IBMmpcli/classes/extensions
cp asmcli/*.jar   /opt/IBMmpcli/classes
cp asmcli/libSPDriverBase.so /opt/IBMmpcli/lib
cp asmcli/libHawkDriverBase.so /opt/IBMmpcli/lib
cp asmcli/libIPMIDriverBase.so /opt/IBMmpcli/lib
cp asmcli/*.script /opt/IBMmpcli/samplescripts
rm -f asmcli.tar
rm -rf asmcli

# Set up Shared Library with Linker
cp /etc/ld.so.conf /etc/ld.so.conf.pre.ibm.mpcli
sed -e '/IBMmpcli/d' < /etc/ld.so.conf > /etc/ld.so.conf.new.ibm.mpcli
echo -e "/opt/IBMmpcli/lib" >> /etc/ld.so.conf.new.ibm.mpcli
rm -f /etc/ld.so.conf
mv /etc/ld.so.conf.new.ibm.mpcli /etc/ld.so.conf
ln -sf /opt/IBMmpcli/lib/libSPDriverBase.so /usr/lib/libSPDriverBase.so
ln -sf /opt/IBMmpcli/lib/libHawkDriverBase.so /usr/lib/libHawkDriverBase.so
ln -sf /opt/IBMmpcli/lib/libIPMIDriverBase.so /usr/lib/libIPMIDriverBase.so
/sbin/ldconfig
