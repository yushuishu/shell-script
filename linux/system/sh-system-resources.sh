#!/bin/bash

if [ -n "$1" ] ;then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]];then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：CPU使用信息、内存使用信息、磁盘使用信息、TCP连接状态"
        echo "参数：无"
        echo "************************************************************************"
        exit 0
    else
        echo "参数无效：请使用 --help、-help、-h 查看脚本使用说明"
    fi
fi


echo -e "\033[36m/////////////////////////////////////// sh-system-resources.sh ////////////////////////////////////////////\033[0m"

# CPU
function cpu_use() {
    echo -e "\033[35m========================== CPU使用信息: =========================\033[0m"
    util=$(vmstat | awk '{if(NR==3)print $13+$14}')
    iowait=$(vmstat | awk '{if(NR==3)print $16}')
    echo "CPU  - 使用率：${util}% ,等待磁盘IO相应使用率：${iowait}:${iowait}%"
}

#内存
function memory_use() {
    echo -e "\033[35m========================= 内存使用信息: =========================\033[0m"
    total=$(free -m | awk '{if(NR==2)printf "%.1f",$2/1024}')
    used=$(free -m | awk '{if(NR==2) printf "%.1f",($2-$NF)/1024}')
    available=$(free -m | awk '{if(NR==2) printf "%.1f",$NF/1024}')
    echo "内存 - 总大小: ${total}G , 使用: ${used}G , 剩余: ${available}G"
}

#磁盘
function disk_use() {
    echo -e "\033[35m========================= 磁盘使用信息: =========================\033[0m"
    fs=$(df -h | awk '/^\/dev/{print $1}')
    for p in $fs; do
        mounted=$(df -h | awk '$1=="'$p'"{print $NF}')
        size=$(df -h | awk '$1=="'$p'"{print $2}')
        used=$(df -h | awk '$1=="'$p'"{print $3}')
        used_percent=$(df -h | awk '$1=="'$p'"{print $5}')
        echo "硬盘 - 挂载点: $mounted , 总大小: $size , 使用: $used , 使用率: $used_percent"
    done
}

# tcp状态
function tcp_status() {
    echo -e "\033[35m========================== TCP连接状态: =========================\033[0m"
  summary=$(ss -antp | awk '{status[$1]++}END{for(i in status) printf i":"status[i]" "}')
  echo "TCP连接状态 - $summary"
}

cpu_use
memory_use
disk_use
tcp_status