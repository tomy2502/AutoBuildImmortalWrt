#!/bin/sh
# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "[tomy] Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "[tomy] Starting 99-custom.sh at $(date)"

# 设置默认防火墙规则，方便虚拟机首次访问 WebUI
# uci set firewall.@zone[1].input='ACCEPT'

# 计算网卡数量
count=0
ifnames=""
for iface in /sys/class/net/*; do
  iface_name=$(basename "$iface")
  # 检查是否为物理网卡（排除回环设备和无线设备）
  if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
    count=$((count + 1))
    ifnames="$ifnames $iface_name"
  fi
done
# 删除多余空格
ifnames=$(echo "$ifnames" | awk '{$1=$1};1')

# 网络设置
if [ "$count" -eq 1 ]; then
   # 单网口设备 类似于NAS模式 动态获取ip模式 具体ip地址取决于上一级路由器给它分配的ip 也方便后续你使用web页面设置旁路由
   # 单网口设备 不支持修改ip 不要在此处修改ip 
   uci set network.lan.proto='dhcp'
elif [ "$count" -gt 1 ]; then
   # 提取第一个接口作为WAN
   wan_ifname=$(echo "$ifnames" | awk '{print $1}')
   # 剩余接口保留给LAN
   lan_ifnames=$(echo "$ifnames" | cut -d ' ' -f2-)
   # 设置WAN接口基础配置
   uci set network.wan=interface
   # 提取第一个接口作为WAN
   uci set network.wan.device="$wan_ifname"
   # WAN接口默认DHCP
   uci set network.wan.proto='dhcp'
   # 设置WAN6绑定网口eth0
   uci set network.wan6=interface
   uci set network.wan6.device="$wan_ifname"
   # 更新LAN接口成员
   # 查找对应设备的section名称
   section=$(uci show network | awk -F '[.=]' '/\.@?device\[\d+\]\.name=.br-lan.$/ {print $2; exit}')
   if [ -z "$section" ]; then
      echo "error：cannot find device 'br-lan'." >> $LOGFILE
   else
      # 删除原来的ports列表
      uci -q delete "network.$section.ports"
      # 添加新的ports列表
      for port in $lan_ifnames; do
         uci add_list "network.$section.ports"="$port"
      done
      echo "ports of device 'br-lan' are update." >> $LOGFILE
   fi
   # LAN口设置静态IP
   uci set network.lan.proto='static'
   # 多网口设备 支持修改为别的ip地址
   uci set network.lan.ipaddr='192.168.199.1'
   uci set network.lan.netmask='255.255.255.0'
   echo "[tomy] set 192.168.199.1 at $(date)" >> $LOGFILE
   echo "[tomy] set 192.168.199.1 at $(date)"
   # 判断是否启用 PPPoE
   echo "[tomy] print enable_pppoe value=== $enable_pppoe" >> $LOGFILE
   echo "[tomy] print enable_pppoe value=== $enable_pppoe"
   if [ "$enable_pppoe" = "yes" ]; then
      echo "PPPoE is enabled at $(date)" >> $LOGFILE
      # 设置ipv4宽带拨号信息
      uci set network.wan.proto='pppoe'
      uci set network.wan.username=$pppoe_account
      uci set network.wan.password=$pppoe_password
      uci set network.wan.peerdns='1'
      uci set network.wan.auto='1'
      # 设置ipv6 默认不配置协议
      uci set network.wan6.proto='none'
      echo "[tomy] PPPoE configuration completed successfully." >> $LOGFILE
      echo "[tomy] PPPoE configuration completed successfully."
   else
      echo "[tomy] PPPoE is not enabled. Skipping configuration." >> $LOGFILE
      echo "[tomy] PPPoE is not enabled. Skipping configuration."
   fi
fi

echo "[tomy] Set DHCP host. at $(date)" >> $LOGFILE
echo "[tomy] Set DHCP host. at $(date)"
# 添加静态 DHCP 配置
uci add dhcp host
uci set dhcp.@host[-1].name='ketingBOX'
uci set dhcp.@host[-1].mac='00:66:DE:0E:82:69'
uci set dhcp.@host[-1].ip='192.168.199.169'

uci add dhcp host
uci set dhcp.@host[-1].name='TOMY'
uci set dhcp.@host[-1].mac='90:09:D0:65:8D:07'
uci set dhcp.@host[-1].ip='192.168.199.223'

uci add dhcp host
uci set dhcp.@host[-1].name='huaweiP30'
uci set dhcp.@host[-1].mac='4E:E9:44:A2:7A:D0'
uci set dhcp.@host[-1].ip='192.168.199.157'

uci add dhcp host
uci set dhcp.@host[-1].name='Z7S'
uci set dhcp.@host[-1].mac='14:C0:50:05:F7:6B'
uci set dhcp.@host[-1].ip='192.168.199.131'

uci add dhcp host
uci set dhcp.@host[-1].name='lilliantekiiPad'
uci set dhcp.@host[-1].mac='46:B5:CA:6C:72:2F'
uci set dhcp.@host[-1].ip='192.168.199.114'

uci add dhcp host
uci set dhcp.@host[-1].name='jimmyPC'
uci set dhcp.@host[-1].mac='D4:6D:6D:31:19:6F'
uci set dhcp.@host[-1].ip='192.168.199.214'

uci add dhcp host
uci set dhcp.@host[-1].name='jimmyMOBILE'
uci set dhcp.@host[-1].mac='92:D6:47:F9:22:CF'
uci set dhcp.@host[-1].ip='192.168.199.147'

uci add dhcp host
uci set dhcp.@host[-1].name='XBOXONE'
uci set dhcp.@host[-1].mac='1C:1A:DF:35:65:7F'
uci set dhcp.@host[-1].ip='192.168.199.196'

echo "[tomy] Set FireWall redirect. at $(date)" >> $LOGFILE
echo "[tomy] Set FireWall redirect. at $(date)"
# 防火墙端口转发
uci add firewall redirect
uci set firewall.@redirect[-1].name='8378'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='8378'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.1'
uci set firewall.@redirect[-1].dest_port='80'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='ssh'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='30202'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.1'
uci set firewall.@redirect[-1].dest_port='22'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='myfrp-1'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='7000'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.1'
uci set firewall.@redirect[-1].dest_port='7000'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='myfrp-2'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='7501'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.1'
uci set firewall.@redirect[-1].dest_port='7501'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='driver1'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='5000'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='5000'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='driver12'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='6690'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='6690'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='aria2-1'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='6800'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='6800'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='aria2-2'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='6880'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='6880'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='memos'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='5230'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='5230'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='purpur'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='25565'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='25565'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='purpur-voicechat'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='24454'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='24454'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='ssh223'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='22222'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='22222'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='astroBOT'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='6185'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='6185'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

uci add firewall redirect
uci set firewall.@redirect[-1].name='cloudsaver'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='8008'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.199.223'
uci set firewall.@redirect[-1].dest_port='8008'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].target='DNAT'

# 不用做盒子tv，不设置该域名映射
# 设置主机名映射，解决安卓原生 TV 无法联网的问题
# uci add dhcp domain
# uci set "dhcp.@domain[-1].name=time.android.com"
# uci set "dhcp.@domain[-1].ip=203.107.6.88"

# 检查配置文件pppoe-settings是否存在 该文件由build.sh动态生成
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "[tomy] PPPoE settings file not found. Skipping." >> $LOGFILE
    echo "[tomy] PPPoE settings file not found. Skipping."
else
   # 读取pppoe信息($enable_pppoe、$pppoe_account、$pppoe_password)
   . "$SETTINGS_FILE"
fi

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface

# 设置所有网口可连接 SSH
uci set dropbear.@dropbear[0].Interface=''

# 提交上述设置内容
uci commit

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Compiled by Tomy"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
