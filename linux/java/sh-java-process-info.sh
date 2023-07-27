#!/bin/bash

# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
KEY_WORD=""
# ========================================================= 输入参数 =========================================================
if [ -n "$1" ]; then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：获取系统基本信息、CPU信息、CPU使用信息、内存使用信息、磁盘使用信息、TCP连接状态"
        echo "参数：参数                    是否必传    说明"
        echo "      --help; -help; -h       false      查看脚本使用说明"
        echo "      *                       false      指定输出的内容，要包含的关键字"
        echo "备注：无"
        echo "************************************************************************"
        exit 0
    else
        KEY_WORD="$1"
    fi
fi
# =============================================================================================================================

echo -e "\033[36m/////////////////////////////////////// sh-java-process-info.sh ////////////////////////////////////////////\033[0m"

echo "-----------------------------------------------------------------------------------------------------"
java_processes=$(jps -l)
while IFS= read -r process; do
    pid=$(echo "$process" | awk '{print $1}')
    main_class=$(echo "$process" | awk '{print $2}')
    # 获取包含pid的进程信息
    processes=$(ps -ef | grep "$pid")
    # 格式化输出
    while read -r line; do
        command=$(echo "$line" | awk '{for(i=8;i<=NF;i++) printf "%s ", $i}')
        if ! echo "$command" | grep -q 'grep'; then
            if [[ -n "$KEY_WORD" ]] && ! echo "$main_class" | grep -q "$KEY_WORD" && ! echo "$command" | grep -q "$KEY_WORD"; then
                continue
            fi
            # 提取进程的详细信息
            pid=$(echo "$line" | awk '{print $2}')
            user=$(echo "$line" | awk '{print $1}')
            cpu=$(echo "$line" | awk '{print $3}')
            mem=$(echo "$line" | awk '{print $4}')
            # 格式化输出
            echo "进程ID: $pid  用户: $user  路径：$main_class"
            echo "CPU使用率: $cpu  内存使用率: $mem"
            echo "命令: $command"
            echo "-----------------------------------------------------------------------------------------------------"
        fi
    done <<<"$processes"
done <<<"$java_processes"
