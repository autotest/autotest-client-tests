#!/bin/bash

cwd=`pwd`
`ls $cwd > tests`
rpm -qa > rpms

while read pkg
do
    pkg_dtls=`echo $pkg |  awk '{print $1}' FS="-[0-9]"`
    sed -i "s/$pkg/$pkg_dtls/g" rpms
done < rpms
while read test
do
    if [ $test == "shared" ] 
    then
        continue
    fi
    test_dir=`echo $test | tr -d '\n'`
    if [ `echo $test_dir | cut -f 2 -d '_'` == "test" ]
    then
        test_dir=`echo $test_dir | cut -f 1 -d '_'`
    else
        test_dir=`echo $test_dir | tr '_' '-'`
    fi
    grep "$test_dir" rpms >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        sed "1,/'''/d" $test/control | sed "1,/'''/d" >>control_tmp
    else
        test_dir=`echo $test_dir | tr '-' '_'`
        grep "$test_dir" rpms >/dev/null 2>&1 && 
            sed "1,/'''/d" $test/control | sed "1,/'''/d" >>control_tmp
    fi
done < tests
grep "import" control_tmp > import_list
cat import_list control_tmp > tests
cat tests | awk '!v[$0]{ print; v[$0]=1 }' > control_list
rm -f rpms tests import_list control_tmp
