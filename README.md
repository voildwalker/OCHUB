# OCHUB · WireGuard 一键部署与全生命周期管理

高性能、极简、安全的 WireGuard 安装与管理脚本（Oracle Cloud 友好版）。  
将繁琐的网络配置抽象为清晰的交互式向导，用几分钟把一台干净的云主机变成稳定可靠的私人 VPN 服务。

![Shell](https://img.shields.io/badge/shell-bash-121011?style=flat-square&logo=gnu-bash&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-Auto%20Installer-88171A?style=flat-square&logo=wireguard&logoColor=white)
![OS](https://img.shields.io/badge/OS-Debian%2FUbuntu-00A1FF?style=flat-square&logo=linux)
![License](https://img.shields.io/github/license/voildwalker/OCHUB?style=flat-square)

---

## 为什么选择 OCHUB 的 WireGuard 方案？

- 体验至上：交互式向导，默认最佳实践，无需理解底层网络即可上线
- 稳定专业：内核转发、UFW 防火墙、NAT、密钥与端口自动配置
- 开箱即用：自动生成客户端配置与二维码，手机一扫即可连接
- 全生命周期：同一脚本完成新增/查看/删除客户端与一键卸载
- 针对 Oracle Cloud 优化：明确的放行步骤与故障自检提示

---

## 一键安装

- 快捷安装（不保留脚本文件）
```bash
curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh | sudo bash
```

- 建议：下载本地后执行（便于后续管理）
```bash
curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh -o install_wireguard.sh
sudo bash install_wireguard.sh
```

原始文件链接（镜像二选一均可）  
- 裸文件链接：https://raw.githubusercontent.com/voildwalker/OCHUB/refs/heads/main/install_wireguard.sh  
- 快捷文件链接：https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh

适用系统：Debian/Ubuntu（以 root 或具备 sudo 的用户执行）

---

## 安装前唯一关键步骤（Oracle Cloud 放行端口）

> 99% 的“能连上但无法上网”问题，源自此处未正确放行。

- 登录 Oracle Cloud 控制台
- 左上角“汉堡菜单” → 网络 → 虚拟云网络
- 选择你的 VCN → 资源 → 安全列表 → 进入默认安全列表
- 添加入站规则：
  - 源类型：CIDR
  - 源 CIDR：0.0.0.0/0
  - 协议：UDP
  - 目标端口范围：建议使用 50000–65535 的高端口，如 51820（稍后脚本会用到）
  - 描述：WireGuard Port
- 保存

如你的实例使用网络安全组（NSG），请在 NSG 中同样放行对应 UDP 端口。

---

## 部署与向导

1) 连接服务器  
通过 SSH 工具（MobaXterm、Termius、FinalShell 等）登录 Oracle 实例。

2) 运行脚本  
按上文“一键安装”方式执行。脚本将：
- 检查并安装依赖：wireguard、wireguard-tools、qrencode、ufw
- 启用 IPv4 转发、配置 UFW 与 NAT
- 生成服务器密钥、创建 /etc/wireguard/wg0.conf
- 启动并设置 wg-quick@wg0 开机自启

3) 跟随向导完成配置  
- 监听端口：输入你在 Oracle Cloud 放行的 UDP 端口（如 51820）
- 首个客户端：输入一个名称（如 my-phone），脚本会自动生成配置与二维码

---

## 连接设备

- 手机端（Android / iOS）
  1. 在应用商店搜索并安装官方 WireGuard
  2. 打开 App → “+” → 从二维码扫描
  3. 对准终端中显示的二维码
  4. 命名隧道并开启连接

- 电脑端（Windows / macOS）
  1. 前往 WireGuard 官网下载并安装
  2. 使用 SFTP 工具（FileZilla、Termius、MobaXterm 等）连接服务器
  3. 下载客户端配置文件至本地：/root/ochub_wg_clients/ 目录（如 /root/ochub_wg_clients/my-phone.conf）
  4. 在 WireGuard 客户端中选择“从文件导入”，加载 .conf 文件即可

---

## 管理与维护

再次运行脚本进入面板（若本地保存了脚本）：
```bash
sudo bash ./install_wireguard.sh
```

面板功能：
- 添加客户端：为家人或其他设备生成配置与二维码
- 查看连接状态：显示活跃/不活跃、最后握手时间、上下行流量
- 移除客户端：安全删除指定配置
- 卸载 WireGuard：完全清理服务与配置（不可逆）

重要路径：
- 服务器配置：/etc/wireguard/wg0.conf
- 客户端配置目录：/root/ochub_wg_clients/

---

## 故障排查

- 客户端连上但上不了网
  - 核对 Oracle 安全列表/NSG 是否放行对应 UDP 端口
  - 服务器防火墙是否放行端口：sudo ufw status
  - 服务是否运行：sudo systemctl status wg-quick@wg0

- 变更后不生效
  - 重载服务：sudo systemctl restart wg-quick@wg0
  - 查看状态与会话：sudo wg show

- 端口占用/冲突
  - 检查监听：sudo ss -lun | grep 51820
  - 在面板中选择新端口后重启服务，并同步更新 Oracle 放行规则

---

## 设计哲学与版本信息

- 内核稳定（Core Stability）：围绕稳定、可复用的网络栈配置
- 体验至上（UX-First）：中文交互、明确提示、友好日志
- 代码健壮（Robust Code）：容错、依赖自检、Apt 锁等待、UFW 与 NAT 自动化

V9.0 更新亮点：
- UI 渲染更精致：逐行打印 ASCII 标题、表格列对齐优化
- 逻辑更顺手：通过 case 语句重构确认逻辑、交互更符合直觉
- 兼容性增强：对 APT 锁的智能等待，异常更可读

---

## 常见问答

- 是否支持非 Oracle 环境？  
  可以。脚本面向 Debian/Ubuntu 通用，但文档重点示例为 Oracle Cloud。

- 是否支持 IPv6 出口？  
  目前主要面向 IPv4 NAT 出口。需要 IPv6 的场景可自行扩展 UFW/路由配置。

- 如何保持脚本为最新？  
  重新从仓库下载脚本再执行即可：
  ```bash
  curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh -o install_wireguard.sh
  sudo bash install_wireguard.sh
  ```

---

## 卸载

在脚本面板中选择“卸载 WireGuard”，或手动执行：
```bash
sudo systemctl stop wg-quick@wg0
sudo systemctl disable wg-quick@wg0
# 如使用了 UFW，自行删除相应 UDP 放行规则与 NAT 片段
sudo apt-get remove --purge -y wireguard wireguard-tools qrencode
sudo apt-get autoremove -y
sudo rm -rf /etc/wireguard /root/ochub_wg_clients
```

操作不可逆，请谨慎。

---

## 许可证

本项目采用 MIT License。详见仓库中的 LICENSE 文件。

---

## 免责声明

- 请确保遵守所在地区法律法规与服务提供商使用政策
- 使用本脚本即表示您理解并愿意自行承担由此带来的风险与责任

---

如果这个项目帮到了你，欢迎 Star 支持。愿每一位指挥官，都能以最少的步骤、最快的速度，拿到一套稳定、优雅、可长期托管的 WireGuard 私人网络。
