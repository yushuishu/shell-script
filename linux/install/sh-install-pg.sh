#!/bin/bash
shopt -s globstar

# 用途：安装postgresql（源码安装方式）




# ========================================================= 输入参数 =========================================================
# 安装包路径
PG_PACKAGE_PATH=""
# pg安装路径：比如指定路径为/opt/postgresql，安装包为postgresql-14.6.tar.gz 安装成功后的目录为 /opt/postgresql/postgresql-14.6
PG_DIR=""
# 控制日志文件记录哪些SQL语句
# none：不记录；
# ddl：记录所有数据定义命令，比如CREATE，ALTER和DROP 语句；
# mod：记录所有ddl语句，加上数据修改语句INSERT,UPDATE等
# all：记录所有执行的语句
LOG_STATEMENT="${LOG_STATEMENT:-'all'}"
# 定义日志输出格式化（时间戳 进程ID 数据库名 事务ID没有为0 远程主机和端口）
LOG_LINE_PREFIX="${LOG_LINE_PREFIX:-'%m_%p_%d_%x_%r'}"

if [ -n "$1" ]; then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：安装配置postgresql数据库，使用的是官网下载的源码安装包"
        echo "参数：参数                是否必传    说明"
        echo "    --help; -help; -h    false      查看脚本使用说明"
        echo "    -a                   true       安装包路径"
        echo "    -b                   true       安装路径，例如指定/opt/postgresql，安装结束过后的目录为/opt/postgresql/postgresql-14.6"
        echo "    -c                   false      控制日志文件记录哪些SQL语句（默认为：all）"
        echo "                                        none ：不记录"
        echo "                                        ddl ：记录所有数据定义命令，比如CREATE，ALTER和DROP 语句"
        echo "                                        mod ：记录所有ddl语句，加上数据修改语句INSERT,UPDATE等"
        echo "                                        all ：记录所有执行的语句"
        echo "    -d                   false      日志输出格式化（默认为：'%m_%p_%d_%x_%r'）"
        echo "                                        %a ：应用程序名称"
        echo "                                        %u ：用户名"
        echo "                                        %d ：数据库名"
        echo "                                        %r ：远程主机和端口"
        echo "                                        %h ：远程主机"
        echo "                                        %b ：后端类型"
        echo "                                        %p ：进程ID"
        echo "                                        %P ：并行组leader的进程ID"
        echo "                                        %t ：时间戳，不包含毫秒"
        echo "                                        %m ：以毫秒为单位的时间戳"
        echo "                                        %n ：以毫秒为单位的时间戳(作为Unix epoch)"
        echo "                                        %Q ：查询ID(如果没有或未计算，则为0)"
        echo "                                        %i ：命令标签"
        echo "                                        %e ：SQL状态"
        echo "                                        %c ：会话ID"
        echo "                                        % 1 ：会话行号"
        echo "                                        %s ：会话开始时间戳"
        echo "                                        %v ：虚拟事务ID"
        echo "                                        %x ：事务ID(如果无则为0)"
        echo "                                        %q ：在非会话进程中此处停止"
        echo "************************************************************************"
        exit 0
    else
        while getopts ":a:b:c:d:" opt; do
            case $opt in
            a)
                PG_PACKAGE_PATH="$OPTARG"
                ;;
            b)
                PG_DIR="$OPTARG"
                ;;
            c)
                LOG_STATEMENT="$OPTARG"
                ;;
            d)
                LOG_LINE_PREFIX="$OPTARG"
                ;;
            \?)
                echo "无效的选项: -$OPTARG，请使用 --help、-help、-h 查看脚本使用说明"
                exit 0
                ;;
            esac
        done
    fi
fi

if [ -z "$PG_PACKAGE_PATH" ] || [ -z "$PG_DIR" ]; then
    echo "错误：参数 -a 和 -b 是必传的，请使用 --help、-help、-h 查看使用说明"
    exit 1
fi

# =============================================================================================================================



echo -e "\033[36m/////////////////////////////////////// sh-install-pg ////////////////////////////////////////////\033[0m"


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
    # 检查目录是否存在
    mkdir -p "${PG_DIR}"
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
    sleep 2
    # 修改数据库访问密码（结尾 EOF" 前面不能有空格，单独一行，不要格式化缩进，否则报错）
    echo "------> 修改数据库访问密码"
    su - postgres -c "${pg_bin}/psql <<EOF
    \set ON_ERROR_STOP on
    alter user postgres with encrypted password '123456';
    \q
EOF"
    # 重启服务，或停止服务（自行选择是否重启）
    echo "------> 停止服务"
    su - postgres -c "${pg_bin}/pg_ctl -D ${pg_home}/data stop"
    sleep 2

    # 删除解压后的源码目录
    rm -r "${PG_DIR}/source-package"

    # 创建日志目录
    mkdir "${pg_home}/data/log"
    chown postgres "${pg_home}/data/log"

    # 备份原始配置文件
    cp "${pg_home}/data/postgresql.conf" "${pg_home}/data/postgresql.conf.bak"

    # 修改 listen_addresses 的值：修改值为*，任何客户端地址都可以访问
    # 检查是否存在未注释的 listen_addresses  行
    UNCOMMENTED_LISTEN_ADDRESSES=$(grep -E '^[^#]*listen_addresses\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LISTEN_ADDRESSES" ]; then
        # 如果存在未注释的行，修改该行
        sed -i '/^[^#]*listen_addresses\s*=/s/^.*$/listen_addresses = '\''*'\''/' "${pg_home}/data/postgresql.conf"
    else
        # 如果未找到未注释的行，查找注释的行并进行修改
        sed -i '/^#\s*listen_addresses\s*=/s/^#\s*//; s/listen_addresses\s*=.*/listen_addresses = '\''*'\''/' "${pg_home}/data/postgresql.conf"
    fi

    UNCOMMENTED_PASSWORD_ENCRYPTION=$(grep -E '^[^#]*password_encryption\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_PASSWORD_ENCRYPTION" ]; then
        # 如果存在未注释的行，修改该行
        sed -i '/^[^#]*password_encryption\s*=/s/^.*$/password_encryption = scram-sha-256/' "${pg_home}/data/postgresql.conf"
    else
        # 如果未找到未注释的行，查找注释的行并进行修改
        sed -i '/^#\s*password_encryption\s*=/s/^#\s*//; s/password_encryption\s*=.*/password_encryption = scram-sha-256/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 max_connections 的值：最大客户端连接数
    # 检查是否存在未注释的 max_connections 行
    UNCOMMENTED_MAX_CONNECTIONS=$(grep -E '^[^#]*max_connections\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_MAX_CONNECTIONS" ]; then
        # 如果存在未注释的行，修改该行
        sed -i '/^[^#]*max_connections\s*=/s/^.*$/max_connections = 200/' "${pg_home}/data/postgresql.conf"
    else
        # 如果未找到未注释的行，查找注释的行并进行修改
        sed -i '/^#\s*max_connections\s*=/s/^#\s*//; s/max_connections\s*=.*/max_connections = 200/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 logging_collector：开启后，日志写入到文件中
    UNCOMMENTED_LOGGING_COLLECTOR=$(grep -E '^[^#]*logging_collector\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOGGING_COLLECTOR" ]; then
        sed -i '/^[^#]*logging_collector\s*=/s/^.*$/logging_collector = on/' "${pg_home}/data/postgresql.conf"
    else
        sed -i '/^#\s*logging_collector\s*=/s/^#\s*//; s/logging_collector\s*=.*/logging_collector = on/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_directory：文件夹名称，目录为安装目录下的data文件夹中
    UNCOMMENTED_LOG_DIRECTORY=$(grep -E '^[^#]*log_directory\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_DIRECTORY" ]; then
        sed -i '/^[^#]*log_directory\s*=/s/^.*$/log_directory = '\''log'\''/' "${pg_home}/data/postgresql.conf"
    else
        sed -i '/^#\s*log_directory\s*=/s/^#\s*//; s/log_directory\s*=.*/log_directory = '\''log'\''/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_filename：日志文件名格式
    UNCOMMENTED_LOG_FILENAME=$(grep -E '^[^#]*log_filename\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_FILENAME" ]; then
        sed -i "/^[^#]*log_filename\s*=/s|^.*$|log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'|" "${pg_home}/data/postgresql.conf"
    else
        sed -i "/^#\s*log_filename\s*=/s/^#\s*//; s|log_filename\s*=.*|log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'|" "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_rotation_age：单个日志文件的生存期，默认1天，在日志文件大小没有达到log_rotation_size时，一天只生成一个日志文件
    UNCOMMENTED_LOG_ROTATION_AGE=$(grep -E '^[^#]*log_rotation_age\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_ROTATION_AGE" ]; then
        sed -i '/^[^#]*log_rotation_age\s*=/s/^.*$/log_rotation_age = 1d/' "${pg_home}/data/postgresql.conf"
    else
        sed -i '/^#\s*log_rotation_age\s*=/s/^#\s*//; s/log_rotation_age\s*=.*/log_rotation_age = 1d/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_rotation_size：单个日志文件的大小，如果时间没有超过log_rotation_age，一个日志文件最大只能到10M，否则将新生成一个日志文件
    UNCOMMENTED_LOG_ROTATION_SIZE=$(grep -E '^[^#]*log_rotation_size\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_ROTATION_SIZE" ]; then
        sed -i '/^[^#]*log_rotation_size\s*=/s/^.*$/log_rotation_size = 100MB/' "${pg_home}/data/postgresql.conf"
    else
        sed -i '/^#\s*log_rotation_size\s*=/s/^#\s*//; s/log_rotation_size\s*=.*/log_rotation_size = 100MB/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_min_duration_statement：
    UNCOMMENTED_LOG_MIN_DURATION_STATEMENT=$(grep -E '^[^#]*log_min_duration_statement\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_MIN_DURATION_STATEMENT" ]; then
        sed -i '/^[^#]*log_min_duration_statement\s*=/s/^.*$/log_min_duration_statement = 5000/' "${pg_home}/data/postgresql.conf"
    else
        sed -i '/^#\s*log_min_duration_statement\s*=/s/^#\s*//; s/log_min_duration_statement\s*=.*/log_min_duration_statement = 5000/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_statement：控制记录哪些SQL语句
    # none：不记录；
    # ddl：记录所有数据定义命令，比如CREATE，ALTER和DROP 语句；
    # mod：记录所有ddl语句，加上数据修改语句INSERT,UPDATE等
    # all：记录所有执行的语句
    UNCOMMENTED_LOG_STATEMENT=$(grep -E '^[^#]*log_statement\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_STATEMENT" ]; then
        sed -i "/^[^#]*log_statement\s*=/s|^.*$|log_statement = $LOG_STATEMENT|" "${pg_home}/data/postgresql.conf"
    else
        sed -i "/^#\s*log_statement\s*=/s/^#\s*//; s|log_statement\s*=.*|log_statement = $LOG_STATEMENT|" "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_connections：记录连接日志
    UNCOMMENTED_LOG_CONNECTIONS=$(grep -E '^[^#]*log_connections\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_CONNECTIONS" ]; then
        sed -i '/^[^#]*log_connections\s*=/s/^.*$/log_connections = on/' "${pg_home}/data/postgresql.conf"
    else
        sed -i '/^#\s*log_connections\s*=/s/^#\s*//; s/log_connections\s*=.*/log_connections = on/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_disconnections：记录连接断开日志
    UNCOMMENTED_LOG_DISCONNECTIONS=$(grep -E '^[^#]*log_disconnections\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_DISCONNECTIONS" ]; then
        sed -i '/^[^#]*log_disconnections\s*=/s/^.*$/log_disconnections = on/' "${pg_home}/data/postgresql.conf"
    else
        sed -i '/^#\s*log_disconnections\s*=/s/^#\s*//; s/log_disconnections\s*=.*/log_disconnections = on/' "${pg_home}/data/postgresql.conf"
    fi

    # 修改 log_line_prefix：日志输出格式
    # %a =应用程序名称
    # %u =用户名
    # %d =数据库名
    # %r =远程主机和端口
    # %h =远程主机
    # %b =后端类型
    # %p =进程ID
    # %P =并行组leader的进程ID
    # %t =时间戳，不包含毫秒
    # %m =以毫秒为单位的时间戳
    # %n =以毫秒为单位的时间戳(作为Unix epoch)
    # %Q =查询ID(如果没有或未计算，则为0)
    # %i =命令标签
    # %e = SQL状态
    # %c =会话ID
    # % 1 =会话行号
    # %s =会话开始时间戳
    # %v =虚拟事务ID
    # %x =事务ID(如果无则为0)
    # %q =在非会话进程中此处停止
    UNCOMMENTED_LOG_LINE_PREFIX=$(grep -E '^[^#]*log_line_prefix\s*=' "${pg_home}/data/postgresql.conf")
    if [ -n "$UNCOMMENTED_LOG_LINE_PREFIX" ]; then
        sed -i "/^[^#]*log_line_prefix\s*=/s|^.*$|log_line_prefix = $LOG_LINE_PREFIX|" "${pg_home}/data/postgresql.conf"
    else
        sed -i "/^#\s*log_line_prefix\s*=/s/^#\s*//; s|log_line_prefix\s*=.*|log_line_prefix = $LOG_LINE_PREFIX|" "${pg_home}/data/postgresql.conf"
    fi


    # 安装好的pg主目录权限，交给用户postgres
    chown -R postgres:postgres "${pg_home}"


    {
      echo "host    all             all             0.0.0.0/0               scram-sha-256"
    }>> "${pg_home}/data/pg_hba.conf"

    # 服务
    {
        echo "开机自启（root权限操作）：vim添加配置文件postgresql.service：sudo vim /usr/lib/systemd/system/postgresql.service"
        echo "添加如下内容："
        echo "[Unit]"
        echo "Description=PostgreSQL database server"
        echo "After=network.target"
        echo "[Service]"
        echo "Type=forking"
        echo "User=postgres"
        echo "Group=postgres"
        echo "TimeoutSec=10s"
        echo "Environment=PG_PORT=5432"
        echo "Environment=PG_DATA=${pg_home}/data/"
        echo "# 启动服务前，执行检查目录文件，配置信息的正确性"
        echo "#ExecStartPre=${pg_home}/bin/postgresql-check-db-dir \${PG_DATA}"
        echo "# -s 只输出错误信息，适合在脚本中使用，减少不必要的输出"
        echo "# -o 传递额外的命令行参数给 PostgreSQL 服务器进程，这里指定了端口号"
        echo "# -w 这个选项表示在启动过程中等待直到数据库准备就绪。pg_ctl 会循环检查数据库是否已完全启动，确保服务可用"
        echo "# -t 60 超时时间，单位是秒，此时间内数据库未启动，命令将失败"
        echo "# -m 指定关闭模式：smart、fast、immediate"
        echo "ExecStart=${pg_home}/bin/pg_ctl start -D \${PG_DATA} -s -o \"-p \${PG_PORT}\" -w -t 60"
        echo "ExecStop=${pg_home}/bin/pg_ctl stop -D \${PG_DATA} -s -m fast"
        echo "ExecReload=${pg_home}/bin/pg_ctl reload -D \${PG_DATA} -s"
        echo "[Install]"
        echo "WantedBy=multi-user.target"
    }>> "/etc/systemd/system/postgresql.service"

    chmod 777 /etc/systemd/system/postgresql.service
    systemctl daemon-reload
    systemctl enable postgresql.service
    echo ""
    echo ""
    echo "================================ 安装成功 ================================"
    echo "数据库目录为：${pg_home}"
    echo "日志目录为：${pg_home}/data/log"
    echo "数据库用户名为：postgres"
    echo "数据库密码为：123456"
    echo "相关命令："
    echo "    启动服务：systemctl start postgresql.service"
    echo "    停止服务：systemctl stop postgresql.service"
    echo "    重启服务：systemctl reload postgresql.service"
    echo "    服务状态：systemctl status postgresql.service"
    echo "=========================================================================="

}


base_lib
pg
