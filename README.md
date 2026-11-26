# DPanel for Synology DSM

DPanel 社区版的群晖 `.spk` 套件。使用 DPanel 上游为群晖编译的二进制，面向 DSM 7.1（42661）及以上版本的 64 位 x86（`x86_64`）和 ARM（`armv8`）机型。不需要在 NAS 上通过 Docker 容器运行 DPanel 本身。

## 打包和发布

本地打包不需要 Python、Node 或 jq。打包不需要传版本号。在 `package/` 中准备好两项输入：

1. 将上游的 `dpanel-ce-synology-amd64` 或 `dpanel-ce-synology-arm64` 放到 `app/server/dpanel`。打包时会自动将包内 `server/dpanel` 的权限设为 `0755`，不修改源文件权限。
2. 手动编辑 `INFO`：把 `version` 填为实际套件版本，把 `arch` 填为与二进制匹配的 `x86_64` 或 `armv8`。

从仓库根目录运行：

```sh
./sypack build ./package          # 正式包：dpanel.spk，匹配成功后自动跳转
./sypack build --debug ./package  # 调试包：dpanel-debug.spk，显示诊断并等待手动跳转
```

默认命令从 `./package` 读取套件，在执行命令的目录生成 `./dpanel.spk`。两种包使用同一个 `index.html`：默认打包时移除 `// #debug-begin` 和 `// #debug-end` 之间的诊断与按钮代码，`--debug` 保留这些代码并单独输出调试包。普通包失败时显示具体原因；调试页还显示 DSM 查询结果、监听地址、匹配规则和最终跳转地址（只显示一行，隐藏 `k` 的值）。调试页仅在 DSM 令牌接口的成功响应中显示 `data.synotoken` 原值，不要分享包含该值的截图。正式页不显示令牌；两种包均不把令牌写入套件日志。两种包选择访问地址的逻辑相同。省略目录参数时，从当前目录读取套件，输出位置不变（文件名取自 `INFO` 的 `package` 字段，再次打包会覆盖）。`sypack build` 不联网、不识别二进制架构、不修改源 `INFO`；它把 `app/` 封装为 `package.tgz`，将其校验值写入包内的 `INFO`。

GitHub Actions 自动完成相同的准备工作：按上游标签下载并核对两个架构的二进制，分别填写 `INFO` 并调用 `./sypack build ./package`，最后按架构命名产物并生成 `SHA256SUMS`。

- Actions 试包：手动运行 **Build Synology SPK**，填写上游标签，从该次运行的 Artifacts 下载试装包。
- 正式发布：待 `donknap/dpanel` 发布两个群晖二进制后，在本仓库推送同名版本标签，由 GitHub Actions 发布。
- 支持的标签格式为 `vX.Y.Z`、`vX.Y.Z.N`、`vX.Y.Z-N`。Actions 套件保留 `X.Y.Z`，构建号独立从 `49` 开始：例如同一个 `v1.11.3` 重打两次，分别得到 `1.11.3-49`、`1.11.3-50`。手动试包、标签发布及重新运行打包共用一个计数，同次两个架构同号；领号后构建失败也不回收。Actions 需要写入 `spk-build-number` 计数分支，请勿删除或重置该分支。本地打包仍使用 `INFO` 原值。

| Release 产物 | DSM 架构 |
| --- | --- |
| `dpanel-amd64.spk` | `x86_64` |
| `dpanel-arm64.spk` | `armv8` |

## 安装与访问

同一个 SPK 支持简体中文和英文：套件简介和安装、卸载向导随 DSM 显示语言切换，其他语言默认显示英文。桌面跳转页按浏览器语言显示，不改变 DPanel 面板内的语言设置。

语言文件统一放在 `package/locales/`。正式包和调试包的桌面入口共用同一套卡片样式，按浏览器语言读取 `zh-CN.json` 或 `en-US.json`，用于入口状态、错误、按钮及调试提示；套件脚本直接读取同名 `.sh` 的变量。安装、卸载各维护一份 `WIZARD_UIFILES/*_uifile.sh`。打包时将两种语言的变量附在各自入口内，避免首次安装依赖尚不存在的套件目录。向导运行时按 DSM 语言选变量，用系统 `awk` 转义变量并输出 JSON（不依赖 `jq`），不在打包时生成中英文向导。套件中心简介使用 `INFO` 的 `description` 和 `description_chs`。

1. 在 **套件中心 → 手动安装** 选择对应架构的 SPK，阅读并同意 DPanel《服务条款》。
2. 选择访问方式：
   - **直连访问（默认）**：通过 `http://NAS地址:所选端口` 访问。服务监听所有 IPv4 网卡（`0.0.0.0`）；端口对公网开放时，请做好访问防护。
   - **反代访问**：服务仅监听 `127.0.0.1`，局域网设备也不能直连。请在 DSM 中配置反向代理（推荐 HTTPS），目标为 `http://127.0.0.1:所选端口`，通过代理地址访问。
3. 设置服务端口（默认 `8086`）和管理员账号（默认用户名 `admin`）。全新安装时向导会预填 10 位随机密码，按住眼睛图标可查看，松开即隐藏。也可自行修改密码。请保存最终密码；登录后可在「系统设置 → 创始人配置」中修改。若主动清空，则在首次打开 DPanel 时设置。升级或保留数据重装不会重置已有账号。

DSM 桌面图标只匹配来源协议与当前 DSM 页面相同、且目的地指向套件的反代规则。有多条匹配时，使用 DSM 返回列表中的最后一条；来源主机名留空或为 `*` 时，使用当前 DSM 主机。**如果 DSM 未开启 HTTP → HTTPS 跳转，又要从 HTTP 和 HTTPS 两种 DSM 入口打开 DPanel，需分别配置两条规则**。例如，`HTTP :4002` 和 `HTTPS :4001` 都可指向 `http://127.0.0.1:8888`。如果 DSM 已跳到 HTTPS，只需配置 HTTPS 规则。

反代模式缺少当前协议的规则时，桌面入口会显示该协议的配置指引；只配置了另一种协议时，不切换协议或改走 HTTP 直连。来源端口填未占用的对外端口，目的地协议固定为 HTTP。规则名称、目的地主机名 `127.0.0.1` 和实际安装端口可分别复制。自定义标题选择 WebSocket，高级设置中的读取超时设为 3600 秒；页面不代写 DSM 规则。若不想使用反代，可以保留数据卸载后重装并选择直连访问。直连模式下，只有确认没有任何规则指向套件时，桌面图标才回退到 HTTP 直连；查询失败或所选规则无效时会说明原因。

只有与当前 DSM 页面主机名相同的 HTTP 或 HTTPS 反代，或上述同主机 HTTP 直连，可以向 DPanel 授权入口传值。套件用 GET 跳转，查询参数 `k` 是 DSM 令牌经 UTF-8 转成无填充的 Base64URL；这不是加密，HTTP 不保护传输，浏览器或代理也可能记录完整 URL。推荐使用 HTTPS，并确保访问日志不记录授权入口的查询串。一键登录需要配套 DPanel 后端，仍须验证 DSM 会话和管理员权限。不传令牌时打开普通登录页。

## 数据、配置和日志

DSM 创建名为 `dpanel` 的共享文件夹。实际存储卷由 DSM 决定，以下为套件使用的固定路径：

| 内容 | 路径 |
| --- | --- |
| 数据（数据库、应用配置等） | `/var/packages/dpanel/shares/dpanel/data/` |
| 启动日志（系统与套件信息、启动命令、环境变量、PID 和进程输出） | `/var/packages/dpanel/shares/dpanel/run.log` |
| DPanel 应用日志 | `/var/packages/dpanel/shares/dpanel/data/logs/dpanel.log` |
| 运行参数 | `/var/packages/dpanel/target/server/.env`，与主程序同目录的普通文件 |
| 共享目录路径记录（供卸载使用） | `/var/packages/dpanel/var/share.path` |
| 进程 PID | `/var/packages/dpanel/var/app.pid` |

每次启动时，`run.log` 按 `System`、`Package`、`Environment` 分组记录。环境变量取自加载 `.env` 并进入数据目录后的启动环境，不是 `.env` 文件的副本。已知的诊断字段显示值；代理、未知变量和含控制字符的值只显示 `[redacted]`。分享日志前请检查主机名、账户和本机路径。

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

### 通过 SSH 连接 Docker

SSH 连接使用目标主机的登录账号，不使用 `dpanel` 套件账号。在目标 NAS 的 **控制面板 → 用户与群组** 创建独立连接账号（例如 `dpanel-ssh`），并按该 NAS 的 SSH 登录策略和 Docker 访问策略授权。不要为了 SSH 连接把登录账号加入 `root` 组。

先从客户端运行 `ssh -p 22 dpanel-ssh@NAS地址 'docker ps'`，替换为实际地址和 SSH 端口。不加 `sudo` 也能列出容器后，再在 DPanel 的 Docker 环境中选择 SSH，填写同一地址、端口、账号及对应凭据。
