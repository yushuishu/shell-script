@echo off
setlocal EnableExtensions

REM 用途：备份MYSQL数据库

REM ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
REM MYSQL 安装目录
set "MYSQL_HOME=D:\app\main\mysql8\bin"
REM 备份文件存储目录
set "MYSQL_BACKUP_DIR=D:\mysql_backup"
REM 备份的数据库
set "MYSQL_BACKUP_DB_NAME=demo"
REM 删除 ... 天之前的备份文件
set "DEL_BACKUP_DAY=7"
REM 备份数据库ip
set "MYSQL_HOST=127.0.0.1"
REM 备份数据库端口
set "MYSQL_PORT=3360"
REM 用户名
set "MYSQL_USER=root"
REM 用户密码
set "MYSQL_PASSWORD=123456"
REM =============================================================================================================================

REM 判断备份的路径是否存在，不存在就创建
if not exist "%MYSQL_BACKUP_DIR%" (
    echo 备份文件存储目录不存在，正在创建...
    mkdir "%MYSQL_BACKUP_DIR%"
    echo 文件夹创建成功。
)

REM 获取当前日期
for /f "tokens=1-3 delims=-/. " %%i in ("%date%") do (
    set "year=%%i"
    set "month=%%j"
    set "day=%%k"
)
set "MYSQL_BACKUP_DATE=%year%-%month%-%day%"

REM 查找当前日期，有多少个备份文件
set file_count=0
for /f %%A in ('dir /b "%MYSQL_BACKUP_DIR%\%MYSQL_BACKUP_DB_NAME%_%MYSQL_BACKUP_DATE%_*.sql" ^| find /c /v ""') do set /a "file_count=%%A + 1"

REM 当前要备份的文件路径和文件名
set "mysql_backup_file=%MYSQL_BACKUP_DIR%\%MYSQL_BACKUP_DB_NAME%_%MYSQL_BACKUP_DATE%_%file_count%.sql"


REM 计算 DEL_BACKUP_DAY 天前的日期
call :SubtractDays %year% %month% %day% %DEL_BACKUP_DAY%
set "long_ago_backup_date=%result%"

REM %DEL_BACKUP_DAY%天前备份的文件路径和文件名
set "long_ago_backup_file=%MYSQL_BACKUP_DIR%\%MYSQL_BACKUP_DB_NAME%_%long_ago_backup_date%_*.sql"

REM 检查7天前的备份文件是否已存在，如存在则删除
if exist "%long_ago_backup_file%" (
    del /f "%long_ago_backup_file%"
)

REM 执行数据库备份命令，当前时刻的数据，即今天的数据
"%MYSQL_HOME%\mysqldump.exe" -h%MYSQL_HOST% -u%MYSQL_USER% -p%MYSQL_PASSWORD% %MYSQL_BACKUP_DB_NAME% > %mysql_backup_file%

pause


:SubtractDays
set "yyyy=%1"
set "mm=%2"
set "dd=%3"
set "days_to_subtract=%4"

REM 将日期转换为自然数表示形式
set /a "yyyy=10000%yyyy% %% 10000"
set /a "mm=100%mm% %% 100"
set /a "dd=100%dd% %% 100"

REM 转换日期为Julian Day Number (JDN)格式
set /a "a=(14-mm)/12"
set /a "y=yyyy+4800-a"
set /a "m=mm+12*a-3"
set /a "jdn=dd+(153*m+2)/5+365*y+y/4-y/100+y/400-32045"

REM 计算日期差异
set /a "jdn=jdn-days_to_subtract"

REM 将JDN转换回日期
set /a "yy=jdn*10000/3652425+4712"
set /a "mm=(jdn*100/306001+14)/10"
set /a "dd=jdn-(1461*(yy+4800+(mm-14)/12))/4+(367*(mm-2-12*((mm-14)/12)))/12-3"

REM 格式化日期为4位数的年份、2位数的月份和2位数的日期
set /a "yyyy=yy"
if %mm% lss 10 set "mm=0%mm%"
if %dd% lss 10 set "dd=0%dd%"

REM 输出结果
echo %yyyy%-%mm%-%dd%

goto :EOF

