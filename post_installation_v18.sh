#!/bin/bash

# Async IT Sàrl - Switzerland - 2021
# Jonas Sauge

# 3CX V18 post installation based on debian 10

apt update -y
username=$(getent passwd "1000" | cut -d: -f1)
echo "$username   ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Running 3CX official post-installation script:
wget -O /tmp/3cxpostinstall.sh http://downloads.3cx.com/downloads/debian9iso/post-install_10.4.0.txt
chmod +x /tmp/3cxpostinstall.sh
bash /tmp/3cxpostinstall.sh
