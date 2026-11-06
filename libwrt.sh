#!/bin/bash
# 360V6 默认设置
# 由 .github/workflows/IPQ60XX-6.12-WIFI.yml 在源码目录（openwrt/）下执行

# ---------- 默认 LAN 地址 ----------
# 光猫如果也是 192.168.1.1，这里必须改，否则拨号后管理页进不去
LAN_IP='10.0.7.1'
sed -i "s/192\.168\.1\.1/${LAN_IP}/g" package/base-files/files/bin/config_generate

# ---------- 主机名 ----------
# 25.12-nss 起上游默认值从 OpenWrt 改成 LibWrt，两种都匹配，
# 否则 sed 匹配不到也不报错，主机名会静默保持 LibWrt
sed -i -E "s/hostname='(OpenWrt|LibWrt)'/hostname='360V6'/" package/base-files/files/bin/config_generate

# ---------- 时区 ----------
# 25.12-nss 上游已经是 CST-8 / Asia/Shanghai，这两条现在是幂等的兜底，
# 万一以后上游改回 UTC 仍然能生效
sed -i -E "s/timezone='(UTC|GMT0)'/timezone='CST-8'/" package/base-files/files/bin/config_generate
sed -i -E "s/zonename='(UTC|Etc\/UTC)'/zonename='Asia\/Shanghai'/" package/base-files/files/bin/config_generate

# ---------- 插件默认关闭 ----------
# 首次启动执行一次，之后脚本自动删除（OpenWrt 的 uci-defaults 机制）
# 需要用时在 LuCI 对应页面勾选"启用"，功能不受影响
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-plugins-off <<'PLUGINEOF'
#!/bin/sh
# 原则：需要先配置才有意义、配错还会影响上网的，默认不启动；
#       装上就能自动干活的（vnstat2 / nlbwmon），保持默认启用。

# ddns / ddns-go：没填域名和凭据时只会定期失败重试，纯噪音
# （ddns-go 的 init 名字是 ddns-go，ddns-scripts 是 ddns，两个都处理，装哪个都覆盖）
for s in ddns ddns-go; do
	if [ -x "/etc/init.d/$s" ]; then
		/etc/init.d/$s disable
		/etc/init.d/$s stop >/dev/null 2>&1
	fi
done

# NTP：换成国内源，开机对时快很多（默认 pool.ntp.org 经常超时）
uci -q delete system.ntp.server
uci -q add_list system.ntp.server='ntp.aliyun.com'
uci -q add_list system.ntp.server='ntp.tencent.com'
uci -q add_list system.ntp.server='cn.pool.ntp.org'
uci -q commit system

# LuCI 默认中文
uci -q set luci.main.lang='zh_cn'
uci -q commit luci

exit 0
PLUGINEOF
chmod +x package/base-files/files/etc/uci-defaults/99-plugins-off

# ---------- 默认密码 ----------
# 置空则首次登录免密（不安全）；要设密码就取消注释并改值
# sed -i "s/root:::0:99999:7:::/root:$1$xxxxxxxx$xxxxxxxxxxxxxxxxxxxxxx:0:0:99999:7:::/" package/base-files/files/etc/shadow

exit 0
