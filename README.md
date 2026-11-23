# DPanel for Synology DSM

DPanel 社区版的群晖 `.spk` 套件。使用 DPanel 上游为群晖编译的二进制，面向 DSM 7.1（42661）及以上版本的 64 位 x86（`x86_64`）和 ARM（`armv8`）机型。不需要在 NAS 上通过 Docker 容器运行 DPanel 本身。

## 打包和发布

**只在 GitHub Actions 中打包，不需要在本地安装 Synology Toolkit 或生成 SPK。**

- 日常试包：在 Actions 中手动运行 **Build Synology SPK**，填入已发布的上游标签，例如 `v1.11.3`。完成后从该次运行的 Artifacts 下载，不会创建 Release。
- 正式发布：等 `donknap/dpanel` 的同名 Release 上传 `dpanel-synology-amd64` 和 `dpanel-synology-arm64` 后，在本仓库推送同名标签。Actions 会从上游下载二进制、校验架构、生成套件，并发布到本仓库的 GitHub Release。
- 正式及手动构建都会同时提供 `SHA256SUMS`。
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
| 持久运行参数 | `/var/packages/dpanel/var/dpanel/.env`，`/var/packages/dpanel/target/server/.env` 指向此文件 |
| 进程 PID | `/var/packages/dpanel/var/app.pid` |

修改 `.env` 里的 `APP_SERVER_PORT` 后重启套件生效。`.env` 按 `KEY=VALUE` 读取，不执行 Shell 代码；安装向导填的密码不会写入该文件。不要把 `dpanel` 共享目录的写权限授予不可信用户。

从试装版升级会保留端口，并将旧 `var/dpanel/data/` 复制到新的共享目录；旧数据保留。如果两边已有数据且未完成过迁移，启动会报错，不会覆盖数据库。卸载默认保留数据；选择删除时清理套件数据、配置和日志，不删除共享文件夹本身，也不删除 Docker 资源。

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
