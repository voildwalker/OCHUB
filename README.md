display_header() {
  clear
  echo

  # 重块体（你的目标版，注意前后空格与缩进保持）
  read -r -d '' BANNER_BLOCK <<'EOF'
 ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗
██╔═══██╗██╔════╝██║  ██║██║   ██║██╔══██╗
██║   ██║██║     ███████║██║   ██║██████╔╝
██║   ██║██║     ██╔══██║██║   ██║██╔══██╗
╚██████╔╝╚██████╗██║  ██║╚██████╔╝██████╔╝
 ╚═════╝  ╚═════╝╚═╝  ╚═╝  ╚═════╝  ╚═════╝
EOF

  # 纯 ASCII 备选（无歧义宽度，跨终端最稳）
  read -r -d '' BANNER_ASCII <<'EOF'
  ____   ____ _   _ _   _ ____ 
 / __ \ / ___| | | | | | |  _ \
| |  | | |   | | | | | | | | | |
| |  | | |___| |_| | |_| | |_| |
 \____/  \____|\___/ \___/|____/
EOF

  # 规则：CJK 本地化或显式 OCHUB_ASCII=1 时使用 ASCII 版
  local banner="$BANNER_BLOCK"
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-C}}}" in
    *zh_*|*ja_*|*ko_* ) banner="$BANNER_ASCII" ;;
  esac
  [ "${OCHUB_ASCII:-0}" = "1" ] && banner="$BANNER_ASCII"

  # 逐行渲染，避免 echo -e 的不确定性
  while IFS= read -r line; do
    printf "%s\n" "${C_GREEN}${line}${C_RESET}"
  done <<< "$banner"

  echo
  printf "%s\n" "${C_WHITE_BOLD}Oracle Cloud mini 工具箱 - WireGuard 面板 V9.0${C_RESET}"
}

<div align="center">
<h1>OCHUB · WireGuard 一键部署与全生命周期管理</h1>
<p>Oracle Cloud mini 工具箱 - WireGuard 面板 V9.0</p>

</div>

<p align="center">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash-121011?style=flat-square&logo=gnu-bash&logoColor=white">
  <img alt="WireGuard" src="https://img.shields.io/badge/WireGuard-Auto%20Installer-88171A?style=flat-square&logo=wireguard&logoColor=white">
  <img alt="OS" src="https://img.shields.io/badge/OS-Debian%2FUbuntu-00A1FF?style=flat-square&logo=linux">
  <img alt="License" src="https://img.shields.io/github/license/voildwalker/OCHUB?style=flat-square">
</p>

<p align="center"><small>高性能、极简、安全的 WireGuard 自动化安装与管理脚本。复杂网络配置被封装为清晰的人机交互，数分钟上线稳定可靠的私人 VPN。</small></p>

---

## ⚡ 极速上手（熟手优先）

只需一条命令，后续全部由交互式面板引导完成：
```bash
curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh | sudo bash
```

<small>
- 保留脚本（便于日后管理）：
  
  ```bash
  curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh -o install_wireguard.sh
  sudo bash install_wireguard.sh
  ```
- 原始文件：  
  裸链：https://raw.githubusercontent.com/voildwalker/OCHUB/refs/heads/main/install_wireguard.sh  
  快链：https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh

适用系统：Debian/Ubuntu（root 或具备 sudo 权限）
</small>

---

## ✨ 亮点特性（简要）

<ul>
  <li><small>体验至上：交互式向导 + 智能默认，零门槛上手</small></li>
  <li><small>稳定专业：内核转发、UFW、防火墙 NAT、密钥与端口全自动</small></li>
  <li><small>开箱即用：自动生成客户端配置与二维码，手机一扫即连</small></li>
  <li><small>全生命周期：安装、增删用户、查看状态、完全卸载一体化</small></li>
  <li><small>针对 Oracle Cloud 优化：明确放行步骤与常见问题提示</small></li>
</ul>

---

## 👇 新手完整指南（点击展开）

<details>
<summary><b>面向新手的图文步骤</b></summary>

### 1) 安装前：在 Oracle Cloud 放行端口（关键）
- 控制台 → 网络 → 虚拟云网络(VCN) → 安全列表（或 NSG）
- 添加入站规则：
  - 源类型：CIDR
  - 源 CIDR：0.0.0.0/0
  - 协议：UDP
  - 目标端口范围：建议 50000–65535 的高端口（如 51820）
  - 描述：WireGuard Port  
- 提示：99% 的“能连上但无法上网”问题源自此步未正确放行

### 2) 部署脚本
- 通过 SSH 登录服务器
- 执行：
  ```bash
  curl -sSL https://raw.githubusercontent.com/voildwalker/OCHUB/main/install_wireguard.sh | sudo bash
  ```
- 跟随交互：输入监听端口（与上一步一致）→ 自动创建首个客户端并显示二维码

### 3) 连接设备
- 手机端（Android / iOS）：安装官方 WireGuard → “+” → 从二维码扫描 → 命名并开启
- 电脑端（Windows / macOS）：安装官方客户端 → SFTP 下载配置文件 /root/ochub_wg_clients/<name>.conf → 从文件导入

### 4) 后续管理
- 再次运行脚本进入面板：
  ```bash
  sudo bash ./install_wireguard.sh
  ```
  - 添加/删除客户端
  - 查看活跃状态、握手时间、上下行流量
  - 一键卸载（不可逆）

重要路径
- 服务器配置：/etc/wireguard/wg0.conf  
- 客户端目录：/root/ochub_wg_clients/

### 5) 常见排错
```bash
# 防火墙状态
sudo ufw status

# 服务状态
sudo systemctl status wg-quick@wg0

# 重启服务
sudo systemctl restart wg-quick@wg0

# 端口占用
sudo ss -lun | grep 51820
```

### 6) 卸载（如需）
- 在面板中选择“卸载 WireGuard”，或手动：
```bash
sudo systemctl stop wg-quick@wg0 && sudo systemctl disable wg-quick@wg0
sudo apt-get remove --purge -y wireguard wireguard-tools qrencode && sudo apt-get autoremove -y
sudo rm -rf /etc/wireguard /root/ochub_wg_clients
```

</details>

---

## 🧭 版本与理念（V9.0）

<ul>
  <li><small>Core Stability：稳定、可复用的网络栈</small></li>
  <li><small>UX-First：中文交互、明确提示、友好日志</small></li>
  <li><small>Robust Code：依赖自检、APT 锁等待、异常更可读</small></li>
  <li><small>V9.0 焦点：ASCII 标题逐行打印、表格列对齐、确认逻辑更顺手</small></li>
</ul>

---

## 📜 许可证与声明
<small>
- 许可证：MIT License（见仓库 LICENSE）  
- 使用前请遵守所在地区法律与服务条款；由此产生的风险与责任由用户自行承担
</small>

---

<p align="center"><small>如果这个项目帮到了你，欢迎 Star。愿每位指挥官，都能以最少的步骤，获得一套稳定、优雅、可长期托管的 WireGuard 私人网络。</small></p>
