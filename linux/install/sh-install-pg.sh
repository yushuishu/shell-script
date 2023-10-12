#!/bin/bash
shopt -s globstar

# 用途：安装postgresql（源码安装方式）

# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
# pg 安装目录：比如安装包为postgresql-14.5.tar.gz 安装成功后的目录为 /opt/postgresql/postgresql-14.5
PG_DIR="/opt/postgresql"
PG_PACKAGE_PATH=""
# ========================================================= 输入参数 =========================================================
if [ -n "$1" ]; then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：安装配置postgresql数据库，使用的是官网下载的源码安装包"
        echo "参数：参数                    是否必传    说明"
        echo "      --help; -help; -h        false      查看脚本使用说明"
        echo "      -p                       true       指定安装包路径"
        echo "************************************************************************"
        exit 0
    else
        while getopts ":p:" opt; do
            case $opt in
            p)
                PG_PACKAGE_PATH="$OPTARG"
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
echo -e "\033[36m/////////////////////////////////////// sh-install-pg ////////////////////////////////////////////\033[0m"

# 检查安装包是否存在
if [ -z "$PG_PACKAGE_PATH" ]; then
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

    apt-get update && apt-get install -y gcc && apt-get install -y libpcre3 libpcre3-dev && apt-get install -y ruby && apt-get install -y zlib1g zlib1g-dev && apt-get install -y openssl && apt-get install -y libssl-dev && apt-get install -y make && apt-get install -y pkg-config && apt-get install -y libreadline-dev

}

function pg() {
    # 解压后的pg目录名，如：postgresql-14.5
    pg_dir_name=$(tar -tf "${PG_PACKAGE_PATH}" | head -1 | cut -f1 -d"/")
    # 完整目录路径，如：/opt/postgresql/postgresql-14.5
    pg_home="${PG_DIR}/${pg_dir_name}"

    # 创建目录，解压安装包
    mkdir -p "${PG_DIR}/source-package" && tar -xvf "${PG_PACKAGE_PATH}" -C "${PG_DIR}/source-package"
    # 检查解压后的目录是否存在，以及是否为空
    if [ ! -d "$PG_DIR/source-package/$pg_dir_name" ]; then
        echo "解压pg安装包失败"
        exit 0
    fi
    if [ -z "$(ls -A $PG_DIR/source-package/$pg_dir_name)" ]; then
        echo "解压pg安装包失败，解压后的文件目录为空：${PG_DIR}/source-package"
        exit 0
    fi

    # 配置、编译、安装（执行时间约5分钟左右）
    cd "${PG_DIR}/source-package/${pg_dir_name}" || return 1
    "./configure" --prefix="${pg_home}" && make && make install
    if [ ! -d "$pg_home" ]; then
        echo "编译安装失败"
        exit 0
    fi
    if [ -z "$(ls -A $pg_home)" ]; then
        echo "编译安装失败，解压后的文件目录为空：${pg_home}"
        exit 0
    fi
    # bin目录
    pg_bin="${pg_home}/bin"

    # 创建用户组和用户。pg是无法使用root账户进行初始化操作的，需要普通用户，名称最好是postgres（一般情况下也都是这个名称）。然后将数据目录授权给postgres用户
    mkdir /home/postgres
    groupadd postgres
    useradd -d /home/postgres -g postgres -s /bin/bash postgres
    echo postgres:123456 | chpasswd
    chown -R postgres:postgres /home/postgres/

    # 创建数据目录，权限交给用户postgres
    mkdir "${pg_home}/data"
    chown postgres "${pg_home}/data"
    # 开放pg端口
    check_and_open_firewall_port 5432

    # postgres用户执行命令，使用-c选项来执行命令，如果切换到postgres用户，会直接导致脚本运行结束
    # 初始化
    #   -D 指定数据库数据位置
    #   -U 选择数据库superuser的用户名。默认 为运行initdb的用户的名称。而postgresql数据库的默认名称是postgres，所以创建用户组和用户的时候名字是postgres
    #   -W 对于新的超级用户提示输入口令
    #   -E 指定数据库编码，一般为UTF8。这也是稍后创建任何数据库的默认编码
    echo "------> 初始化"
    su - postgres -c "${pg_bin}/initdb -E UTF8 -D ${pg_home}/data"
    # 启动服务
    echo "------> 启动服务"
    su - postgres -c "${pg_bin}/pg_ctl -D ${pg_home}/data start"
    # 修改数据库访问密码（结尾 EOF" 前面不能有空格，单独一行，不要格式化缩进，否则报错）
    echo "------> 修改数据库访问密码"
    su - postgres -c "${pg_bin}/psql <<EOF
    \set ON_ERROR_STOP on
    alter user postgres with encrypted password '123456';
    \q
EOF"
    # 重启服务，或停止服务（自行选择是否重启）
    echo "------> 重启服务，或停止服务"
    #su - postgres -c "${pg_bin}/pg_ctl -D ${pg_home}/data restart"
    su - postgres -c "${pg_bin}/pg_ctl -D ${pg_home}/data stop"
    # 安装好的pg主目录权限，交给用户postgres
    chown -R postgres:postgres "${pg_home}"

    echo ""
    echo "安装成功，数据库目录为：${pg_home}"
    echo "数据库密码为：123456"
    echo "==================================================== 根据需求，添加额外配置 ===================================================="
    echo "远程访问（postgres权限操作）：vim配置文件：${pg_home}/data/postgresql.conf"
    echo "              修改参数 listen_address = ’*’ 监听所有访问（大约在60行附近）"
    echo "              修改参数 password_encryption = scram-sha-256  密码验证开启（大约在96行附近）"
    echo "         vim配置文件：${pg_home}/data/pg_hba.conf"
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
pg
