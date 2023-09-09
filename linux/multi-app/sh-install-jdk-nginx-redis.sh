#!/bin/bash
shopt -s globstar

# 用途：备份pg数据库

# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
# jdk 安装目录：比如安装包为jdk-8u361-linux-x64.tar.gz 安装成功后的目录为 /usr/local/java/jdk1.8.0_361
JDK_DIR="/usr/local/java"
JDK_PACKAGE_PATH=""
# nginx 安装目录：比如安装包为nginx-1.18.0.tar.gz 安装成功后的目录为 /opt/nginx/nginx-1.18.0
NGINX_DIR="/opt/nginx"
NGINX_PACKAGE_PATH=""
# redis 安装目录：比如安装包为redis-7.0.13.tar.gz 安装成功后的目录为 /opt/redis/redis-7.0.13
REDIS_DIR="/opt/redis"
REDIS_PACKAGE_PATH=""
# ========================================================= 输入参数 =========================================================
if [ -n "$1" ]; then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：安装配置指定环境或软件，所有安装包都是各个官网下载的源码安装包"
        echo "参数：参数                    是否必传    说明"
        echo "      --help; -help; -h        false      查看脚本使用说明"
        echo "      -j                       false      安装Jdk-v17.x，指定安装包路径"
        echo "      -n                       false      安装Nginx，指定安装包路径"
        echo "      -r                       false      安装Redis-v7.x，指定安装包路径"
        echo "备注：jdk是环境软件，会安装到/usr/local 目录下，nginx和redis都是应用型软件，会安装到/opt目录。另外redis只安装单机服务，不会安装分布式集群环境"
        echo "************************************************************************"
        exit 0
    else
        while getopts ":j:n:r:" opt; do
            case $opt in
            j)
                JDK_PACKAGE_PATH="$OPTARG"
                echo "指定安装的Jdk: $OPTARG"
                ;;
            n)
                NGINX_PACKAGE_PATH="$OPTARG"
                echo "指定安装的Nginx: $OPTARG"
                ;;
            r)
                REDIS_PACKAGE_PATH="$OPTARG"
                echo "指定安装的Redis: $OPTARG"
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

echo -e "\033[36m/////////////////////////////////////// sh-install-jdk-nginx-redis ////////////////////////////////////////////\033[0m"

# 临时目录，解压源码进行编译时，存放临时的源码文件目录，安装成功之后，自动删除
mkdir -p /tmp/sh-install-jdk-nginx-redis


# 下载编译需要的库
function base() {
    echo "" > sh-install-jdk-nginx-redis.log
    echo -n "开始下载编译需要的库" > sh-install-jdk-nginx-redis.log
    # 定义动画持续时间（秒）
    duration=0.6
    # 计算每个点的间隔时间
    interval=0.1
    # 计算点的总数
    total_points=$(bc <<<"$duration / $interval")
    for ((i = 1; i <= total_points; i++)); do
        echo -n "."
        sleep $interval
    done

    apt-get update && apt-get install -y gcc > sh-install-jdk-nginx-redis.log && apt-get install -y libpcre3 libpcre3-dev > sh-install-jdk-nginx-redis.log && apt-get install -y zlib1g zlib1g-dev > sh-install-jdk-nginx-redis.log && apt-get install -y openssl > sh-install-jdk-nginx-redis.log && apt-get install -y libssl-dev > sh-install-jdk-nginx-redis.log && apt-get install -y make > sh-install-jdk-nginx-redis.log
}

# 安装jdk
function jdk() {
    echo "" > sh-install-jdk-nginx-redis.log
    echo -n "开始安装jdk" > sh-install-jdk-nginx-redis.log
    # 创建java目录，解压jdk
    # 定义动画持续时间（秒）
    duration=0.6
    # 计算每个点的间隔时间
    interval=0.1
    # 计算点的总数
    total_points=$(bc <<<"$duration / $interval")
    for ((i = 1; i <= total_points; i++)); do
        echo -n "."
        sleep $interval
    done

    # 解压后的jdk目录名，如：jdk1.8.0_361
    jdk_home_dir=$(tar -tf "${JDK_PACKAGE_PATH}" | head -1 | cut -f1 -d"/")
    # 完整目录路径，如：/usr/local/java/jdk1.8.0_361
    jdk_home="${JDK_DIR}/${jdk_home_dir}"
    # 开始解压 jdk-8u361-linux-x64.tar.gz
    mkdir -p "${JDK_DIR}" && tar -xvf "${JDK_PACKAGE_PATH}" -C "${JDK_DIR}"
    # 检查解压后的目录是否存在，以及是否为空
    if [ ! -d "$jdk_home" ]; then
        echo "解压jdk安装包失败" > sh-install-jdk-nginx-redis.log
        return 1
    fi
    if [ -z "$(ls -A $jdk_home)" ]; then
        echo "解压jdk安装包失败，解压后的文件目录为空：${jdk_home}" > sh-install-jdk-nginx-redis.log
        return 1
    fi

    # 配置环境变量
    vi >
    export JAVA_HOME=/usr/local/jdk1.8.0_231
    export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
    export PATH=$PATH:$JAVA_HOME/bin

}

# 安装nginx
function nginx() {
    echo "" > sh-install-jdk-nginx-redis.log
    echo -n "开始安装nginx" > sh-install-jdk-nginx-redis.log
    # 定义动画持续时间（秒）
    duration=0.6
    # 计算每个点的间隔时间
    interval=0.1
    # 计算点的总数
    total_points=$(bc <<<"$duration / $interval")
    for ((i = 1; i <= total_points; i++)); do
        echo -n "."
        sleep $interval
    done

    mkdir -p "${NGINX_DIR}" && tar -xvf "${NGINX_PACKAGE_PATH}" -C /tmp/sh-install-jdk-nginx-redis
    ./configure --prefix=/usr/local/nginx --sbin-path=/usr/local/nginx/sbin/nginx --conf-path=/etc/nginx/nginx.conf && make && make install

}

# 安装redis
function redis() {
    echo "" > sh-install-jdk-nginx-redis.log
    echo -n "开始安装redis" > sh-install-jdk-nginx-redis.log
    # 定义动画持续时间（秒）
    duration=0.6
    # 计算每个点的间隔时间
    interval=0.1
    # 计算点的总数
    total_points=$(bc <<<"$duration / $interval")
    for ((i = 1; i <= total_points; i++)); do
        echo -n "."
        sleep $interval
    done

    mkdir -p "${REDIS_DIR}" && tar -xvf "${REDIS_PACKAGE_PATH}" -C /tmp/sh-install-jdk-nginx-redis


}

base();
jdk();
nginx();
redis();










