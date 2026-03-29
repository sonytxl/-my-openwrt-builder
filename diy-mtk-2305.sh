#!/bin/bash
BJ_TIME=$(TZ='Asia/Shanghai' date +'%Y-%m-%d %H:%M:%S')
echo "🚀 开始执行 MTK 7981 终极量产版 (原生纯血引擎 + SSR-Plus 外科手术移植) - $BJ_TIME"

# 1. 修改默认 IP 与主机名
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package/base-files/files/bin/config_generate

# ==================== ☢️ 放弃破坏性换源，采用“外科手术移植” ☢️ ====================
# 既然 padavanonly 的原生引擎最完美兼容，我们绝不去破坏它们！我们只借用 SSR-Plus 的 UI 壳子。

echo "📦 正在拉取 fw876 helloworld 源码..."
rm -rf package/helloworld
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld

echo "🧹 正在剔除 helloworld 中与原生系统冲突的底层引擎..."
# 核心大招：删掉这堆自带的引擎，强迫 SSR-Plus 去使用 padavanonly 原生自带的 xray 和 mosdns！
# 彻底解决 1 秒报错、跨国断流、和架构污染！
rm -rf package/helloworld/mosdns
rm -rf package/helloworld/xray-core
rm -rf package/helloworld/xray-plugin
rm -rf package/helloworld/sing-box
rm -rf package/helloworld/shadowsocks-rust
rm -rf package/helloworld/v2ray-core
rm -rf package/helloworld/v2ray-geodata
rm -rf package/helloworld/v2ray-plugin

# ==================== 防爆内存补丁 ====================
echo "🛡️ 注入防爆内存与全局缓存..."
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config
echo "CONFIG_CCACHE=y" >> .config

# ==================== 自动化量产注入 ====================
echo "📜 正在注入开机自动配置脚本 (ZeroTier + Moon + WiFi + 密码)..."
mkdir -p package/base-files/files/etc/uci-defaults
cat << "EOF" > package/base-files/files/etc/uci-defaults/999-custom-settings
#!/bin/sh
sed -i 's/^\(root:\)[^:]*:/\1$1$V4UetPzk$CYXluq41wU.F4HnvQ.6hX.:/' /etc/shadow

ZT_NET_ID="41207907b477904b"
while uci -q delete zerotier.@zerotier[0]; do :; done
uci set zerotier.default_setup=zerotier
uci set zerotier.default_setup.enabled='1'
uci add_list zerotier.default_setup.join="$ZT_NET_ID"
uci set zerotier.default_setup.secret='generate'
uci commit zerotier

/etc/init.d/zerotier enable
/etc/init.d/zerotier start

(
    sleep 15
    zerotier-cli orbit 41207907b4 41207907b4
) &

sleep 3
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

rm -f /etc/uci-defaults/999-custom-settings
exit 0
EOF

echo "✅ 7981 终极量产环境注入完毕！"
