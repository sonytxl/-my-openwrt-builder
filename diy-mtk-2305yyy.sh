#!/bin/bash
echo "🚀 开始执行 MTK 7981 终极量产白金版 (sbwml 核弹级稳定版)..."

# 1. 修改默认 IP
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate

# 2. 修改默认主机名
sed -i 's/ImmortalWrt/Ecom-7981/g' package/base-files/files/bin/config_generate

# ==================== ☢️ 核心换源破局 ☢️ ====================
# 3. 放弃老旧的 fw876，拉取 sbwml 的 v5 稳定版！
# 这是专为 23.05 优化的版本，自带极稳的内核，永不报 Go 依赖错误！
echo "📦 正在拉取 sbwml 终极稳定版源码..."
rm -rf package/helloworld
git clone --depth=1 -b v5 https://github.com/sbwml/openwrt_helloworld package/helloworld

# 4. 彻底物理屏蔽官方 feeds 中带 Bug 的组件，全面接管！
# 既然官方的坏了，我们就统统删掉，强迫系统使用 sbwml 提供的完美版
echo "🧹 正在清理官方毒瘤组件..."
rm -rf feeds/packages/net/xray-core
rm -rf feeds/packages/net/sing-box
rm -rf feeds/packages/net/v2ray-core
rm -rf feeds/packages/net/v2ray-geodata

# ==================== 防爆内存与网络提速补丁 ====================
echo "🛡️ 注入防爆内存与网络提速补丁..."
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config 
echo "CONFIG_CCACHE=y" >> .config 
sed -i 's/https:\/\/proxy.golang.org/https:\/\/goproxy.cn,direct/g' feeds/packages/lang/golang/golang-package.mk || true

# ==================== 自动化量产注入 ====================
echo "📜 正在注入开机自动配置脚本 (ZeroTier + Moon + WiFi + 密码)..."
mkdir -p package/base-files/files/etc/uci-defaults
cat << "EOF" > package/base-files/files/etc/uci-defaults/999-custom-settings
#!/bin/sh

# (1) 设置路由器默认后台密码为 password
sed -i 's/^\(root:\)[^:]*:/\1$1$V4UetPzk$CYXluq41wU.F4HnvQ.6hX.:/' /etc/shadow

# (2) ZeroTier 全自动静默加入与 Moon 挂载
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

# (3) 统一 WiFi 名字为 Ecom-WiFi，密码为 password
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

echo "✅ 7981 终极量产环境 (sbwml 版) 注入完毕！"
