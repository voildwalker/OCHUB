<div align="center">

<pre>
 ██████╗ ██████╗██╗  ██╗██╗  ██╗██████╗
██╔═══██╗██╔════╝██║  ██║██║  ██║██╔══██╗
██║   ██║██║     ███████║██║  ██║██████╔╝
██║   ██║██║     ██╔══██║██║  ██║██╔══██╗
╚██████╔╝╚██████╗██║  ██║╚██████╔╝██████╔╝
 ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝
</pre>

<h1>OCHUB · WireGuard 一键部署与全生命周期管理</h1>
<p>Oracle Cloud mini 工具箱 - WireGuard 面板 V9.0</p>

</div>

<p align="center">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash-121011?style=flat-square&logo=gnu-bash&logoColor=white">
  <img alt="WireGuard" src="https://img.shields.io/badge/WireGuard-Auto%20Installer-88171A?style=flat-square&logo=wireguard&logoColor=white">
  <img alt="OS" src="https://img.shields.io/badge/OS-Debian%2FUbuntu-00A1FF?style=flat-square&logo=linux">
  <img alt="License" src="https://img.shields.io/github/license/voildwalker/OCHUB?style=flat-square">
</p>

简介  
高性能、极简、安全的 WireGuard 安装与管理脚本（Oracle Cloud 友好版）。复杂配置被封装为清晰的人机交互，只需几分钟即可获得稳定可靠的私人 VPN 服务。

---

## ⚡ 极速上手（熟手建议）

只需一条命令，其他交互脚本会一步步引导：
```bash
curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh | sudo bash
```

可选
- 保留脚本以便后续管理：
  ```bash
  curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh -o install_wireguard.sh
  sudo bash install_wireguard.sh
  ```
- 原始文件链接
  - 裸文件链接：https://raw.githubusercontent.com/voildwalker/OCHUB/refs/heads/main/install_wireguard.sh
  - 快捷文件链接：https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh

适用系统：Debian/Ubuntu（root 或具备 sudo 权限）

---

## 👇 新手完整指南（展开查看）

<details>
<summary><b>面向新手的图文步骤（点击展开）</b></summary>

### 1) 开始前：在 Oracle Cloud 放行端口（关键）
- 控制台 → 网络 → 虚拟云网络(VCN) → 安全列表（或 NSG）
- 添加入站规则：
  - 源类型：CIDR
  - 源 CIDR：0.0.0.0/0
  - 协议：UDP
  - 目标端口范围：建议 50000–65535 的高端口，如 51820
  - 描述：WireGuard Port
- 提示：99% 的“能连上但无法上网”问题，来自此步未正确放行

### 2) 部署脚本
- 通过 SSH 登录服务器
- 执行以下命令开始安装（或参见上方“保留脚本”方式）
  ```bash
  curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh | sudo bash
  ```
- 跟随交互：
  - 输入监听 UDP 端口（与上一步放行一致）
  - 安装完成后将自动创建首个客户端并生成二维码

### 3) 连接你的设备
- 手机端（Android / iOS）
  - 安装官方 WireGuard → “+” → 从二维码扫描 → 命名并开启
- 电脑端（Windows / macOS）
  - 安装官方客户端
  - 使用 SFTP 下载配置文件：/root/ochub_wg_clients/<你的名称>.conf
  - 在客户端中“从文件导入”

### 4) 后续管理
- 再次运行脚本进入面板：
  ```bash
  sudo bash ./install_wireguard.sh
  ```
  - 添加/删除客户端
  - 查看在线状态、握手时间、上下行流量
  - 一键卸载（不可逆）

重要路径
- 服务器配置：/etc/wireguard/wg0.conf
- 客户端配置目录：/root/ochub_wg_clients/

### 5) 常见排错
- 连上但上不了网：检查 Oracle 放行规则、UFW 状态、服务运行情况
  ```bash
  sudo ufw status
  sudo systemctl status wg-quick@wg0
  sudo systemctl restart wg-quick@wg0
  ```
- 端口冲突：
  ```bash
  sudo ss -lun | grep 51820
  ```

### 6) 卸载
- 在面板中选择“卸载 WireGuard”，或手动：
  ```bash
  sudo systemctl stop wg-quick@wg0 && sudo systemctl disable wg-quick@wg0
  sudo apt-get remove --purge -y wireguard wireguard-tools qrencode && sudo apt-get autoremove -y
  sudo rm -rf /etc/wireguard /root/ochub_wg_clients
  ```

</details>

---

## ✨ 为什么选择 OCHUB 方案
- 体验至上：交互式向导 + 智能默认，零门槛上手
- 稳定专业：内核转发、UFW、NAT 与密钥管理全自动
- 即刻可用：二维码/配置文件一键分发，多端快速连接
- 全生命周期：安装、增删用户、查看状态、卸载一体化
- 针对 Oracle Cloud 优化：明确放行步骤与常见问题提示

---

## 🧭 版本与理念（V9.0）
- Core Stability：稳定可复用的网络栈配置
- UX-First：中文交互、明确提示、友好日志
- Robust Code：依赖自检、APT 锁等待、异常处理更可读
- V9.0 焦点：ASCII 标题逐行打印、表格列对齐、确认逻辑更顺手

---

## 📜 许可证与声明
- 许可证：MIT License（见仓库 LICENSE）
- 使用前请遵守所在地区法律与服务条款；由此产生的风险与责任由用户自行承担

---

如果这个项目帮到了你，欢迎 Star。愿每位指挥官，都能以最少的步骤，获得一套稳定、优雅、可长期托管的 WireGuard 私人网络。
