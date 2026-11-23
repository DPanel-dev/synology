# DPanel for Synology DSM

DPanel 社区版的群晖 `.spk` 套件。使用 DPanel 上游为群晖编译的二进制，面向 DSM 7.1（42661）及以上版本的 64 位 x86（`x86_64`）和 ARM（`armv8`）机型。不需要在 NAS 上通过 Docker 容器运行 DPanel 本身。

## 打包和发布

本地打包不需要传版本号。在 `package/` 中准备好两项输入：

1. 将上游的 `dpanel-synology-amd64` 或 `dpanel-synology-arm64` 放到 `app/server/dpanel`。打包时会自动将包内 `server/dpanel` 的权限设为 `0755`，不修改源文件权限。
2. 手动编辑 `INFO`：把 `version` 填为实际套件版本，把 `arch` 填为与二进制匹配的 `x86_64` 或 `armv8`。

从仓库根目录运行：

```sh
./sypack build ./package
```

命令从 `./package` 读取套件，在执行命令的目录生成 `./dpanel.spk`。省略目录参数时，从当前目录读取套件，输出位置不变（文件名取自 `INFO` 的 `package` 字段，再次打包会覆盖）。`sypack build` 不联网、不识别二进制架构、不修改源 `INFO`；它把 `app/` 封装为 `package.tgz`，将其校验值写入包内的 `INFO`。

GitHub Actions 自动完成相同的准备工作：按上游标签下载并核对两个架构的二进制，分别填写 `INFO` 并调用 `./sypack build ./package`，最后按架构命名产物并生成 `SHA256SUMS`。

- Actions 试包：手动运行 **Build Synology SPK**，填写上游标签，从该次运行的 Artifacts 下载试装包。
- 正式发布：待 `donknap/dpanel` 发布两个群晖二进制后，在本仓库推送同名版本标签，由 GitHub Actions 发布。
- 支持的标签格式为 `vX.Y.Z`、`vX.Y.Z.N`、`vX.Y.Z-N`。DSM 套件版本为 `X.Y.Z-N`，三段标签的构建号为 `0`。

| Release 产物 | DSM 架构 |
| --- | --- |
| `dpanel-amd64.spk` | `x86_64` |
| `dpanel-arm64.spk` | `armv8` |

## 安装与访问

1. 在 **套件中心 → 手动安装** 选择对应架构的 SPK，阅读并同意 DPanel《服务条款》。
2. 设置应用端口（默认 `8086`），管理员用户名默认 `admin`，密码可留空。新安装填了密码会尝试初始化管理员；留空则在网页中创建。升级或保留数据重装不会重置已有账号。
3. 确认套件已运行，在浏览器打开 `http://NAS地址:端口`（例如 `http://172.16.1.223:8086`）。DSM 桌面图标也指向这个 HTTP 服务。无需配置反向代理，当前不支持 DSM 一键登录。

服务监听 NAS 的 IPv4 网络接口。只在可信内网使用，必要时用 DSM 防火墙限制来源，不要把 HTTP 端口转发到公网。

## 数据、配置和日志

DSM 创建名为 `dpanel` 的共享文件夹。实际存储卷由 DSM 决定，以下为套件使用的固定路径：

| 内容 | 路径 |
| --- | --- |
| 数据（数据库、应用配置等） | `/var/packages/dpanel/shares/dpanel/data/` |
| 启动日志（DSM 版本、架构、运行账户、路径、端口、PID 和进程输出） | `/var/packages/dpanel/shares/dpanel/run.log` |
| DPanel 应用日志 | `/var/packages/dpanel/shares/dpanel/data/logs/dpanel.log` |
| 运行参数 | `/var/packages/dpanel/target/server/.env`，与主程序同目录的普通文件 |
| 共享目录路径记录（供卸载使用） | `/var/packages/dpanel/var/share.path` |
| 进程 PID | `/var/packages/dpanel/var/app.pid` |

修改 `.env` 里的 `APP_SERVER_PORT` 后重启套件生效。`.env` 按 `KEY=VALUE` 读取，不执行 Shell 代码；安装向导填的密码不会写入该文件。不要把 `dpanel` 共享目录的写权限授予不可信用户。

旧测试布局不提供迁移，请按全新安装测试。本布局后续升级会保存并恢复 `server/.env`；卸载重装则按安装向导重新生成 `.env`。卸载默认保留数据；选择删除时清理套件数据、配置和日志，不删除共享文件夹本身，也不删除 Docker 资源。

## SSH 维护

```sh
sudo /usr/syno/bin/synopkg status dpanel
sudo /usr/syno/bin/synopkg restart dpanel
sudo -u dpanel /var/packages/dpanel/target/server/service.sh --help
sudo tail -n 100 /var/packages/dpanel/shares/dpanel/run.log
```

`service.sh` 的 `start`、`stop`、`restart`、`status` 交给 DSM 套件管理；其他参数传给 DPanel CLI，与服务使用同一份 `.env` 和数据目录。若套件在挂载共享目录之前就失败，先看套件中心的启动报错，此时共享目录里可能还没有 `run.log`。

### Docker 权限

套件使用 DSM 分配的内部用户运行，不以 root 运行，也不修改 Docker socket 权限。若要管理本机容器，请安装机型支持的 Container Manager（旧系统上可能叫 Docker），为套件用户明确授权；或者配置通过 TLS 或 SSH 保护的远程 Docker 端点。不要将 Docker socket 设置为所有人可读写。
