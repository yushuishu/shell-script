#!/bin/bash
shopt -s globstar

# 用途：安装mysql（二进制安装方式）

# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
# mysql 安装目录：比如安装包为mysql-8.0.34-linux-glibc2.28-x86_64.tar.gz 安装成功后的目录为 /opt/mysql/mysql-8.0.34-linux-glibc2.28-x86_64
MYSQL_DIR="/opt/mysql"
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
echo -e "\033[36m/////////////////////////////////////// sh-install-mysql ////////////////////////////////////////////\033[0m"

# 检查安装包是否存在
if [ -z "$MYSQL_PACKAGE_PATH" ]; then
    echo "指定的安装包不存在"
    exit 0
fi

# 检查防火墙是否开启，开放指定端口号
check_and_open_firewall_port() {
    port=\$1
    if [ -z "$port" ]; then
        echo "端口号为空！"
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
    echo -n "开始下载安装额外需要的库"
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

    apt-get update && apt-get install -y gcc && apt-get install -y libpcre3 libpcre3-dev && apt-get install -y ruby && apt-get install -y zlib1g zlib1g-dev && apt-get install -y openssl && apt-get install -y libssl-dev && apt-get install -y make && apt-get install -y pkg-config && apt-get install -y libreadline-dev && apt-get upgrade -y libc6 && apt-get install -y libaio1 libaio-dev

}

function mysql() {
    # 解压后的mysql目录名，如：mysql-8.0.34-linux-glibc2.28-x86_64
    mysql_dir_name=$(tar -tf "${MYSQL_PACKAGE_PATH}" | head -1 | cut -f1 -d"/")
    # 完整目录路径，如：/opt/mysql/mysql-8.0.34-linux-glibc2.28-x86_64
    mysql_home="${MYSQL_DIR}/${mysql_dir_name}"

    # 创建目录，解压安装包
    tar -xvf "${MYSQL_PACKAGE_PATH}" -C "${MYSQL_DIR}"
    # 检查解压后的目录是否存在，以及是否为空
    if [ ! -d "$mysql_home" ]; then
        echo "解压mysql安装包失败"
        exit 0
    fi
    if [ -z "$(ls -A $mysql_home)" ]; then
        echo "解压mysql安装包失败，解压后的文件目录为空：${mysql_home}"
        exit 0
    fi

    # 创建用户组和用户
    echo "创建用户组和用户 ......"
    mkdir /home/mysql
    groupadd mysql
    useradd -d /home/mysql -g mysql -s /bin/bash mysql
    echo mysql:123456 | chpasswd
    chown -R mysql:mysql /home/mysql/

    # 配置文件 my.cnf
    echo "配置文件my.cnf ......"
    {
        echo "[mysql]"
        echo "# 设置mysql客户端默认字符集"
        echo "default-character-set=utf8"
        echo "#socket=${mysql_home}/mysql.sock"
        echo "[mysqld]"
        echo "# 禁用MySQL服务器进行DNS反解析，DNS反解析可能会导致连接延迟或潜在的安全问题"
        echo "# 禁用之后，mysql的授权表中就不能使用主机名了，只能使用IP。（也就是只能用IP地址检查客户端的登录，不能用主机名）"
        echo "skip-name-resolve=1"
        echo "#socket=${mysql_home}/mysql.sock"
        echo "# 设置3306端口"
        echo "port = 3306"
        echo "# 设置mysql的安装目录"
        echo "basedir=${mysql_home}"
        echo "# 设置mysql数据库的数据的存放目录"
        echo "datadir=${mysql_home}/data"
        echo "# 设置错误日志文件"
        echo "log_error=${mysql_home}/logs/error.log"
        echo "# 允许最大连接数，默认151"
        echo "max_connections=200"
        echo "# 设置InnoDB存储引擎的缓冲池大小，默认为128MB"
        echo "innodb_buffer_pool_size=128M"
        echo "# 设置默认字符集，支持一些特殊表情符号（特殊表情符占用4个字节）"
        echo "character-set-server=utf8mb4"
        echo "# 设置字符集对应一些排序等规则，注意要和character-set-server对应"
        echo "collation-server=utf8mb4_general_ci"
        echo "# 创建新表时将使用的默认存储引擎"
        echo "default-storage-engine=INNODB"
        echo "# 设置对sql语句大小写敏感，1表示不敏感（值可以是1或on)"
        echo "lower_case_table_names=1"
        echo "# 数据包发送的大小，如果有BLOB对象建议修改成1G"
        echo "max_allowed_packet=128M"
        echo "# 慢查询sql日志设置（开启值可以是1或on)"
        echo "slow_query_log=1"
        echo "slow_query_log_file=${mysql_home}/logs/slow.log"
        echo "# 设置慢查询执行的秒数，单位秒，必须达到此值可被记录"
        echo "long_query_time=10"
        echo "#[client]"
        echo "#socket=${mysql_home}/mysql.sock"
    }>> "${mysql_home}/my.cnf"

    # 配置文件 mysqladmin.cnf
    echo "配置文件mysqladmin.cnf ......"
    {
        echo "[mysqladmin]"
        echo "user=root"
        echo "password=123456"
    }>> "${mysql_home}/mysqladmin.cnf"

    # 创建mysql数据文件目录
    echo "创建mysql数据文件目录 ......"
    mkdir -p "${mysql_home}/data"
    # 创建日志文件
    echo "创建日志文件 ......"
    mkdir "${mysql_home}/logs"
    touch "${mysql_home}/logs/error.log"
    # 所属权限
    chown -R mysql:mysql "${mysql_home}"
    # 开放端口
    echo "开放端口3306 ......"
    check_and_open_firewall_port 3306

    # 初始化 MySQL
    echo "初始化MySQL ......"
    cd "${mysql_home}/bin" || { echo "Failed to change directory：${mysql_home}/bin"; exit 1; }
    ./mysqld --defaults-file="${mysql_home}/my.cnf" --initialize-insecure --user=mysql
    # 启动服务
    echo "启动服务 ......"
    ./mysqld_safe --defaults-file="${mysql_home}/my.cnf" --user=mysql >>"${mysql_home}/logs/mysqld_safe.log" 2>&1 &
    # 睡眠5秒钟，等待服务启动，并使用pgrep命令检查给出提示，如果不进行休眠，下一行命令执行失败
    sleep 5
    if pgrep mysqld
    then
        echo "MySQL server is running"
    else
        echo "MySQL is not running"
    fi

    # 登录客户端、设置root密码、设置远程访问、刷新服务
    echo "设置root密码、设置远程访问 ......"
    ${mysql_home}/bin/mysql -u root --skip-password <<EOF
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '123456';
    use mysql;
    update user set host='%' where user='root';
    flush privileges;
    \q
EOF

    # 关闭服务
    echo "关闭服务 ......"
    ./mysqladmin -u root -p123456 shutdown

    # 所属权限
    chown -R mysql:mysql "${mysql_home}"

    echo ""
    echo ""
    echo "安装成功，数据库目录为：${mysql_home}"
    echo "数据库密码为：123456"
    echo "端口号：3306"

    # 配置文件service
    echo "配置service服务 ......"
    {
        echo "[Unit]"
        echo "Description=MySQL Community Server"
        echo "After=network.target"
        echo "[Service]"
        echo "Type=forking"
        echo "User=mysql"
        echo "Group=mysql"
        echo "# Where to send early-startup messages from the server (before the logging"
        echo "# options of postgresql.conf take effect)"
        echo "# This is normally controlled by the global default set by systemd"
        echo "# StandardOutput=syslog"
        echo "# Disable OOM kill on the postmaster"
        echo "OOMScoreAdjust=-1000"
        echo "DynamicUser=true"
        echo "PrivateTmp=true"
        echo "# Give a reasonable amount of time for the server to start up/shut down"
        echo "TimeoutSec=300"
        echo "ExecStart=${mysql_home}/bin/mysqld_safe --defaults-file=${mysql_home}/my.cnf --user=mysql >>${mysql_home}/logs/mysqld_safe.log 2>&1 &"
        echo "ExecStop=${mysql_home}/bin/mysqladmin --defaults-file=${mysql_home}/mysqladmin.cnf shutdown"
        echo "ExecStopPost=/bin/sleep 3"
        # /bin/sh -c '...'是因为systemd只接受一个单一的命令，所以我们需要用/bin/sh -c来封装这个包含两个命令的命令序列。
        echo "ExecReload=/bin/sh -c '${mysql_home}/bin/mysqladmin --defaults-file=${mysql_home}/mysqladmin.cnf shutdown && ${mysql_home}/bin/mysqld_safe --defaults-file=${mysql_home}/my.cnf --user=mysql >>${mysql_home}/logs/mysqld_safe.log 2>&1 &'"
        echo "[Install]"
        echo "WantedBy=multi-user.target"
    }>> /usr/lib/systemd/system/mysqld_safe.service

    chmod 777 /usr/lib/systemd/system/mysqld_safe.service

    echo "设置开机自启：systemctl enable mysqld_safe.service"
    echo "启动服务：systemctl start mysqld_safe.service"
    echo "停止服务：systemctl stop mysqld_safe.service"
    echo "重启服务：systemctl reload mysqld_safe.service"
    echo "服务状态：systemctl status mysqld_safe.service"

}


base_lib
mysql
