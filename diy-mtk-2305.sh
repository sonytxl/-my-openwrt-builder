#!/bin/bash
echo "🚀 开始执行 MTK 7981 (23.05 分支) 终极量产版编译前置任务..."

# 1. 修改默认 IP
echo "🔧 正在修改默认 IP 地址为 192.168.51.1..."
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate 

# 2. 修改默认主机名
echo "🏷️ 正在修改默认主机名为 Ecom-Gateway..."
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package /base-files/files/bin/config_generate 

# 3. 注入 SSR-Plus 源码
echo "📦 正在拉取 luci-app-ssr-plus 源码..."
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld 

# 4. 解决冲突：按照你提供的名单物理清除冲突组件，确保 xray 编译不挂
echo "🧹 正在清理冲突组件..."
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

# 5. 加入预编译 Rust 保底防线
echo "🛡️ 注入 Rust 预编译防线..."
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config 

# 6. 开启全局编译缓存 (因为你有缓存，这个必须开)
echo "⚡ 开启全局 Ccache 编译缓存..."
echo "CONFIG_CCACHE=y" >> .config 

# 7. 注入开机自动配置脚本 (核心：密码/WiFi/ZeroTier 三合一)
echo "📜 正在注入开机自动配置脚本..."
mkdir -p package/base-files/files/etc/uci-defaults
cat << "EOF" > package/base-files/files/etc/uci-defaults/999-custom-settings
#!/bin/sh

# (1) 设置路由器默认登录密码为 password
sed -i 's/^\(root:\)[^:]*:/\1$1$V4UetPzk$CYXluq41wU.F4HnvQ.6hX.:/' /etc/shadow [cite: 2]

# (2) ZeroTier 全自动静默加入与 Moon 挂载
# 填入你刚才在搬瓦工面板生成的 16位 Network ID
ZT_NET_ID="41207907b477904b"

# 配置 UCI 开启 ZeroTier
while uci -q delete zerotier.@zerotier[0]; do :; done
uci set zerotier.default_setup=zerotier
uci set zerotier.default_setup.enabled='1'
uci add_list zerotier.default_setup.join="$ZT_NET_ID"
uci set zerotier.default_setup.secret='generate'
uci commit zerotier

# 启动服务并挂载 Moon 卫星
/etc/init.d/zerotier enable
/etc/init.d/zerotier start

# 等待 ZT 服务初始化，然后捕获你的搬瓦工 Moon 卫星 (10位 ID: 41207907b4)
(
    sleep 15
    zerotier-cli orbit 41207907b4 41207907b4
) &

# (3) 统一 WiFi 名字与密码 (SSID: Ecom-WiFi)
sleep 3
if [ -f /etc/config/wireless ]; then
    for iface in $(uci show wireless | grep "=wifi-iface" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${iface}.ssid='Ecom-WiFi'
        uci set wireless.${iface}.encryption='psk2'
        uci set wireless.${iface}.key='password'
    done [cite: 3, 4]
    
    for radio in $(uci show wireless | grep "=wifi-device" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${radio}.disabled='0'
    done [cite: 5]
    
    uci commit wireless
    wifi reload
fi

# 阅后即焚
rm -f /etc/uci-defaults/999-custom-settings
exit 0
EOF

echo "✅ 终极量产环境注入完毕！"
