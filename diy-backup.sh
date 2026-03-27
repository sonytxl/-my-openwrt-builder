#!/bin/bash
echo "🚀 开始执行编译前置任务..."

# 1. 修改默认 IP
sed -i 's/192.168.1.1/192.168.61.1/g' package/base-files/files/bin/config_generate

# 2. 核心大招：拉取 SSR-Plus 源码
echo "📦 正在拉取 luci-app-ssr-plus 源码..."
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld

# 3. 物理清除 SSR-Plus 中极易报错的组件
echo "🧹 物理清除容易报错的组件..."
rm -rf package/helloworld/shadowsocks-rust
rm -rf package/helloworld/tuic-client
rm -rf package/helloworld/hysteria
rm -rf package/helloworld/trojan
rm -rf package/helloworld/naiveproxy

# 4. 加入预编译 Rust 保底防线 & 开启缓存
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config
echo "CONFIG_DEVEL=y" >> .config
echo "CONFIG_CCACHE=y" >> .config

# 5. 注入开机自动配置脚本 (密码、WiFi、ZeroTier)
echo "📜 正在注入开机自动配置脚本..."
mkdir -p package/base-files/files/etc/uci-defaults
cat << "EOF" > package/base-files/files/etc/uci-defaults/999-custom-settings
#!/bin/sh

# ================= (1) 设置默认密码 =================
sed -i 's/^\(root:\)[^:]*:/\1$1$V4UetPzk$CYXluq41wU.F4HnvQ.6hX.:/' /etc/shadow

# ================= (2) ZeroTier 自动化配置 =================
# 请把你真实的 ZeroTier 16位 Network ID 填在下面的双引号里
ZT_NET_ID="替换成你的16位ZeroTier网络ID"

# 清理可能存在的旧配置，创建全新节点
while uci -q delete zerotier.@zerotier[0]; do :; done
uci set zerotier.default_setup=zerotier
uci set zerotier.default_setup.enabled='1'
uci add_list zerotier.default_setup.join="$ZT_NET_ID"
uci set zerotier.default_setup.secret='generate'  # 核心：每次都生成全新独立身份证
uci commit zerotier

# 设置 ZeroTier 开机自启并立刻启动
/etc/init.d/zerotier enable
/etc/init.d/zerotier start

# ================= (3) 统一 WiFi 配置 =================
sleep 3
if [ -f /etc/config/wireless ]; then
    for iface in $(uci show wireless | grep "=wifi-iface" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${iface}.ssid='mywifi'
        uci set wireless.${iface}.encryption='psk2'
        uci set wireless.${iface}.key='password'
    done
    for radio in $(uci show wireless | grep "=wifi-device" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${radio}.disabled='0'
    done
    uci commit wireless
    wifi reload
fi

# ================= (4) 阅后即焚 =================
rm -f /etc/uci-defaults/999-custom-settings
exit 0
EOF

echo "✅ 前置环境准备完毕！"
