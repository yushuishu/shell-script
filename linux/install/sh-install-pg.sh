#!/bin/bash
shopt -s globstar

# 用途：安装postgresql

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
        echo "      -p                       true      安装>=安装postgresql14，指定安装包路径"
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
    return
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

    apt-get update && apt-get install -y gcc && apt-get install -y libpcre3 libpcre3-dev && apt-get install -y zlib1g zlib1g-dev && apt-get install -y openssl && apt-get install -y libssl-dev && apt-get install -y make && apt-get install -y pkg-config && apt-get install -y readline && apt-get install -y readline-dev && apt-get install -y zlib-devel

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

    # 配置、编译、安装（执行时间约8分钟左右）
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

    # 创建数据目录
    mkdir "${pg_home}/data"

    # 创建用户组和用户。pg是无法使用root账户进行初始化操作的，需要普通用户，名称最好是postgres（一般情况下也都是这个名称）。然后将数据目录授权给postgres用户
    mkdir /home/postgres
    groupadd postgres
    useradd -d /home/postgres -g postgres -s /bin/bash postgres
    echo postgres:123456 | chpasswd
    chown postgres "${pg_home}/data"
    check_and_open_firewall_port 5432

    # 初始化
    #   -D 指定数据库数据位置
    #   -U 选择数据库superuser的用户名。默认 为运行initdb的用户的名称。而postgresql数据库的默认名称是postgres，所以创建用户组和用户的时候名字是postgres
    #   -W 对于新的超级用户提示输入口令
    #   -E 指定数据库编码，一般为UTF8。这也是稍后创建任何数据库的默认编码
    su postgres
    cd "${pg_home}/bin"
    ./initdb -E UTF8 -D "${pg_home}/data"

    # 修改数据库访问密码
    ./psql
    alter user postgres with encrypted password '123456';
    exit

    # 配置远程访问
    vi "${pg_home}/data/postgresql.conf"

}

base_lib
pg
