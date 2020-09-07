#!/bin/sh

# Async IT Sàrl - Switzerland - 2020
# Jonas Sauge

wget -O- http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add -
echo "deb http://downloads-global.3cx.com/downloads/debian stretch main" | tee /etc/apt/sources.list.d/3cxpbx.list
echo "deb http://downloads-global.3cx.com/downloads/debian stretch-testing main" | tee /etc/apt/sources.list.d/3cxpbx-testing.list
apt update -y
apt install -y net-tools dphys-swapfile
username=$(getent passwd "1000" | cut -d: -f1)
echo "$username   ALL=(ALL:ALL) ALL" >> /etc/sudoers
mkdir /etc/iptables
cat > /etc/iptables/rules.v4<<EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -m conntrack --ctstate INVALID -j DROP
-4 -A INPUT -s 127.0.0.0/8 ! -i lo -j DROP
-6 -A INPUT -s ::1/128 ! -i lo -j DROP
-4 -A INPUT -d 224.0.1.75 -j ACCEPT
-4 -A INPUT -m addrtype --dst-type BROADCAST -j DROP
-4 -A INPUT -m addrtype --dst-type MULTICAST -j DROP
-4 -A INPUT -m addrtype --dst-type ANYCAST -j DROP
-4 -A INPUT -d 224.0.0.0/4 -j DROP
-N SSHBRUTE
-A SSHBRUTE -m recent --name SSH --set
-A SSHBRUTE -m recent --name SSH --update --seconds 300 --hitcount 10 -m limit --limit 1/second --limit-burst 100 -j LOG --log-prefix "iptables[SSH-brute]: "
-A SSHBRUTE -m recent --name SSH --update --seconds 300 --hitcount 10 -j DROP
-A SSHBRUTE -j ACCEPT
-N ICMPFLOOD
-A ICMPFLOOD -m recent --set --name ICMP --rsource
-A ICMPFLOOD -m recent --update --seconds 1 --hitcount 6 --name ICMP --rsource --rttl -m limit --limit 1/sec --limit-burst 1 -j LOG --log-prefix "iptables[ICMP-flood]: "
-A ICMPFLOOD -m recent --update --seconds 1 --hitcount 6 --name ICMP --rsource --rttl -j DROP
-A ICMPFLOOD -j ACCEPT
-A INPUT -p tcp -m multiport --dports 80,443,5000,5001,5015,5060,5061,5090 --syn -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p udp -m multiport --dports 69,5060,5090,7000:10999 -j ACCEPT
-A INPUT -p udp -m multiport --dports 137,138 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 139,445 -j ACCEPT
-A INPUT -p tcp --dport 22 --syn -m conntrack --ctstate NEW -j SSHBRUTE
-4 -A INPUT -p icmp --icmp-type 0  -m conntrack --ctstate NEW -j ACCEPT
-4 -A INPUT -p icmp --icmp-type 3  -m conntrack --ctstate NEW -j ACCEPT
-4 -A INPUT -p icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 1   -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 2   -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 3   -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 4   -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 133 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 134 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 135 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 136 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 137 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 141 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 142 -j ACCEPT
-6 -A INPUT -s fe80::/10 -p ipv6-icmp --icmpv6-type 130 -j ACCEPT
-6 -A INPUT -s fe80::/10 -p ipv6-icmp --icmpv6-type 131 -j ACCEPT
-6 -A INPUT -s fe80::/10 -p ipv6-icmp --icmpv6-type 132 -j ACCEPT
-6 -A INPUT -s fe80::/10 -p ipv6-icmp --icmpv6-type 143 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 148 -j ACCEPT
-6 -A INPUT              -p ipv6-icmp --icmpv6-type 149 -j ACCEPT
-6 -A INPUT -s fe80::/10 -p ipv6-icmp --icmpv6-type 151 -j ACCEPT
-6 -A INPUT -s fe80::/10 -p ipv6-icmp --icmpv6-type 152 -j ACCEPT
-6 -A INPUT -s fe80::/10 -p ipv6-icmp --icmpv6-type 153 -j ACCEPT
-4 -A INPUT -p icmp --icmp-type 8  -m conntrack --ctstate NEW -j ICMPFLOOD
-6 -A INPUT -p ipv6-icmp --icmpv6-type 128 -j ICMPFLOOD
-A INPUT -p udp -m multiport --dports 135,445 -j DROP
-A INPUT -p udp --dport 137:139 -j DROP
-A INPUT -p udp --sport 137 --dport 1024:65535 -j DROP
-A INPUT -p tcp -m multiport --dports 135,139,445 -j DROP
-A INPUT -p udp --dport 1900 -j DROP
-A INPUT -p udp --sport 53 -j DROP
-A INPUT -p tcp --dport 113 --syn -m conntrack --ctstate NEW -j REJECT --reject-with tcp-reset
-A INPUT -m limit --limit 1/second --limit-burst 100 -j LOG --log-prefix "iptables[DOS]: "
COMMIT
EOF
cp /etc/iptables/rules.v4 /etc/iptables/rules.v6
