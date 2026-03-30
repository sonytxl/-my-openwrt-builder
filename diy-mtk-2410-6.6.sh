#!/bin/bash
echo "🚀 开始执行 MTK 7981 编译前置任务..."

# 1. 修改默认 IP (终极防漏杀：同时通杀官方 1.1 和 Padavanonly 的 6.1，目标改为 51.1)
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package/base-files/files/bin/config_generate
 
# 2. 拉取 SSR-Plus 源码
echo "📦 正在拉取 luci-app-ssr-plus 源码..."
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld

# 3. 物理清除 SSR-Plus 中易报错的 Rust/Go 组件及冲突包
echo "🧹 物理清除容易报错的组件..."
rm -rf package/helloworld/shadowsocks-rust
rm -rf package/helloworld/shadow-tls
rm -rf package/helloworld/tuic-client
rm -rf package/helloworld/hysteria
rm -rf package/helloworld/trojan
rm -rf package/helloworld/naiveproxy
rm -rf package/helloworld/v2ray-geodata


# 3. 注入防爆内存编译参数
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config
echo "CONFIG_CCACHE=y" >> .config

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

echo "✅ 前置环境准备完毕，完美底盘即将移交编译引擎！"
