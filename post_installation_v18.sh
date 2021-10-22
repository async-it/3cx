#!/bin/sh

# Async IT Sàrl - Switzerland - 2020
# Jonas Sauge

wget -O- http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add -
echo "deb http://downloads-global.3cx.com/downloads/debian buster main" | tee /etc/apt/sources.list.d/3cxpbx.list
echo "deb http://downloads-global.3cx.com/downloads/debian buster-testing main" | tee /etc/apt/sources.list.d/3cxpbx-testing.list
apt update -y
apt install -y net-tools dphys-swapfile snmpd
username=$(getent passwd "1000" | cut -d: -f1)
echo "$username   ALL=(ALL:ALL) ALL" >> /etc/sudoers
