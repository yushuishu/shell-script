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
    mkdir /home/mysql
    groupadd mysql
    useradd -d /home/mysql -g mysql -s /bin/bash mysql
    echo mysql:123456 | chpasswd
    chown -R mysql:mysql /home/mysql/

    # 配置文件my.cnf
    {
        echo "[mysql]"
        echo "# 设置mysql客户端默认字符集"
        echo "default-character-set=utf8"
        echo "[mysqld]"
        echo "# 禁用MySQL服务器进行DNS反解析，DNS反解析可能会导致连接延迟或潜在的安全问题"
        echo "# 禁用之后，mysql的授权表中就不能使用主机名了，只能使用IP。（也就是只能用IP地址检查客户端的登录，不能用主机名）"
        echo "skip-name-resolve=1"
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
        echo "innodb_buffer_pool_size=128"
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
        echo "慢查询sql日志设置（开启值可以是1或on)"
        echo "slow_query_log=1"
        echo "slow_query_log_file=${mysql_home}/logs/slow.log"
        echo "# 设置慢查询执行的秒数，单位秒，必须达到此值可被记录"
        echo "long_query_time=10"
    }>> "${mysql_home}/my.cnf"
    
    # 创建mysql数据文件目录
    mkdir -p "${mysql_home}/data"
    # 创建日志文件
    mkdir "${mysql_home}/logs"
    touch "${mysql_home}/logs/error.log"
    # 所属权限
    chown -R mysql:mysql "${mysql_home}"
    # 开放端口
    check_and_open_firewall_port 3306

    # 初始化 MySQL
    cd "${mysql_home}/bin" || exit 0
    ./mysqld --defaults-file="${mysql_home}/my.cnf" --initialize-insecure --user=mysql
    # 启动服务
    ./mysqld_safe --defaults-file=/opt/mysql/mysql-8.0.34-linux-glibc2.28-x86_64/my.cnf --user=mysql &

    # 登录客户端、设置root密码、设置远程访问、刷新服务
    ./mysql -u root --skip-password <<EOF
    \ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '123456';
    use mysql;
    update user set host='%' where user='root';
    flush privileges;
    quit;
    \q
EOF

    # 关闭服务
    ./mysqladmin -u root -p123456 shutdown



    echo ""
    echo "安装成功，数据库目录为：${mysql_home}"
    echo "数据库密码为：123456"
    echo "端口号：3306"
    echo "==================================================== 根据需求，添加额外配置 ===================================================="
    echo "远程访问（postgres权限操作）：vim配置文件：${mysql_home}/my.cnf"
    echo "              修改参数 listen_address = ’*’ 监听所有访问（大约在60行附近）"
    echo "              修改参数 password_encryption = scram-sha-256  密码验证开启（大约在96行附近）"
    echo "         vim配置文件：${mysql_home}/data/pg_hba.conf"
    echo "              ip范围配置（所有客户端都可以访问），在大约90行附近，添加一行：host    all             all             0.0.0.0/0               scram-sha-256"
    echo ""
    echo "开机自启（root权限操作）：vim添加配置文件postgresql.service：sudo vim /usr/lib/systemd/system/postgresql.service"
    echo "              添加如下内容："
    echo "                    [Unit]"
    echo "                    Description=PostgreSQL database server"
    echo "                    After=network.target"
    echo "                    [Service]"
    echo "                    Type=forking"
    echo "                    User=postgres"
    echo "                    Group=postgres"
    echo "                    # Port number for server to listen on"
    echo "                    Environment=PG_PORT=5432"
    echo "                    # Location of database directory"
    echo "                    Environment=PG_DATA=${pg_home}/data/"
    echo "                    # Where to send early-startup messages from the server (before the logging"
    echo "                    # options of postgresql.conf take effect)"
    echo "                    # This is normally controlled by the global default set by systemd"
    echo "                    # StandardOutput=syslog"
    echo "                    # Disable OOM kill on the postmaster"
    echo "                    OOMScoreAdjust=-1000"
    echo "                    #ExecStartPre=${pg_home}/bin/postgresql-check-db-dir \${PG_DATA}"
    echo "                    ExecStart=${pg_home}/bin/pg_ctl start -D \${PG_DATA} -s -o \"-p \${PG_PORT}\" -w -t 300"
    echo "                    ExecStop=${pg_home}/bin/pg_ctl stop -D \${PG_DATA} -s -m fast"
    echo "                    ExecReload=${pg_home}/bin/pg_ctl reload -D \${PG_DATA} -s"
    echo "                    # Give a reasonable amount of time for the server to start up/shut down"
    echo "                    TimeoutSec=300"
    echo "                    [Install]"
    echo "                    WantedBy=multi-user.target"
    echo "              设置权限：chmod 777 /usr/lib/systemd/system/postgresql.service"
    echo "              设置开机自启：systemctl enable postgresql.service"
    echo "              启动服务：systemctl start postgresql.service"
    echo "              停止服务：systemctl stop postgresql.service"
    echo "              重启服务：systemctl reload postgresql.service"
    echo "              服务状态：systemctl status postgresql.service"

}


base_lib
mysql



[mysql]
# 设置mysql客户端默认字符集
default-character-set=utf8
[mysqld]
# 禁用MySQL服务器进行DNS反解析，DNS反解析可能会导致连接延迟或潜在的安全问题
# 禁用之后，mysql的授权表中就不能使用主机名了，只能使用IP。（也就是只能用IP地址检查客户端的登录，不能用主机名）
skip-name-resolve=1
# 设置3306端口
port = 3306
# 设置mysql的安装目录
basedir=${mysql_home}
# 设置mysql数据库的数据的存放目录
datadir=${mysql_home}/data
# 设置错误日志文件
log_error=${mysql_home}/logs/error.log
# 允许最大连接数，默认151
max_connections=200
# 设置InnoDB存储引擎的缓冲池大小，默认为128MB
innodb_buffer_pool_size=128
# 设置默认字符集，支持一些特殊表情符号（特殊表情符占用4个字节）
character-set-server=utf8mb4
# 设置字符集对应一些排序等规则，注意要和character-set-server对应
collation-server=utf8mb4_general_ci
# 创建新表时将使用的默认存储引擎
default-storage-engine=INNODB
# 设置对sql语句大小写敏感，1表示不敏感（值可以是1或on)
lower_case_table_names=1
# 数据包发送的大小，如果有BLOB对象建议修改成1G
max_allowed_packet=128M
# 慢查询sql日志设置（开启值可以是1或on)
slow_query_log=1
slow_query_log_file=${mysql_home}/logs/slow.log
# 设置慢查询执行的秒数，单位秒，必须达到此值可被记录"
long_query_time=10