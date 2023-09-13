# shell-script

<p>
  <a href="https://www.microsoft.com/zh-cn"><img src="https://img.shields.io/badge/Windows-%3E=10-green.svg" alt="Windows compatility"></a>
  <a href="https://ubuntu.com/download/server"><img src="https://img.shields.io/badge/Ubuntu-%3E=20.04.5-blue.svg" alt="Ubuntu compatility"></a>
</p>

## 介绍

Windows平台基于 [Windows@10](https://www.microsoft.com/zh-cn)，Linux平台基于[VMware@15pro](https://www.vmware.com/cn.html) [Ubuntu@20.04.5](https://ubuntu.com/download/server) 开发使用。

Windows平台和Linux平台下使用、总结、收集的脚本（bash、bat）

## 预览

![script-01](https://github.com/yushuishu/shell-script/assets/50919172/9b129ee5-be4f-4a00-b423-6fdff7fec507)


## 项目结构说明

## 使用

不通场景下的脚本，需要简单修改脚本内容，也就是代码逻辑变量，一般放在脚本文件顶部区域（有注释），比如数据库备份脚本，就需要修改默认要备份的数据库，以及主机、用户名、密码等信息。

- 每个脚本都可以通过 `--help`、`-help`、`-h` 可选命令来查看帮助说明。
- 关于安装jdk、mysql、nginx等脚本的使用，全部使用源码进行编译安装。
- sh脚本上传到Ubuntu上，需要vim编辑脚本执行：`:set ff=unix` 将Windows平台下的换行符改为Linux系统的换行符

## 引用
