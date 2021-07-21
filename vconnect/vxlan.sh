directory="/opt/ixpcontrol/data/vconnect/configs/vxlan/PEER_*"
bridge="br0"
dirCT="/root/configs/vxlan/PEER_AS"
ipAddr=$(curl -s https://ipv4.ixpcontrol.com)
if [ -z "$(ls -A ${directory})" ]; then
  exit
fi

function check_eth {
    set -o pipefail # optional.
    /usr/sbin/ethtool "$1" | grep -q "Link detected: yes" 2>/dev/null
}

function check_bridge {
    set -o pipefail #optional
    /usr/sbin/brctl show ${bridge} | grep -q $1 2>/dev/null
}

function create_bridge {
    set -o pipefail #optional
    /usr/sbin/brctl addif ${bridge} vxlan_AS$1 2>/dev/null
}

function create_vxlan {
    set -o pipefail #optional
    /usr/sbin/ip link add vxlan_AS$1 type vxlan local ${ipAddr} remote $2 dstport 4789 id $3 ttl 255
    /usr/sbin/ip link set up dev vxlan_AS$1
    /usr/sbin/ip link set vxlan_AS$1 mtu 1550
}

function getIP {
    set -o pipefail #optional
    ip route get 8.8.8.8 | head -1 | cut -d' ' -f8
}



for file in $directory
do
userConfig=$(cat $file | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]")
echo "Parsed Configuration"
for conf in ${userConfig}; do
  eval ${conf}
done
echo "Checking If Interface Exists"



if check_eth vxlan_AS${ASN}; then
echo "Interface Exists, Check Bridge"
intExist="true"
else
echo "Interface Not Present, Create it!"
intExist="false"
fi



if [ $intExist = "true" ]; then
echo "Checking Bridge"
if check_bridge vxlan_AS${ASN}; then
echo "Interface is on Bridge, Nothing to do"
briExist="true"
else
echo "Interface is NOT present on Bridge"
briExist="false"
fi
fi



if [ $intExist = "false" ]; then
echo "Create Interface"
create_vxlan ${ASN} ${ipAddress} ${TunnelID}
create_bridge ${ASN}
fi

if [ $briExist = "false" ]; then
echo "Create Bridge"
create_bridge ${ASN}
fi


done

