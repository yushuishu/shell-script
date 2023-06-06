#!/bin/bash


echo -e "\033[36m/////////////////////////////////////// sh-system-info.sh ////////////////////////////////////////////\033[0m"


# 系统信息
function system_info() {
    echo -e "\033[35m======================= 操作系统内核信息: ======================\033[0m"
    uname -a
    echo -e "\033[35m=========================== 内核版本: ==========================\033[0m"
    cat /proc/version
    echo -e "\033[35m=========================== cpu个数: ===========================\033[0m"
    grep 'physical id' /proc/cpuinfo | sort -u | wc -l
    echo -e "\033[35m=========================== cpu核数: ===========================\033[0m"
    cat /proc/cpuinfo | grep "cpu cores" | uniq
    echo -e "\033[35m=========================== cpu型号: ===========================\033[0m"
    cat /proc/cpuinfo | grep 'model name' | uniq
    echo -e "\033[35m========================= cpu内核频率: =========================\033[0m"
    cat /proc/cpuinfo | grep MHz | uniq
    echo -e "\033[35m========================= cpu统计信息: =========================\033[0m"
    # 获取CPU信息
    cpu_info=$(lscpu)
    # 将英文字段替换为中文描述
    cpu_info=$(echo "$cpu_info" | sed 's/Architecture:/架构：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU(s):/CPU核数：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Thread(s) per core:/每个核心线程数：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Core(s) per socket:/每个插槽核心数：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Socket(s):/插槽数：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Vendor ID:/厂商ID：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU MHz:/CPU频率（MHz）：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU max MHz:/最大CPU频率（MHz）：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU min MHz:/最小CPU频率（MHz）：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU op-mode(s):/CPU操作模式：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Byte Order:/字节序：/')
    cpu_info=$(echo "$cpu_info" | sed 's/On-line CPU(s) list:/在线CPU列表：/')
    cpu_info=$(echo "$cpu_info" | sed 's/NUMA node\(s\):/NUMA节点数目：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Model name:/CPU型号名称：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU family:/CPU系列：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU max MHz:/最大CPU频率（MHz）：/')
    cpu_info=$(echo "$cpu_info" | sed 's/CPU min MHz:/最小CPU频率（MHz）：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Hypervisor vendor:/虚拟化平台厂商：/')
    cpu_info=$(echo "$cpu_info" | sed 's/Virtualization type:/虚拟化类型：/')
    # 输出CPU信息
    echo "$cpu_info"
}

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

system_info
cpu_use
memory_use
disk_use
tcp_status
