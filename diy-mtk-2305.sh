#!/bin/bash
echo "🚀 开始执行 MTK 7981 终极量产白金版编译前置任务..."

# 1. 修改默认 IP
echo "🔧 正在修改默认 IP 地址为 192.168.51.1..."
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate

# 2. 修改默认主机名
echo "🏷️ 正在修改默认主机名为 Ecom-Gateway..."
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package/base-files/files/bin/config_generate

# 3. 注入 SSR-Plus 源码
echo "📦 正在拉取 luci-app-ssr-plus 源码..."
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld

# ==================== 核心排雷逻辑（完全采用你的完美名单） ====================
echo "🧹 正在清理 helloworld 冲突组件，坚定使用官方核心！..."
# 只杀掉 helloworld 里的冲突组件，绝对不动 feeds 官方库！
rm -rf package/helloworld/xray-core
rm -rf package/helloworld/v2ray-core
rm -rf package/helloworld/sing-box
rm -rf package/helloworld/shadowsocks-rust
rm -rf package/helloworld/shadow-tls
rm -rf package/helloworld/tuic-client
rm -rf package/helloworld/hysteria
rm -rf package/helloworld/trojan
rm -rf package/helloworld/naiveproxy
rm -rf package/helloworld/v2ray-geodata
rm -rf package/helloworld/microsocks
rm -rf package/helloworld/dns2tcp
rm -rf package/helloworld/tcping
rm -rf package/helloworld/v2ray-plugin
rm -rf package/helloworld/xray-plugin 

# ==================== 防爆内存与网络提速补丁 ====================
echo "🛡️ 注入防爆内存与网络提速补丁..."
# (1) 禁用官方 xray-core 的 UPX 压缩，瞬间节省 2GB+ 编译内存，防止 OOM 暴毙！
sed -i '/upx/d' feeds/packages/net/xray-core/Makefile || true

# (2) 强制 Go 语言换源，完美解决 sing-box 报 module 缺失、下载依赖超时的问题！
sed -i 's/https:\/\/proxy.golang.org/https:\/\/goproxy.cn,direct/g' feeds/packages/lang/golang/golang-package.mk || true

# (3) 开启 Rust 预编译与 Ccache 缓存
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config 
echo "CONFIG_CCACHE=y" >> .config 

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

# 延时 15 秒等待 ZT 生成虚拟网卡，然后挂载搬瓦工 Moon 卫星
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

# 阅后即焚，保持系统洁净
rm -f /etc/uci-defaults/999-custom-settings
exit 0
EOF

echo "✅ 7981 终极量产环境注入完毕！"
