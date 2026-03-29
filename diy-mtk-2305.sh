#!/bin/bash
BJ_TIME=$(TZ='Asia/Shanghai' date +'%Y-%m-%d %H:%M:%S')
echo "🚀 开始执行 MTK 7981 终极量产版 - $BJ_TIME"

# 1. 修改默认 IP 与主机名
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package/base-files/files/bin/config_generate

# 2. 拉取 SSR-Plus 外壳并外科手术剥离冲突引擎
echo "📦 拉取并清理外壳..."
rm -rf package/helloworld
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld
rm -rf package/helloworld/mosdns package/helloworld/xray-core package/helloworld/xray-plugin package/helloworld/sing-box package/helloworld/shadowsocks-rust package/helloworld/v2ray-core package/helloworld/v2ray-geodata package/helloworld/v2ray-plugin

# 3. 注入防爆内存编译参数
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config
echo "CONFIG_CCACHE=y" >> .config

# ==================== 自动化量产物理烙印 ====================
echo "📜 正在进行 ROM 级物理烙印..."

# 4. 🚀 物理烙印：密码强行定死为 password
mkdir -p package/base-files/files/etc
cat << "EOF" > package/base-files/files/etc/shadow
root:$1$V4UetPzk$CYXluq41wU.F4HnvQ.6hX.:19436:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
EOF

# 5. 🚀 物理烙印：直接写入 ZeroTier 账号配置
mkdir -p package/base-files/files/etc/config
cat << "EOF" > package/base-files/files/etc/config/zerotier
config zerotier 'ecom_network'
	option enabled '1'
	list join '41207907b477904b'
	option secret 'generate'
	option nat '1'
EOF

# 6. 🚀 修复时序黑洞：将带“智能等待”的寻星指令写入开机启动项
mkdir -p package/base-files/files/etc
cat << "EOF" > package/base-files/files/etc/rc.local
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

(
    # 智能等待：每5秒 ping 一次公网，死等网络通畅
    while ! ping -c 1 -W 1 223.5.5.5 >/dev/null 2>&1; do
        sleep 5
    done
    # 网络通畅后，额外等待20秒，确保系统时间完成 NTP 同步
    sleep 20
    # 最终执行寻星指令
    zerotier-cli orbit 41207907b4 41207907b4
) &

exit 0
EOF

# 7. WiFi 配置使用 uci-defaults 动态注入 (因涉及硬件底层识别)
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

echo "✅ 7981 终极量产环境注入完毕！"
