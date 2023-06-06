$OutputEncoding = [console]::OutputEncoding = [Text.Encoding]::UTF8
function system_info()
{
    echo =======================^[[35m 操作系统内核信息: ======================^[[0m
    echo ===========================^[[35m 内核版本: =========================^[[0m
    type C:\Windows\System32\drivers\etc\hosts
    echo ===========================^[[35m cpu个数: ===========================^[[0m
    wmic cpu get NumberOfCores
    echo ===========================^[[35m cpu核数: ===========================^[[0m
    wmic cpu get NumberOfLogicalProcessors
    echo ===========================^[[35m cpu型号: ===========================^[[0m
    wmic cpu get Name
    echo =========================^[[35m cpu内核频率: =========================^[[0m
    wmic cpu get MaxClockSpeed
    echo =========================^[[35m cpu统计信息: =========================^[[0m
    systeminfo | findstr /C:"处理器"
    systeminfo | findstr /C:"可用物理内存"
    systeminfo | findstr /C:"可用虚拟内存"
    systeminfo | findstr /C:"总虚拟内存"
}
system_info