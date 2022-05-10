#!/bin/bash

read -p 'Net name [default: vpn]' net_name
read -p 'Host name [default: node0]' host_name
read -p 'Interface [default: tun0]' interface
read -p $'client or server?\n0 client\n1 server\nchoice [default: 0]' cs

set_default(){
    if [ -z "`eval echo '$'"${1}"`" ]
    then
        eval $1=$2
    fi
}

set_default net_name vpn
set_default host_name node0
set_default interface tun0
set_default cs 0

#echo $net_name $host_name $interface $cs

if [ $cs = 0 ]
then
    read -p 'the server host name you will connect:' server_name
elif [ $cs = 1 ]
then
    read -p 'Global Ipv4 Address(if not,leave it blank):' ipv4_addr
    read -p 'Global Ipv6 Address(if not,leave it blank):' ipv6_addr
    read -p 'Listen Port[default: 655]' port
fi
set_default port 655

read -p 'Local ipv4 address[default: 10.0.0.1/24]:' local_ipv4_addr
read -p 'Local ipv6 address[default: fec0::1/64]:' local_ipv6_addr

set_default local_ipv4_addr "10.0.0.1/24"
set_default local_ipv6_addr "fec0::1/64"

read -p 'Number of Share Subnet[default: 0]' num
set_default num 0

if [ $num > 0 ]
then
    echo 'Please input Subnet(format:10.2.7.0/24 or ::/0)'
fi

for ((i=0;i<$num;i++))
do
    read -p "Subnet $i :" subnet[$i]
done

echo '---Start generating configuration file---'
mkdir -p /etc/tinc/$net_name/hosts
chmod -R 755 /etc/tinc/$net_name
cd /etc/tinc/$net_name/

############# tinc.conf ################
touch tinc.conf

echo "Name = $host_name" | tee -a  tinc.conf 
echo "AddressFamily = any" | tee -a  tinc.conf
if [ $cs = 0 ]
then
    echo "ConnectTo = $server_name" | tee -a  tinc.conf
elif [ $cs = 1 ]
then
    echo "BindToAddress = * $port" | tee -a  tinc.conf
fi
echo "Interface = $interface" | tee -a  tinc.conf
echo "Device = /dev/net/tun" | tee -a  tinc.conf
echo "PrivateKeyFile=/etc/tinc/$net_name/rsa_key.priv" | tee -a  tinc.conf

############### tinc-up #################
touch tinc-up
echo "#!/bin/sh" | tee -a  tinc-up
echo "ip addr add $local_ipv4_addr dev \$INTERFACE" | tee -a  tinc-up
echo "ip -6 addr add $local_ipv6_addr dev \$INTERFACE" | tee -a  tinc-up
echo "ip link set \$INTERFACE up" | tee -a  tinc-up

############### tinc-down ################
touch tinc-down
echo "#!/bin/sh" | tee -a  tinc-down
echo "ip route del $local_ipv4_addr dev \$INTERFACE" | tee -a  tinc-down
echo "ip -6 route del $local_ipv6_addr dev \$INTERFACE" | tee -a  tinc-down
echo "ifconfig \$INTERFACE down" | tee -a  tinc-down

if [ $num > 0 ]
then
    echo "echo 1 > /proc/sys/net/ipv4/ip_forward" | tee -a tinc-up
    echo "echo 0 > /proc/sys/net/ipv4/ip_forward" | tee -a tinc-down
    echo "iptables -t nat -A POSTROUTING -s $local_ipv4_addr -j MASQUERADE" | tee -a tinc-up
    echo "iptables -t nat -D POSTROUTING -s $local_ipv4_addr -j MASQUERADE" | tee -a tinc-down
fi

chmod +x tinc-*

############### host_name ################
cd hosts
touch $host_name
if [ $cs = 1 ]
then
    if [ -n "$ipv4_addr" ]
    then
        echo "Address=$ipv4_addr" | tee -a  $host_name
    fi
    if [ -n "$ipv6_addr" ]
    then
        echo "Address=$ipv6_addr" | tee -a  $host_name
    fi
    echo "Port=$port" | tee -a  $host_name
fi
echo "Subnet=`echo $local_ipv4_addr | awk -F/ '{print $1}'`/32" | tee -a  $host_name
echo "Subnet=`echo $local_ipv6_addr | awk -F/ '{print $1}'`/128" | tee -a  $host_name
for ((i=0;i<$num;i++))
do
    echo "Subnet=${subnet[$i]}" | tee -a  $host_name
done

# tincd -n $net_name -K 4096
tinc -n $net_name generate-rsa-keys 4096

echo "done"
echo "start command: /etc/init.d/tinc start"
echo "stop command: /etc/init.d/tinc stop"
echo "use /etc/init.d/tinc enable to enable individual networks"
