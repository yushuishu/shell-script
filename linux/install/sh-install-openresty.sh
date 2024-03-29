#!/bin/bash
shopt -s globstar

# 用途：安装OpenResty（二进制安装方式）

# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
# OpenResty 安装目录：比如安装包为mysql-8.0.34-linux-glibc2.28-x86_64.tar.gz 安装成功后的目录为 /opt/openresty/mysql-8.0.34-linux-glibc2.28-x86_64
MYSQL_DIR="/opt/openresty"
MYSQL_PACKAGE_PATH=""
# ========================================================= 输入参数 =========================================================
if [ -n "$1" ]; then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：安装配置mysql8数据库，使用的是官网下载的Linux - Generic（通用版二进制安装包）"
        echo "参数：参数                    是否必传    说明"
        echo "      --help; -help; -h        false      查看脚本使用说明"
        echo "      -p                       true       指定安装包路径"
        echo "************************************************************************"
        exit 0
    else
        while getopts ":p:" opt; do
            case $opt in
            p)
                MYSQL_PACKAGE_PATH="$OPTARG"
                ;;
            \?)
                echo "无效的选项: -$OPTARG，请使用 --help、-help、-h 查看脚本使用说明"
                exit 0
                ;;
            esac
        done
    fi
fi

# =============================================================================================================================
echo -e "\033[36m/////////////////////////////////////// sh-install-openresty ////////////////////////////////////////////\033[0m"

# 检查安装包是否存在
if [ -z "$MYSQL_PACKAGE_PATH" ]; then
    echo "指定的安装包不存在"
    exit 0
fi