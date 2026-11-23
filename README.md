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

1. 在 **套件中心 → 手动安装** 选择对应架构的 SPK。这是第三方套件，不是群晖官方签名分发的套件。
2. 选择端口，默认 `8086`。默认只监听 `127.0.0.1`。推荐在 DSM 的 **登录门户 → 高级 → 反向代理** 创建 HTTPS 入口，将目标设为 HTTP、`127.0.0.1` 和安装时选的端口，并配置 WebSocket 转发。然后访问该 HTTPS 入口的 `/dpanel/ui`。安装向导若填写了该 HTTPS 入口（只填主机名和可选端口），DSM 桌面图标可以直接打开它。
3. 也可以在安装时勾选允许直连，从可信内网访问 `http://NAS地址:端口/dpanel/ui`。直连使用 HTTP，请限制防火墙的来源，不要转发到公网。
4. 首次在 DPanel 界面创建管理员。当前套件不支持 DSM 一键登录。

### Docker 权限

套件使用 DSM 分配的内部用户运行，不以 root 运行，也不修改 Docker socket 权限。要管理本机容器，请先安装机型支持的 Container Manager（旧系统上可能叫 Docker），并为 DPanel 套件用户明确授权访问其 Docker socket；如不授权，可在 DPanel 中配置用 TLS 或 SSH 保护的远程 Docker 端点。**Docker socket 的访问权限等同于对 Docker 宿主机的高权限控制**，不要将其设置为所有人可读写。

### 数据保留

运行数据、监听配置和日志存放于 `/var/packages/dpanel/var/dpanel/`（随套件安装卷）。升级不会覆盖该目录。卸载默认保留；只有在卸载向导主动勾选删除才清理该目录，不会删除 Docker 容器、镜像或卷。重装时请选择同一个存储卷以复用保留的数据和原监听配置。

如需为已安装套件补填或修改 HTTPS 入口，可在保留原设置的前提下，修改 `/var/packages/dpanel/var/dpanel/connection.conf` 的第三行（前两行分别是端口和是否允许 HTTP 直连）。重启套件后桌面入口会更新；留空则恢复直连链接或反向代理设置指引。
