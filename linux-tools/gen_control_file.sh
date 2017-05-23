#!/bin/bash
MAPPER_FILE="shared/mapper_file"
grep -i "ubuntu" /etc/*release >/dev/null 2>&1
if [ $? -eq 0 ];then
        dpkg -l | awk -F" " '{print $2}' | awk -F":" '{print $1}' > rpms
else
        rpm -qa > rpms
fi


cwd=`pwd`
`ls $cwd > tests`
cp rpms rpms_1

generic_fn()
{
while read pkg
do
 pkg_dtls=`echo $pkg | awk '{print $1}' FS="/"`
 sed -i s'/$pkg/$pkg_dtls/g' rpms_1
done < rpms
while read test
do
    if [ "$test" == "shared" ]
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
    grep "$test_dir" rpms_1 >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        if [ -e $test/control ]
        then
            sed "1,/'''/d" $test/control | sed "1,/'''/d" >>control_tmp
        fi
    else
        test_dir=`echo $test_dir | tr '-' '_'`
        grep "$test_dir" rpms_1 >/dev/null 2>&1
        if [[ $? -eq 0 && -e $test/control ]]
        then
            sed "1,/'''/d" $test/control | sed "1,/'''/d" >>control_tmp
        fi
    fi
done < tests
}

ubuntu_control_file()
{
while read line
do
        #echo $line
        if [ -z "$line" ];then

                continue
        fi

        grep "$line" $MAPPER_FILE >/dev/null 2>&1
        if [ $? -eq 0 ];then
                grep -w "$line" $MAPPER_FILE|awk '{print $1}'|egrep -v "^#|grep"|awk -F"=" '{print $1}' >> data_file
                cat data_file|sort|uniq  > new_data_file
                while read final_line
                do
                        ls |grep -iw "$final_line" >>final_data_file
                done<new_data_file

        fi
done <rpms
cat final_data_file|sort|uniq > final_call
while read test
do
    grep -iw "$test" final_call >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        if [ -e "$test"/control ]
        then
            sed "1,/'''/d" "$test"/control | sed "1,/'''/d" >>control_tmp
        fi
    else
        grep -iw "$test" final_call >/dev/null 2>&1
        if [ $? -eq 0 ] && [ -e "$test"/control ]
        then
            sed "1,/'''/d" "$test"/control | sed "1,/'''/d" >>control_tmp
        fi
    fi

done<tests
rm data_file new_data_file final_data_file final_call
}

generic_fn
grep -i "ubuntu" /etc/*release >/dev/null 2>&1
if [ $? -eq 0 ];then
        ubuntu_control_file
fi
grep "import" control_tmp > import_list
cat import_list control_tmp > tests
cat tests | awk '!v[$0]{ print; v[$0]=1 }' > control_list
rm -f rpms_1 rpms tests import_list control_tmp

