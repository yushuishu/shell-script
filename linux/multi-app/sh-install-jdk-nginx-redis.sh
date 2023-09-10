#!/bin/bash
shopt -s globstar

# 用途：安装jdk、nginx、redis

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
    echo "备注：jdk是环境软件，会安装到/usr/local目录下。"
    echo "          （安装jdk，使用 . 执行脚本，配置文件才生效，如果使用 sh 或 ./ 执行脚本，需要再次执行source /etc/profile）"
    echo "     nginx和redis都是应用型软件，会安装到/opt目录。"
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

echo "" >>sh-install-jdk-nginx-redis.log
echo "" >>sh-install-jdk-nginx-redis.log
echo "" >>sh-install-jdk-nginx-redis.log
echo "请查看日志文件：tail -1000f ./sh-install-jdk-nginx-redis.log"
# 定义动画持续时间（秒）
duration=1
# 计算每个点的间隔时间
interval=0.1
# 计算点的总数
total_points=$(bc <<<"$duration / $interval")
for ((i = 1; i <= total_points; i++)); do
  echo -n "===" >>sh-install-jdk-nginx-redis.log
  sleep $interval
done
echo "" >>sh-install-jdk-nginx-redis.log

# 检查防火墙是否开启，开放指定端口号
check_and_open_firewall_port() {
  port=\$1
  if [ -z "$port" ]; then
    echo "端口号为空！" >>sh-install-jdk-nginx-redis.log
    return
  fi
  firewall_status=$(sudo ufw status | grep "Status: active")
  if [[ -n "$firewall_status" ]]; then
    # 防火墙已启用，开放指定端口号
    sudo ufw allow $port
  fi
}

# 下载编译需要的库
function base_lib() {
  echo "" >>sh-install-jdk-nginx-redis.log
  echo -n "----------------------------------------------------------------》开始下载安装额外需要的库" >>sh-install-jdk-nginx-redis.log
  # 定义动画持续时间（秒）
  duration=0.6
  # 计算每个点的间隔时间
  interval=0.1
  # 计算点的总数
  total_points=$(bc <<<"$duration / $interval")
  for ((i = 1; i <= total_points; i++)); do
    echo -n "." >>sh-install-jdk-nginx-redis.log
    sleep $interval
  done

  apt-get update >>sh-install-jdk-nginx-redis.log && apt-get install -y gcc >>sh-install-jdk-nginx-redis.log && apt-get install -y libpcre3 libpcre3-dev >>sh-install-jdk-nginx-redis.log && apt-get install -y zlib1g zlib1g-dev >>sh-install-jdk-nginx-redis.log && apt-get install -y openssl >>sh-install-jdk-nginx-redis.log && apt-get install -y libssl-dev >>sh-install-jdk-nginx-redis.log && apt-get install -y make >>sh-install-jdk-nginx-redis.log

}

# 安装jdk
function jdk() {
  if [ -z "$JDK_PACKAGE_PATH" ]; then
    return
  fi
  echo "" >>sh-install-jdk-nginx-redis.log
  echo -n "----------------------------------------------------------------》开始安装jdk" >>sh-install-jdk-nginx-redis.log
  # 创建java目录，解压jdk
  # 定义动画持续时间（秒）
  duration=0.6
  # 计算每个点的间隔时间
  interval=0.1
  # 计算点的总数
  total_points=$(bc <<<"$duration / $interval")
  for ((i = 1; i <= total_points; i++)); do
    echo -n "." >>sh-install-jdk-nginx-redis.log
    sleep $interval
  done

  # 解压后的jdk目录名，如：jdk1.8.0_361
  jdk_dir_name=$(tar -tf "${JDK_PACKAGE_PATH}" | head -1 | cut -f1 -d"/")
  # 完整目录路径，如：/usr/local/java/jdk1.8.0_361
  jdk_home="${JDK_DIR}/${jdk_dir_name}"
  # 开始解压 jdk-8u361-linux-x64.tar.gz
  mkdir -p "${JDK_DIR}" && tar -xvf "${JDK_PACKAGE_PATH}" -C "${JDK_DIR}" >>sh-install-jdk-nginx-redis.log
  # 检查解压后的目录是否存在，以及是否为空
  if [ ! -d "$jdk_home" ]; then
    echo "解压jdk安装包失败" >>sh-install-jdk-nginx-redis.log
    return 1
  fi
  if [ -z "$(ls -A $jdk_home)" ]; then
    echo "解压jdk安装包失败，解压后的文件目录为空：${jdk_home}" >>sh-install-jdk-nginx-redis.log
    return 1
  fi

  # 配置环境变量
  echo "export JAVA_HOME=${jdk_home}" >>/etc/profile
  if [[ $jdk_dir_name == *"1.8"* ]]; then
    # jdk1.8版本系列，添加jre
    echo 'export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >>/etc/profile
  fi
  echo 'export PATH=$JAVA_HOME/bin:$PATH' >>/etc/profile
  echo 'export JAVA_HOME PATH' >>/etc/profile
  # 刷新配置文件
  source /etc/profile
  # 查看jdk
  java -version >>sh-install-jdk-nginx-redis.log
}

# 安装nginx
function nginx() {
  if [ -z "$NGINX_PACKAGE_PATH" ]; then
    return
  fi
  echo "" >>sh-install-jdk-nginx-redis.log
  echo -n "----------------------------------------------------------------》开始安装nginx" >>sh-install-jdk-nginx-redis.log
  # 定义动画持续时间（秒）
  duration=0.6
  # 计算每个点的间隔时间
  interval=0.1
  # 计算点的总数
  total_points=$(bc <<<"$duration / $interval")
  for ((i = 1; i <= total_points; i++)); do
    echo -n "." >>sh-install-jdk-nginx-redis.log
    sleep $interval
  done

  # 解压后的nginx目录名，如：nginx-1.18.0
  nginx_dir_name=$(tar -tf "${NGINX_PACKAGE_PATH}" | head -1 | cut -f1 -d"/")
  # 完整目录路径，如：/opt/nginx/nginx-1.18.0
  nginx_home="${NGINX_DIR}/${nginx_dir_name}"

  # 创建目录
  mkdir -p "${NGINX_DIR}/source-package" && tar -xvf "${NGINX_PACKAGE_PATH}" -C "${NGINX_DIR}/source-package" >>sh-install-jdk-nginx-redis.log
  # 检查解压后的目录是否存在，以及是否为空
  if [ ! -d "$NGINX_DIR/source-package" ]; then
    echo "解压nginx安装包失败" >>sh-install-jdk-nginx-redis.log
    return 1
  fi
  if [ -z "$(ls -A $NGINX_DIR/source-package)" ]; then
    echo "解压nginx安装包失败，解压后的文件目录为空：${NGINX_DIR}/source-package" >>sh-install-jdk-nginx-redis.log
    return 1
  fi

  # 配置、编译、安装
  "${NGINX_DIR}/source-package/${nginx_dir_name}/configure" --prefix="${nginx_home}" >>sh-install-jdk-nginx-redis.log && make >>sh-install-jdk-nginx-redis.log && make install >>sh-install-jdk-nginx-redis.log

  # 开启端口
  check_and_open_firewall_port 80

}

# 安装redis
function redis() {
  if [ -z "$REDIS_PACKAGE_PATH" ]; then
    return
  fi
  echo "" >>sh-install-jdk-nginx-redis.log
  echo -n "----------------------------------------------------------------》开始安装redis" >>sh-install-jdk-nginx-redis.log
  # 定义动画持续时间（秒）
  duration=0.6
  # 计算每个点的间隔时间
  interval=0.1
  # 计算点的总数
  total_points=$(bc <<<"$duration / $interval")
  for ((i = 1; i <= total_points; i++)); do
    echo -n "." >>sh-install-jdk-nginx-redis.log
    sleep $interval
  done

  # 解压后的redis目录名，如：redis-7.0.13
  redis_dir_name=$(tar -tf "${REDIS_PACKAGE_PATH}" | head -1 | cut -f1 -d"/")
  # 完整目录路径，如：/opt/redis/redis-7.0.13
  redis_home="${REDIS_DIR}/${redis_dir_name}"

  # 创建目录
  mkdir -p "${REDIS_DIR}/source-package" && tar -xvf "${REDIS_PACKAGE_PATH}" -C "${REDIS_DIR}/source-package" >>sh-install-jdk-nginx-redis.log
  # 检查解压后的目录是否存在，以及是否为空
  if [ ! -d "$REDIS_DIR/source-package" ]; then
    echo "解压redis安装包失败" >>sh-install-jdk-nginx-redis.log
    return 1
  fi
  if [ -z "$(ls -A $REDIS_DIR/source-package)" ]; then
    echo "解压redis安装包失败，解压后的文件目录为空：${REDIS_DIR}/source-package" >>sh-install-jdk-nginx-redis.log
    return 1
  fi

  # 编译、安装（Redis没有configure）
  make >>sh-install-jdk-nginx-redis.log && make install --prefix="${redis_home}" >>sh-install-jdk-nginx-redis.log

  # 开启端口
  check_and_open_firewall_port 6379

}

base_lib
jdk
nginx
redis
