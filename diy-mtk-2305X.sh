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

# 6. 设置默认密码与统一 WiFi (前天的原生版本)
mkdir -p package/base-files/files/etc/uci-defaults
cat << "EOF" > package/base-files/files/etc/uci-defaults/99-ecom-setup
#!/bin/sh

sed -i 's/^\(root:\)[^:]*:/\1$1$V4UetPzk$CYXluq41wU.F4HnvQ.6hX.:/' /etc/shadow

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

rm -f /etc/uci-defaults/99-ecom-setup
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-ecom-setup
