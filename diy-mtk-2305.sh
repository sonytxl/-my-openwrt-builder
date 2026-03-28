#!/bin/bash
BJ_TIME=$(TZ='Asia/Shanghai' date +'%Y-%m-%d %H:%M:%S')
echo "🚀 开始执行 MTK 7981 终极量产白金版 (sbwml 稳定版) - 当前北京时间: $BJ_TIME"

# 1. 修改默认 IP 与主机名
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package/base-files/files/bin/config_generate

# ==================== ☢️ 核心换源破局 (填平所有依赖黑洞) ☢️ ====================
echo "🧹 清理官方旧毒瘤组件..."
rm -rf feeds/packages/net/xray-core
rm -rf feeds/packages/net/sing-box
rm -rf feeds/packages/net/v2ray-core
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/v2dat

echo "📦 正在拉取 sbwml 极稳版全家桶 (补齐所有的依赖空洞)..."
# (1) 核心代理组件 (xray-core, sing-box, ssr-plus等)
rm -rf package/helloworld
git clone --depth=1 -b v5 https://github.com/sbwml/openwrt_helloworld package/helloworld

# (2) ⚠️ 救命稻草 1：完美适配的 MosDNS 和 v2dat
git clone --depth=1 -b v5 https://github.com/sbwml/luci-app-mosdns package/mosdns

# (3) ⚠️ 救命稻草 2：完美适配的 v2ray-geodata (xray-core 强依赖此项，缺少会一秒暴毙！)
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# ==================== ⚙️ 核心编译器升级 ⚙️ ====================
echo "🔄 正在替换底层 Go 编译器版本为 1.23 (sbwml 强制要求)..."
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 23.x feeds/packages/lang/golang

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
