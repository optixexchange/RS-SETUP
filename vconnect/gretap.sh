directory="/opt/ixpcontrol/data/vconnect/configs/gretap/PEER_*"
bridge="br0"
dirCT="/root/configs/gretap/PEER_AS"
ipAddr=$(curl -s https://ipv4.ixpcontrol.com)
if [ -z "$(ls -A ${directory})" ]; then
  exit
fi

function check_eth {
    set -o pipefail # optional.
    /usr/sbin/ethtool $1 | grep -q "Link detected: yes" 2>/dev/null
}

function check_bridge {
    set -o pipefail #optional
    /usr/sbin/brctl show ${bridge} | grep -q $1 2>/dev/null
}

function create_bridge {
    set -o pipefail #optional
    /usr/sbin/brctl addif ${bridge} gretap_AS$1 2>/dev/null
}

function create_gre {
    set -o pipefail #optional
     /usr/sbin/ip link add gretap_AS$1 type gretap local ${ipAddr} remote $2 ttl 255
     /usr/sbin/ip link set up dev gretap_AS$1
     /usr/sbin/ip link set gretap_AS$1 mtu 1550
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



if check_eth gretap_AS${ASN}; then
echo "Interface Exists, Check Bridge"
intExist="true"
else
echo "Interface Not Present, Create it!"
intExist="false"
fi



if [ $intExist = "true" ]; then
echo "Checking Bridge"
  if check_bridge gretap_AS${ASN}; then
echo "Interface is on Bridge, Nothing to do"
briExist="true"
  else
echo "Interface is NOT present on Bridge"
briExist="false"
  fi
fi



if [ $intExist = "false" ]; then
echo "Create Interface"
create_gre ${ASN} ${ipAddress}
create_bridge ${ASN}
fi

if [ $briExist = "false" ]; then
echo "Create Bridge"
create_bridge ${ASN}
fi
done

