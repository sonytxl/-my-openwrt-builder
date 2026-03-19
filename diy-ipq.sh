#!/bin/bash
echo "🚀 开始注入 JDCloud AX1800 Pro (亚瑟) 专属配置..."

# 1. 修改默认 IP 地址
sed -i 's/192.168.1.1/192.168.61.1/g' package/base-files/files/bin/config_generate
echo "✅ 默认 IP 已修改为 192.168.61.1"

# 2. 核心插件与 Web UI 注入
cat >> .config <<EOF

# =======================================================
# 🌐 唤醒 Web 界面 (LuCI) 与中文支持
# =======================================================
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-app-autoreboot=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
# CONFIG_PACKAGE_luci-app-usb-printer=y

# =======================================================
# 🛠️ 基础实用工具
# =======================================================
CONFIG_PACKAGE_luci-app-autoreboot=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-upnp=y

# =======================================================
# 🚀 现代科学上网核心 (原生支持 fw4 + NSS 硬件加速)
# =======================================================
CONFIG_PACKAGE_luci-app-homeproxy=y

# =======================================================
# 🌍 异地组网 / 虚拟局域网
# =======================================================
CONFIG_PACKAGE_luci-app-wireguard=y
CONFIG_PACKAGE_luci-app-zerotier=y

# 强制开启 NSS 硬件加速引擎的 LuCI 控制面板 (如果有的话)
CONFIG_PACKAGE_luci-app-nss-ecm=y
EOF

echo "✅ LuCI 界面及 HomeProxy 插件已成功注入 .config！"
