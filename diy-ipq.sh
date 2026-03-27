#!/bin/bash
echo "🚀 开始执行 JDCloud AX1800 Pro 编译前置任务..."

# 1. 修改默认 IP
sed -i 's/192.168.1.1/192.168.61.1/g' package/base-files/files/bin/config_generate

# 2. 核心大招：拉取 SSR-Plus 源码供你上传的 .config 读取！
echo "📦 正在拉取 luci-app-ssr-plus 源码..."
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld

# 3. 物理清除 SSR-Plus 中极易报错的 Rust/高耗时组件
echo "🧹 物理清除容易报错的组件..."
rm -rf package/helloworld/shadowsocks-rust
rm -rf package/helloworld/tuic-client
rm -rf package/helloworld/hysteria
rm -rf package/helloworld/trojan
rm -rf package/helloworld/naiveproxy

# 4. 加入预编译 Rust 保底防线
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config

# 5. 开启全局编译缓存 (高通提速核心！)
echo "📦 正在开启高通全局 Ccache 编译缓存..."
echo "CONFIG_DEVEL=y" >> .config
echo "CONFIG_CCACHE=y" >> .config

# 6. 注入开机自动配置脚本 (核心：密码与WiFi统一)
echo "📜 正在注入开机自动配置脚本 (后台密码与WiFi设定)..."
mkdir -p package/base-files/files/etc/uci-defaults
cat << "EOF" > package/base-files/files/etc/uci-defaults/999-custom-settings
#!/bin/sh

# (1) 设置路由器默认登录密码为 password (写入加密后的 Hash 值)
sed -i 's/^\(root:\)[^:]*:/\1$1$V4UetPzk$CYXluq41wU.F4HnvQ.6hX.:/' /etc/shadow

# (2) 设置所有 WiFi 频段名称为 mywifi，密码为 password
# 等待系统自动生成默认 WiFi 配置文件后执行拦截修改
sleep 3
if [ -f /etc/config/wireless ]; then
    # 遍历并修改所有无线接口 (自动兼容 2.4G 和 5G)
    for iface in $(uci show wireless | grep "=wifi-iface" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${iface}.ssid='mywifi'
        uci set wireless.${iface}.encryption='psk2'
        uci set wireless.${iface}.key='password'
    done
    
    # 遍历并强制开启所有物理无线网卡
    for radio in $(uci show wireless | grep "=wifi-device" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci set wireless.${radio}.disabled='0'
    done
    
    uci commit wireless
    wifi reload
fi

# 脚本运行一次后自我删除，防止每次开机都重置
rm -f /etc/uci-defaults/999-custom-settings
exit 0
EOF

echo "✅ 高通前置环境准备完毕，完美底盘即将移交编译引擎！"
