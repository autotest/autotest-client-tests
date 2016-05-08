#!/usr/bin/sh

find . -name "control" > package_test_list
var_path=`pwd`
while read file
do
    grep -r "test_path=path" $file >/dev/null 2>&1 &&
        sed -i "s:path\\s\=\\s'':path \= '${var_path}':g"  $file
done < package_test_list
rm -f package_test_list
