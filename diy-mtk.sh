#!/bin/bash
echo "🚀 开始执行 MTK 7981 编译前置任务..."

# 1. 修改默认 IP (终极防漏杀：同时通杀官方 1.1 和 Padavanonly 的 6.1，目标改为 51.1)
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate

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

# 4. 拉取 Tailscale 图形界面源码 (破除原版无 UI 的限制)
# echo "📦 正在注入 luci-app-tailscale 源码..."
# git clone https://github.com/asvow/luci-app-tailscale.git package/luci-app-tailscale

# 5. 加入预编译 Rust 保底防线
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config

# 6. 开启全局编译缓存 (极其重要！)
echo "📦 正在开启全局 Ccache 编译缓存..."
echo "CONFIG_CCACHE=y" >> .config

echo "✅ 前置环境准备完毕，完美底盘即将移交编译引擎！"
