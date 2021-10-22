#!/bin/sh

# Async IT Sàrl - Switzerland - 2021
# Jonas Sauge

# 3CX V18 post installation based on debian 10

wget -O- http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add -
echo "deb http://downloads-global.3cx.com/downloads/debian buster main" | tee /etc/apt/sources.list.d/3cxpbx.list
echo "deb http://downloads-global.3cx.com/downloads/debian buster-testing main" | tee /etc/apt/sources.list.d/3cxpbx-testing.list
apt update -y
username=$(getent passwd "1000" | cut -d: -f1)
echo "$username   ALL=(ALL:ALL) ALL" >> /etc/sudoers
