#!/bin/bash
# ===================================================================================
# ochub - WireGuard 一键部署与全周期管理脚本 V9.0 (Victory Edition)
#
# 设计哲学 (Philosophy):
#   - 内核稳定 (Core Stability): 核心网络功能经过验证，确保稳定可靠。
#   - 体验至上 (UX-First): 遵从用户习惯，提供清晰、无歧义、经典的交互界面。
#   - 代码健壮 (Robust Code): 采用最佳实践，修复所有已知逻辑与UI缺陷。
#
# V9.0 更新日志 (Change Log):
#   - [最终修复] 全面采纳指挥官提供的V8.0最终修复方案。
#   - [UI] 使用printf逐行打印，彻底解决左对齐ASCII Art的渲染错乱问题。
#   - [UI] 使用“分离打印”策略，完美解决“活跃”状态下表格列对齐的顽固问题。
#   - [逻辑] 采用case语句重构确认逻辑，使卸载等操作的交互更符合用户直觉。
#
# 版权 (C) 2025 ochub.io
# 作者: AI Collective & The Commander
# ===================================================================================

# --- 脚本安全与错误处理 ---
set -eEuo pipefail
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

# --- 色彩与美学体系 ---
C_RESET=$(tput sgr0 || echo "")
C_BOLD=$(tput bold || echo "")
C_GREEN=$(tput setaf 2 || echo "")
C_WHITE=$(tput setaf 7 || echo "")
C_YELLOW=$(tput setaf 3 || echo "")
C_CYAN=$(tput setaf 6 || echo "")
C_RED_BG=$(tput setab 1 || echo "")
C_WHITE_BOLD=$(tput bold)$(tput setaf 7)

# --- 全局常量与变量 ---
WG_CONF="/etc/wireguard/wg0.conf"
CLIENT_CONFIGS_DIR="/root/ochub_wg_clients"
export DEBIAN_FRONTEND=noninteractive
LINE_SEPARATOR_CHAR="-"
LINE_WIDTH=78

# ==================================================
# 工具函数 (Utility Functions)
# ==================================================
log() { echo -e "${C_BOLD}${C_CYAN}ℹ [INFO]${C_RESET}   $1" >&2; }
ok() { echo -e "${C_BOLD}${C_GREEN}✓ [OK]${C_RESET}     $1" >&2; }
warn() { echo -e "${C_BOLD}${C_YELLOW}⚠ [WARN]${C_RESET}   $1" >&2; }
err() { echo -e "${C_BOLD}${C_RED_BG}✗ [ERROR]${C_RESET}  $1" >&2; }

handle_error() {
    local exit_code=$?
    if [ $exit_code -eq 1 ] && [[ "$2" =~ ^(read|return) ]]; then
        return
    fi
    err "在第 $1 行执行 '$2' 时发生错误 (退出码: $exit_code)。"
    log "脚本意外终止。如果您需要帮助，请将此错误信息截图。"
    exit $exit_code
}

press_any_key() {
    echo >&2
    read -n 1 -s -r -p "按任意键返回主菜单..."
    echo >&2
}

# 采用逐行printf方案，修复ASCII Art渲染问题
display_header() {
    clear
    echo
    printf "%s\n" "${C_GREEN} ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗${C_RESET}"
    printf "%s\n" "${C_GREEN}██╔═══██╗██╔════╝██║  ██║██║   ██║██╔══██╗${C_RESET}"
    printf "%s\n" "${C_GREEN}██║   ██║██║     ███████║██║   ██║██████╔╝${C_RESET}"
    printf "%s\n" "${C_GREEN}██║   ██║██║     ██╔══██║██║   ██║██╔══██╗${C_RESET}"
    printf "%s\n" "${C_GREEN}╚██████╔╝╚██████╗██║  ██║╚██████╔╝██████╔╝${C_RESET}"
    printf "%s\n" "${C_GREEN} ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝${C_RESET}"
    echo
    printf "%s\n" "${C_WHITE_BOLD}Oracle Cloud mini 工具箱 - WireGuard 面板 V9.0${C_RESET}"
}

detect_public_ip() {
    local ip
    log "正在检测公网IP..."
    ip=$(curl -s -4 --connect-timeout 5 https://ipv4.icanhazip.com 2>/dev/null) || ip=""
    if [[ -z "$ip" ]]; then
        warn "主检测接口失败，尝试备用接口..."
        ip=$(curl -s -4 --connect-timeout 5 https://api.ipify.org 2>/dev/null) || ip=""
    fi
    if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        err "无法检测到有效的公网IP地址。请检查服务器网络连接。"
        return 1
    fi
    ok "公网IP检测成功: ${C_YELLOW}${ip}${C_RESET}"
    echo "$ip"
}

check_os() {
    if ! [[ -f /etc/debian_version ]]; then
        err "本脚本目前仅为 Debian/Ubuntu 系操作系统深度优化。"
        exit 1
    fi
    if [[ "$EUID" -ne 0 ]]; then
        err "请以 root 用户权限运行本脚本 (例如: sudo ./script.sh)。"
        exit 1
    fi
}

wait_for_apt_lock() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
        warn "软件包管理器正忙 (可能在自动更新)，脚本将智能等待..."
        sleep 1
    done
}

# ==================================================
# 核心功能函数 (Core Functions)
# ==================================================
install_wireguard() {
    display_header; echo >&2
    log "开始全新安装 WireGuard..."
    local packages_to_install=()
    log "正在检查核心依赖..."
    command -v wg >/dev/null || packages_to_install+=("wireguard-tools" "wireguard")
    command -v qrencode >/dev/null || packages_to_install+=("qrencode")
    command -v ufw >/dev/null || packages_to_install+=("ufw")
    if [ ${#packages_to_install[@]} -ne 0 ]; then
        warn "检测到核心依赖未安装: ${packages_to_install[*]}"
        log "正在安装缺失的依赖..."; wait_for_apt_lock
        apt-get update -qq && apt-get install -y --no-install-recommends "${packages_to_install[@]}"
        ok "依赖安装完成。"
    else
        ok "所有核心依赖均已满足。"
    fi
    local public_ip; public_ip=$(detect_public_ip) || exit 1
    local public_interface; public_interface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    [ -z "$public_interface" ] && { err "无法自动检测到公网网络接口。"; exit 1; }
    read -p "请输入 WireGuard 监听的UDP端口 [建议50000-65535, 默认: 51820]: " listen_port
    listen_port=${listen_port:-51820}
    mkdir -p /etc/wireguard && chmod 700 /etc/wireguard
    log "正在生成服务器密钥对..."
    local server_private_key; server_private_key=$(wg genkey)
    local server_public_key; server_public_key=$(echo "${server_private_key}" | wg pubkey)
    echo "${server_private_key}" > "${WG_CONF%.conf}_server_privatekey"
    echo "${server_public_key}" > "${WG_CONF%.conf}_server_publickey"
    chmod 600 "${WG_CONF%.conf}"_*key
    ok "服务器密钥对生成完毕。"
    log "正在生成服务器配置文件..."
    cat > "$WG_CONF" <<EOF
# ================= OCHUB MANAGED CONFIG V9.0 =================
[Interface]
Address = 10.10.0.1/24
PrivateKey = ${server_private_key}
ListenPort = ${listen_port}
PostUp = ufw route allow in on %i out on ${public_interface}
PostDown = ufw route delete allow in on %i out on ${public_interface}
# ===========================================================
EOF
    chmod 600 "$WG_CONF"
    log "正在配置内核转发与防火墙..."
    if ! sysctl net.ipv4.ip_forward | grep -q "1"; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf; sysctl -p > /dev/null
    fi
    sed -i -e 's/#DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    local ufw_before_rules="/etc/ufw/before.rules"
    if ! grep -q "ochub-wireguard-nat" "$ufw_before_rules"; then
        sed -i '/\*filter/i # ochub-wireguard-nat\n*nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s 10.10.0.0/24 -o '"$public_interface"' -j MASQUERADE\nCOMMIT\n' "$ufw_before_rules"
    fi
    ufw allow "${listen_port}/udp"; ufw allow ssh
    if ! ufw status | grep -q "Status: active"; then
        warn "检测到UFW防火墙未激活，正在为您激活..."; echo "y" | ufw enable
    else
        ufw reload
    fi
    ok "内核转发与防火墙配置完毕。"
    log "正在启动 WireGuard 服务并设置为开机自启..."; systemctl enable --now wg-quick@wg0
    ok "WireGuard 服务已启动。"
    display_header; echo >&2
    ok "WireGuard 服务器端安装配置完成！"
    log "流程已无缝衔接，即将开始添加您的第一个客户端..."; sleep 2
    add_client
}

add_client() {
    display_header; echo >&2
    log "开始添加新的 WireGuard 客户端..."
    local client_name
    while true; do
        read -p "请输入客户端名称 (必须以字母开头, 或输入'c'取消): " client_name
        if [[ "${client_name,,}" == "c" ]]; then log "操作已取消。"; return; fi
        if [[ "$client_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ && ! -f "${CLIENT_CONFIGS_DIR}/${client_name}.conf" ]]; then
            break
        else
            err "名称无效或已存在。必须以字母开头，且只包含字母、数字、下划线或连字符。"
        fi
    done
    mapfile -t used_ips < <(grep -oP '10\.10\.0\.\d+' "$WG_CONF" | cut -d'.' -f4 | sort -n)
    local next_ip_octet=2
    for i in $(seq 2 254); do
        if ! [[ " ${used_ips[*]} " =~ " $i " ]]; then next_ip_octet=$i; break; fi
    done
    local client_ip="10.10.0.${next_ip_octet}"
    local client_private_key; client_private_key=$(wg genkey)
    local client_public_key; client_public_key=$(echo "$client_private_key" | wg pubkey)
    cat >> "$WG_CONF" <<EOF

# Client: ${client_name}
[Peer]
PublicKey = ${client_public_key}
AllowedIPs = ${client_ip}/32
EOF
    mkdir -p "$CLIENT_CONFIGS_DIR"
    local client_conf_path="${CLIENT_CONFIGS_DIR}/${client_name}.conf"
    local server_public_key; server_public_key=$(cat "${WG_CONF%.conf}_server_publickey")
    local server_endpoint; server_endpoint="$(detect_public_ip):$(grep ListenPort "$WG_CONF" | cut -d'=' -f2 | xargs)"
    cat > "$client_conf_path" <<EOF
[Interface]
PrivateKey = ${client_private_key}
Address = ${client_ip}/24
DNS = 1.1.1.1
[Peer]
PublicKey = ${server_public_key}
Endpoint = ${server_endpoint}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
    chmod 600 "$client_conf_path"
    log "正在应用配置..."; systemctl restart wg-quick@wg0
    ok "客户端 [${client_name}] 创建成功！"
    log "请使用手机客户端扫描下方二维码，或下载配置文件使用："
    qrencode -t utf8 -m 2 < "$client_conf_path"
    press_any_key
}

# 采用“分离打印”策略，完美解决表格对齐
list_clients() {
    if ! systemctl is-active --quiet wg-quick@wg0; then
        warn "WireGuard 服务当前未运行。"; press_any_key; return
    fi
    display_header; echo >&2
    printf "  %-18s %-16s %-21s %s\n" "客户端名称" "隧道 IP" "最后握手时间" "状态 / 流量"
    local separator; separator=$(printf '%*s' "$LINE_WIDTH" '' | tr ' ' "$LINE_SEPARATOR_CHAR")
    echo -e "  ${C_GREEN}${separator}${C_RESET}"
    local client_info; client_info=$(awk '/^# Client:/{name=$3} /^PublicKey =/{pubkey=$3} /^AllowedIPs =/{ip=$3; print name, pubkey, ip}' "$WG_CONF")
    if [ -z "$client_info" ]; then
        log "当前没有已配置的客户端。"
    else
        local live_info; live_info=$(wg show wg0 dump | tail -n +2)
        while read -r name pubkey ip; do
            printf "  %-18s %-16s" "$name" "${ip%/32}"
            local match; match=$(echo "$live_info" | grep "$pubkey" || true)
            if [[ -n "$match" ]] && [[ $(echo "$match" | awk '{print $5}') != "0" ]]; then
                local handshake_time; handshake_time=$(date -d "@$(echo "$match" | awk '{print $5}')" +"%Y-%m-%d %H:%M:%S")
                local rx_human; rx_human=$(numfmt --to=iec-i --suffix=B --format="%.2f" "$(echo "$match" | awk '{print $6}')")
                local tx_human; tx_human=$(numfmt --to=iec-i --suffix=B --format="%.2f" "$(echo "$match" | awk '{print $7}')")
                printf " %-22s" "$handshake_time"
                echo -e "${C_GREEN}活跃${C_RESET} | ↓${rx_human} / ↑${tx_human}"
            else
                printf " %-22s" "-"
                echo -e "${C_YELLOW}不活跃${C_RESET}"
            fi
        done <<< "$client_info"
    fi
    press_any_key
}

remove_client() {
    display_header; echo >&2
    log "开始移除客户端..."
    if ! [ -d "$CLIENT_CONFIGS_DIR" ] || ! ls -1qA "$CLIENT_CONFIGS_DIR" | grep -q .; then
        warn "当前没有已配置的客户端。"; press_any_key; return
    fi
    log "当前已配置的客户端列表:"
    local i=1; local clients=()
    for f in "$CLIENT_CONFIGS_DIR"/*.conf; do
        client_name=$(basename "$f" .conf)
        echo "  [${i}] ${client_name}" >&2; clients+=("$client_name"); ((i++))
    done
    read -p "请输入要移除的客户端序号 (或输入 'c' 返回): " client_choice
    if [[ "${client_choice,,}" == "c" ]]; then log "操作已取消。"; return; fi
    if ! [[ "$client_choice" =~ ^[0-9]+$ ]] || [ "$client_choice" -lt 1 ] || [ "$client_choice" -gt ${#clients[@]} ]; then
        err "无效的输入。"; return
    fi
    local client_to_remove=${clients[$((client_choice-1))]}
    log "准备移除客户端: ${C_YELLOW}${client_to_remove}${C_RESET}"
    local start_line; start_line=$(grep -n "# Client: ${client_to_remove}" "$WG_CONF" | cut -d: -f1)
    if [ -n "$start_line" ]; then
        local end_line; end_line=$(awk "NR > $start_line && /^\\[Peer\\]/{print NR-1; exit}" "$WG_CONF")
        [ -z "$end_line" ] && end_line=$(wc -l < "$WG_CONF")
        sed -i "${start_line},${end_line}d" "$WG_CONF"
    fi
    rm -f "${CLIENT_CONFIGS_DIR}/${client_to_remove}.conf"
    systemctl restart wg-quick@wg0
    ok "客户端 [${client_to_remove}] 已成功移除！"
    press_any_key
}

# 采用健壮的case语句重构确认逻辑
uninstall_wireguard() {
    display_header; echo >&2
    warn "此操作将完全卸载 WireGuard 并删除所有相关配置！"
    read -p "您确定要继续吗? (输入 'yes' 或 'y' 确认): " confirmation
    case "${confirmation,,}" in
        y|yes)
            log "开始执行卸载..."
            systemctl stop wg-quick@wg0 >/dev/null 2>&1 || true
            systemctl disable wg-quick@wg0 >/dev/null 2>&1 || true
            local listen_port; listen_port=$(grep ListenPort "$WG_CONF" 2>/dev/null | cut -d'=' -f2 | xargs) || true
            ufw delete allow "${listen_port}/udp" >/dev/null 2>&1 || true
            local ufw_before_rules="/etc/ufw/before.rules"
            if grep -q "ochub-wireguard-nat" "$ufw_before_rules"; then
                sed -i '/# ochub-wireguard-nat/,/COMMIT/d' "$ufw_before_rules"
            fi
            ufw reload >/dev/null 2>&1
            wait_for_apt_lock
            apt-get remove --purge -y wireguard wireguard-tools qrencode >/dev/null && apt-get autoremove -y >/dev/null
            rm -rf /etc/wireguard "$CLIENT_CONFIGS_DIR"
            rm -f /etc/sysctl.d/wg.conf
            ok "WireGuard 已被完全卸载。"
            log "脚本将退出。"; exit 0
            ;;
        *)
            log "卸载操作已取消。"; press_any_key
            ;;
    esac
}

display_help() {
    display_header; echo >&2
    local separator; separator=$(printf '%*s' "$LINE_WIDTH" '' | tr ' ' "$LINE_SEPARATOR_CHAR")
    echo "  这是一个帮助菜单，说明各项功能。"
    echo -e "  ${C_GREEN}${separator}${C_RESET}"
    echo "  1. 添加客户端: 创建一个新的用户配置。"
    echo "  2. 查看连接状态: 显示当前所有客户端的连接信息。"
    echo "  3. 移除客户端: 删除一个已有的用户。"
    echo "  4. 卸载 WireGuard: 彻底移除所有相关文件和配置。"
    echo -e "  ${C_GREEN}${separator}${C_RESET}"
    press_any_key
}

# ==================================================
# 主管理菜单 (Main Menu)
# ==================================================
display_main_menu() {
    display_header
    local separator; separator=$(printf '%*s' "$LINE_WIDTH" '' | tr ' ' "$LINE_SEPARATOR_CHAR")
    echo >&2
    echo -e "  ${C_GREEN}${separator}${C_RESET}" >&2
    echo -e "    ${C_WHITE}1. 添加客户端${C_RESET}" >&2
    echo -e "    ${C_WHITE}2. 查看连接状态${C_RESET}" >&2
    echo -e "    ${C_WHITE}3. 移除客户端${C_RESET}" >&2
    echo -e "    ${C_YELLOW}4. 卸载 WireGuard${C_RESET}" >&2
    echo -e "  ${C_GREEN}${separator}${C_RESET}" >&2
    echo -e "    ${C_WHITE}h. 帮助与说明${C_RESET}" >&2
    echo -e "    ${C_WHITE}q. 退出脚本${C_RESET}" >&2
    echo -e "  ${C_GREEN}${separator}${C_RESET}" >&2
}

main_menu() {
    check_os
    if [ ! -f "$WG_CONF" ]; then
        display_header
        log "检测到 WireGuard 尚未安装，即将开始引导部署..."; sleep 2
        install_wireguard
    fi
    while true; do
        display_main_menu
        read -p "  请输入你的选择: " choice
        case "${choice,,}" in
            1) add_client ;;
            2) list_clients ;;
            3) remove_client ;;
            4) uninstall_wireguard ;;
            h) display_help ;;
            q) ok "感谢使用 ochub, 再见!"; exit 0 ;;
            *) err "无效的输入，请重试。"; sleep 2 ;;
        esac
    done
}

# --- 脚本入口 ---
main_menu
