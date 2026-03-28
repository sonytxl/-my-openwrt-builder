#!/bin/bash

# 1. 修改默认 IP 地址
sed -i 's/192.168.1.1/192.168.51.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.6.1/192.168.51.1/g' package/base-files/files/bin/config_generate

# 2. 修改默认主机名
sed -i 's/ImmortalWrt/Ecom-Gateway/g' package/base-files/files/bin/config_generate

# 3. 注入 SSR-Plus 插件源码
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld

# 4. 清理冲突组件 (完全按照你前天成功的名单)
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

# 5. 优化编译环境
echo "CONFIG_RUST_USE_PREBUILT_HOST=y" >> .config
echo "CONFIG_CCACHE=y" >> .config


