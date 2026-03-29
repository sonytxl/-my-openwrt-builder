#!/bin/bash
BJ_TIME=$(TZ='Asia/Shanghai' date +'%Y-%m-%d %H:%M:%S')
echo "🚀 开始执行 XDR6088 (MT7986) 极简办公版 - $BJ_TIME"

# 1. 修改默认 IP 与主机名
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package/base-files/files/bin/config_generate

# (已移除 SSR-Plus 的拉取代码，为 HomeProxy 留出绝对纯净的底层环境)

# 2. 注入防爆内存编译参数
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config
echo "CONFIG_CCACHE=y" >> .config

# ==================== 自动化量产物理烙印 ====================
echo "📜 正在进行 ROM 级配置注入..."

# 3. WiFi 配置使用 uci-defaults 动态注入 (MT7986 通用)
mkdir -p package/base-files/files/etc/uci-defaults
cat << "EOF" > package/base-files/files/etc/uci-defaults/99-custom-wifi
#!/bin/sh
if [ -f /etc/config/wireless ]; then
    for iface in $(uci show wireless | grep "=wifi-iface" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${iface}.ssid='Ecom-WiFi'
        uci set wireless.${iface}.encryption='psk2'
        uci set wireless.${iface}.key='password'
    done
    for radio in $(uci show wireless | grep "=wifi-device" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${radio}.disabled='0'
    done
    uci commit wireless
    wifi reload
fi
rm -f /etc/uci-defaults/99-custom-wifi
exit 0
EOF

echo "✅ XDR6088 极简办公版环境注入完毕！"
