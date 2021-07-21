ztInterface=$(cat /opt/ixpcontrol/data/zt.interface)
bridge="br0"

function check_interface {
    set -o pipefail # optional.
    /usr/sbin/ethtool "$1" | grep -q "Link detected: yes" 2>/dev/null
}

function check_bridge {
    set -o pipefail #optional
    /usr/sbin/brctl show ${bridge} | grep -q $1 2>/dev/null
}

function create_bridge {
    set -o pipefail #optional
    /usr/sbin/brctl addif ${bridge} ${ztInterface} 2>/dev/null
}


if check_interface ${bridge}; then
echo "Bridge is Online.. Continue"
bridgeExist="true"
else
echo "Bridge is Offline.. Exit"
exit;
fi

if check_interface ${ztInterface}; then
echo "Interface Exists, Check Bridge"
intExist="true"
else
echo "Interface Not Present, Create it!"
intExist="false"
fi



if [ $intExist = "true" ]; then
echo "Checking Bridge"
if check_bridge ${ztInterface}; then
echo "Interface is on Bridge, Nothing to do"
briExist="true"
else
echo "Interface is NOT present on Bridge"
briExist="false"
fi
fi

if [ $briExist = "true" ]; then
exit;
else
echo "Interface is NOT present on Bridge"
create_bridge ${ztInterface}
exit;
fi
fi
