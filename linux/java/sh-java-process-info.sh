#!/bin/bash

if [ -n "$1" ] ;then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]];then
        echo "Java运行的服务进程信息"
        exit 0
    else
        echo "参数无效"
    fi
fi


echo -e "\033[36m/////////////////////////////////////// sh-java-process-info.sh ////////////////////////////////////////////\033[0m"


jps
