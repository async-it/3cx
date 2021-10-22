#!/bin/bash

# Async IT Sàrl - Switzerland - 2021
# Jonas Sauge

# 3CX V18 post installation based on debian 10

echo "deb http://downloads-global.3cx.com/downloads/debian buster main" | tee /etc/apt/sources.list.d/3cxpbx.list
echo "deb http://downloads-global.3cx.com/downloads/debian buster-testing main" | tee /etc/apt/sources.list.d/3cxpbx-testing.list
echo "deb http://deb.debian.org/debian buster main contrib non-free" > /etc/apt/sources.list
echo "deb http://security.debian.org/ buster/updates main contrib non-free" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian buster-updates main contrib non-free" >> /etc/apt/sources.list

apt update -y
username=$(getent passwd "1000" | cut -d: -f1)
echo "$username   ALL=(ALL:ALL) ALL" >> /etc/sudoers
#!/bin/bash
post=/usr/local/bin/post-install


apt-get update >> /var/tmp/installation_log.txt 2>&1
apt-get -y install gnupg2 >> /var/tmp/installation_log.txt 2>&1

wget -O- http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add -

mkdir /etc/3cxpbx
echo $THREECXMARKER > /etc/3cxpbx/3cxmarkers

# Adding pinning file
pin=/etc/apt/preferences.d/3cxpbx
pin_url=http://downloads-global.3cx.com/downloads/v180/debianupdate/buster.txt
if wget --max-redirect 0 -O /tmp/pinning.tmp $pin_url && grep -q "Pinning d5bedc82fe43e01588812f065662891daf554b4d" /tmp/pinning.tmp; then
	mv -f /tmp/pinning.tmp $pin
	touch /etc/TCXMARKETPLACE_PINNING
	echo \"Pinning file: Pin file downloaded $pin_url\"
else
	echo \"Pinning file: Pin file error\"
	rm -f /tmp/pinning.tmp
fi

cat > /etc/nftables.conf<<EOF
#!/usr/sbin/nft -f
# vim:set ts=4:
# You can find examples in /usr/share/nftables/.

# Clear all prior state
flush ruleset

# Basic IPv4/IPv6 stateful firewall for server/workstation.
table inet filter {
    chain input {
	type filter hook input priority 0; policy drop;

	iifname lo accept comment "Accept any localhost traffic"
	ct state { established, related } accept comment "Accept traffic originated from us"

	ip daddr 224.0.1.75 counter accept comment "Accept SIP Multicast"
	fib daddr type broadcast drop comment "Drop other broadcast"
	fib daddr type multicast drop comment "Drop other multicast"
	fib daddr type anycast drop comment "Drop other anycast"
	ip daddr 224.0.0.0/4 drop comment "Drop DVMRP"

	ct state invalid drop comment "Drop invalid connections"

	tcp dport 113 reject with icmpx type port-unreachable comment "Reject AUTH to make it fail fast"

	# 3CX PhoneSystem specific
	tcp dport { 80,443,5000,5001,5015,5060,5061,5090 } ct state new counter accept comment "Accept 3CX PhoneSystem TCP ports"
                udp dport { 69,5060,5090,7000-10999 } counter accept comment "Accept 3CX PhoneSystem UDP ports"

	# Other services specific
	udp dport { 137,138 } counter accept comment "Accept NetBIOS"
	tcp dport { 139,445 } counter accept comment "Accept TCP/IP MS Networking"

	# SSH Bruteforce blacklist
	tcp dport ssh ct state new limit rate 15/minute accept comment "Avoid brute force on SSH"

	# ICMPv4

	ip protocol icmp icmp type {
	    echo-reply,  # type 0
	    destination-unreachable,  # type 3
	    time-exceeded,  # type 11
	    parameter-problem,  # type 12
	} accept \
	comment "Accept ICMP"

	ip protocol icmp icmp type echo-request limit rate 1/second accept \
	comment "Accept max 1 ping per second"

	# ICMPv6

	ip6 nexthdr icmpv6 icmpv6 type {
	    destination-unreachable,  # type 1
	    packet-too-big,  # type 2
	    time-exceeded,  # type 3
	    parameter-problem,  # type 4
	    echo-reply,  # type 129
	} accept \
	comment "Accept basic IPv6 functionality"

	ip6 nexthdr icmpv6 icmpv6 type echo-request limit rate 1/second accept \
	comment "Accept max 1 ping per second"

	ip6 nexthdr icmpv6 icmpv6 type {
	    nd-router-solicit,  # type 133
	    nd-router-advert,  # type 134
	    nd-neighbor-solicit,  # type 135
	    nd-neighbor-advert,  # type 136
	} ip6 hoplimit 255 accept \
	comment "Allow IPv6 SLAAC"

	ip6 nexthdr icmpv6 icmpv6 type {
	    mld-listener-query,  # type 130
	    mld-listener-report,  # type 131
	    mld-listener-reduction,  # type 132
	    mld2-listener-report,  # type 143
	} ip6 saddr fe80::/10 accept \
	comment "Allow IPv6 multicast listener discovery on link-local"
    }

    chain forward {
	type filter hook forward priority 0; policy drop;
    }

    chain output {
	type filter hook output priority 0; policy accept;
    }
}
EOF
cat > $post  <<'EOG'
#!/bin/bash

function generate_language_files()
{

cat <<EOF | base64 -d >/tmp/tcxisowizard_i18n.tar.gz
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
EOF

tar -xzf /tmp/tcxisowizard_i18n.tar.gz -C /usr/share/ 2> /dev/null > /dev/null

}

# Define text domain
export TEXTDOMAIN=tcxisowizard
# Generate language files
generate_language_files

clear
# echo "deb http://downloads-global.3cx.com/downloads/debian buster main" > /etc/apt/sources.list.d/3cxpbx.list;
echo "deb http://downloads-global.3cx.com/downloads/debian buster main" > /etc/apt/sources.list.d/3cxpbx.list;
echo "deb http://downloads-global.3cx.com/downloads/debian buster-testing main" > /etc/apt/sources.list.d/3cxpbx-testing.list;

clear
echo "10" | whiptail --title $" 3CX Installation " --gauge $"Waiting for network" 7 78 0; sleep 1
WAITING=0
while ! wget http://downloads-global.3cx.com/ --spider --tries 3 --timeout 10 --dns-timeout 10 --connect-timeout 10 --read-timeout 10 -O - 1>/dev/null 2>/dev/null; do
    sleep 1
    WAITING=$((${WAITING} + 1))
    if [ $WAITING -gt 10 ]; then
      whiptail --title $" 3CX Installation " --msgbox $"Could not connect to 3CX server. Please check your internet connection and try again." 8 78
    fi;
done
echo "20" | whiptail --title $" 3CX Installation " --gauge $"Update package lists" 7 78 0; sleep 1
apt-get update >> /var/tmp/installation_log.txt 2>&1
echo "30" | whiptail --title $" 3CX Installation " --gauge $"Install new certificates" 7 78 0; sleep 1
/usr/bin/debconf-apt-progress -- apt-get -y install ca-certificates mc htop openssh-server net-tools
/usr/bin/debconf-apt-progress -- apt-get -o Dpkg::Options::="--force-confold" --force-yes -y install nftables
apt-get update >> /var/tmp/installation_log.txt 2>&1
echo "50" | whiptail --title $" 3CX Installation " --gauge $"Install latest linux kernel" 7 78 0; sleep 1
/usr/bin/debconf-apt-progress -- apt-get -y install linux-image-amd64
echo "60" | whiptail --title $" 3CX Installation " --gauge $"Install 3CX package" 7 78 0; sleep 1

SBC_TESTING_VERSION=`env -u LANGUAGE LC_ALL=C apt-cache policy 3cxsbc | grep Candidate | egrep -o "[0-9]+.[0-9]+.[0-9.]*"`
TESTING_VERSION=`env -u LANGUAGE LC_ALL=C apt-cache -t testing policy 3cxpbx | grep Candidate | egrep -o "[0-9]+.[0-9]+.[0-9.]*"`

# rm -f /etc/apt/sources.list.d/3cxpbx-testing.list;
# apt-get update >> /var/tmp/installation_log.txt 2>&1

SBC_STABLE_VERSION=`env -u LANGUAGE LC_ALL=C apt-cache policy 3cxsbc | grep Candidate | egrep -o "[0-9]+.[0-9]+.[0-9.]*"`
SBC_NEWEST_VERSION=`echo -e "$SBC_STABLE_VERSION\n$SBC_TESTING_VERSION" | sort --version-sort -r | head -1`
STABLE_VERSION=`env -u LANGUAGE LC_ALL=C apt-cache policy 3cxpbx | grep Candidate | egrep -o "[0-9]+.[0-9]+.[0-9.]*"`
NEWEST_VERSION=`echo -e "$STABLE_VERSION\n$TESTING_VERSION" | sort --version-sort -r | head -1`

#echo "deb http://downloads-global.3cx.com/downloads/debian buster-testing main" > /etc/apt/sources.list.d/3cxpbx-testing.list;
#apt-get update >> /var/tmp/installation_log.txt 2>&1

X=-1
unset MENU_ITEM
if [ "$NEWEST_VERSION" = "$TESTING_VERSION" ] && [ "$STABLE_VERSION" != "$TESTING_VERSION" ]; then
	if [ "x$STABLE_VERSION" != "x" ]; then
		MENU_ITEM[$((X=X+1))]="3CX Version"
		MENU_ITEM[$((X=X+1))]=" $STABLE_VERSION"
	fi
#	MENU_ITEM[$((X=X+1))]="3CX Beta"
#	MENU_ITEM[$((X=X+1))]=" $TESTING_VERSION "$"(For evaluation - No Support)"
else
	MENU_ITEM[$((X=X+1))]="3CX Version"
	MENU_ITEM[$((X=X+1))]=" $STABLE_VERSION"
fi

if [ "$SBC_NEWEST_VERSION" = "$SBC_TESTING_VERSION" ] && [ "$SBC_STABLE_VERSION" != "$SBC_TESTING_VERSION" ]; then
	if [ "x$SBC_STABLE_VERSION" != "x" ]; then
		MENU_ITEM[$((X=X+1))]="3CX SBC Version"
		MENU_ITEM[$((X=X+1))]=" $SBC_STABLE_VERSION"
	fi
#	MENU_ITEM[$((X=X+1))]="3CX SBC Beta"
#	MENU_ITEM[$((X=X+1))]=" $SBC_TESTING_VERSION "$"(For evaluation - No Support)"
else
	MENU_ITEM[$((X=X+1))]="3CX SBC Version"
	MENU_ITEM[$((X=X+1))]=" $SBC_STABLE_VERSION"
fi

/usr/bin/whiptail --title $"3CX Select What to Install" --menu $"Please choose your package for this installation:" 11 78 5 "${MENU_ITEM[@]}" 2> /tmp/results

CHANNEL_RESULT=`cat /tmp/results`

case "${CHANNEL_RESULT}" in
"3CX Version") echo "40" | whiptail --title $" 3CX Installation " --gauge $"Prepare nftables" 7 78 0; sleep 1
yes | /bin/systemctl enable nftables.service >> /var/tmp/installation_log.txt 2>&1
echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y install 3cxpbx
/bin/ln -s /etc/systemd/system/3CXFirstInstallation.service /etc/systemd/system/multi-user.target.wants/3CXFirstInstallation.service
;;
"3CX Beta") echo "40" | whiptail --title $" 3CX Installation " --gauge $"Prepare nftables" 7 78 0; sleep 1
yes | /bin/systemctl enable nftables.service >> /var/tmp/installation_log.txt 2>&1
echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y -t testing install 3cxpbx
/bin/ln -s /etc/systemd/system/3CXFirstInstallation.service /etc/systemd/system/multi-user.target.wants/3CXFirstInstallation.service
;;
"3CX SBC Version") rm -f /etc/nftables.conf 2> /dev/null > /dev/null
rm -f /etc/nftables.conf 2> /dev/null > /dev/null


MAIN_VERSION="${SBC_STABLE_VERSION:0:2}"
if [ "$MAIN_VERSION" = "15" ]; then
	echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y install curl
	echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y install 3cxsbc
	/bin/systemctl stop 3cxsbc
	/usr/bin/3CXSBCInstallation_15.sh;
else
  echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y install 3cxsbc
	/bin/systemctl stop 3cxsbc
	/usr/bin/3CXSBCInstallation.sh;
fi
;;
"3CX SBC Beta") rm -f /etc/nftables.conf 2> /dev/null > /dev/null
rm -f /etc/nftables.conf 2> /dev/null > /dev/null

MAIN_VERSION="${SBC_TESTING_VERSION:0:2}"
if [ "$MAIN_VERSION" = "15" ]; then
  echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y -t testing install curl
	echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y -t testing install 3cxsbc
	/bin/systemctl stop 3cxsbc
	/usr/bin/3CXSBCInstallation_15.sh;
else
	echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y -t testing install 3cxsbc
	/bin/systemctl stop 3cxsbc
	/usr/bin/3CXSBCInstallation.sh;
fi
;;
*)
  echo "1" | /usr/bin/debconf-apt-progress -- apt-get -y install 3cxpbx
;;
esac

echo "80" | whiptail --title $" 3CX Installation " --gauge $"Activate root login" 7 78 0; sleep 1
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config >> /var/tmp/installation_log.txt 2>&1
service ssh restart >> /var/tmp/installation_log.txt 2>&1
echo "100" | whiptail --title $" 3CX Installation " --gauge $"Prepare for reboot" 7 78 0; sleep 1
rm /usr/local/bin/post-install >> /var/tmp/installation_log.txt 2>&1
/sbin/reboot >> /var/tmp/installation_log.txt 2>&1
EOG

cat > /usr/bin/3CXSBCInstallation_15.sh<<'EOL'
#!/bin/bash
FQDN=$(whiptail --title $"3CX SBC" --inputbox  $"Enter your 3CX Phone System FQDN
TIP: Get FQDN from
3CX Management console > Settings > Network > FQDN Tab" --backtitle $"3CX Session Border Controller Setup" 12 62  3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 1 ]; then
	exit 1
    echo "EXIT"
fi
FQDNnat=$FQDN
FQDN="TunnelAddr =$FQDN"
sed -i "s/TunnelAddr =/$FQDN/g" /etc/3cxsbc.conf

Localip=$(whiptail --title $"3CX SBC" --inputbox $"Enter the IP Address of your 3CXPhone System server

TIP:	If 3CX is behind NAT, enter the local IP of 3CX PBX
			If 3CX is NOT behind NAT,enter the public IP" --backtitle $"3CX Session Border Controller Setup" 12 62  3>&1 1>&2 2>&3)
	 exitstatus=$?
if [ $exitstatus = 1 ]; then
	exit 1
    echo "EXIT"
fi

Pbxport=$(whiptail --title $"3CX SBC" --inputbox $"Enter 3CX Phone System SIP Port ex.5060
TIP:	Get SIP Port from
			3CX Management console > Settings > Network >
Ports > SIP Port" --backtitle $"3CX Session Border Controller Setup" 12 62 5060  3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 1 ]; then
	exit 1
    echo "EXIT"
fi
	Pbxport="PbxSipPort =$Pbxport"
sed -i "s/PbxSipPort = 5060/$Pbxport/g" /etc/3cxsbc.conf

Tunnelport=$(whiptail --title $"3CX SBC" --inputbox $"Enter 3CX Tunnel Port ex.5090
TIP:	Get 3CX Tunnel port from
			3CX Management console > Settings > Network >
			Ports > Tunnel Port" --backtitle $"3CX Session Border Controller Setup" 12 62 5090  3>&1 1>&2 2>&3)
	exitstatus=$?
if [ $exitstatus = 1 ]; then
	exit 1
    echo "EXIT"
fi
TunnelPortf=$Tunnelport
Tunnelport="TunnelPort = $Tunnelport"
sed -i "s/TunnelPort = 5090/$Tunnelport/g" /etc/3cxsbc.conf

Tunnelpass=$(whiptail --title "$3CX SBC" --inputbox $"Enter Tunnel Password

TIP:	Get 3CX Tunnel Password from
			3CX Management console > Settings > Security >
			3CX Tunnel tab > Tunnel Password" --backtitle $"3CX Session Border Controller Setup" 12 62  3>&1 1>&2 2>&3)
   exitstatus=$?
if [ $exitstatus = 1 ]; then
	exit 1
    echo "EXIT"
fi
sed -i 's/entertunnelpass/'$Tunnelpass'/g' /etc/3cxsbc.conf

fchoice=$(whiptail --title $"3CX SBC" --menu --nocancel $"Do you want to configure Failover? If main Server go down 3CXSBC can automatically connect to a secondary standby 3CX Server" --backtitle $"3CX Session Border Controller Setup" 13 62 2 \
        1 $"Enable Failover" \
		2 $"No Failover" 3>&2 2>&1 1>&3)
if [ $fchoice -eq 1 ]
then
Tunnelf=$(whiptail --title $"3CX SBC" --inputbox $"Enter the Public IP Address of your 3CXPhone System Failover server

TIP:	Use the Public IP of the Failover Server
			and NOT the FQDN" --backtitle $"3CX Session Border Controller Setup" 12 62  3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 1 ]; then
	exit 1
    echo "EXIT"
fi
Tunnelf="TunnelAddr2 = $Tunnelf"
sed -i "s/#TunnelAddr2 =/$Tunnelf/g" /etc/3cxsbc.conf

TunnelPortf="TunnelPort2 = $TunnelPortf"
sed -i "s/#TunnelPort2 =/$TunnelPortf/g" /etc/3cxsbc.conf
Localip=$FQDNnat
fchoice=TRUE
fi

if [ $fchoice = 2 ]; then
	fchoice=FALSE
fi
Localipnat=$Localip
Localip="PbxSipIP =$Localip"
sed -i "s/PbxSipIP =/$Localip/g" /etc/3cxsbc.conf

schoice=$(whiptail --title $"3CX SBC" --menu --nocancel $"Secures tunnel traffic
Note:Requires V15" --backtitle $"3CX Session Border Controller Setup" 12 62 2 \
        1 $"Enable Encryption" \
        2 $"Disable Encryption" 3>&2 2>&1 1>&3)
if [ $schoice -eq 1 ]
then
schoice=1
else
schoice=0
sed -i "s/SecurityMode = 1/SecurityMode = 0/g" /etc/3cxsbc.conf
fi

versbc="$(dpkg -s 3cxsbc | grep 'Version')"
versbc=${versbc:8}
natali="True"
methprov="MANUALLY"
if [ "$Localipnat" = "$FQDNnat" ]
then
natali="True"
else
natali="False"
fi
red=`tput setaf 1`
green=`tput setaf 2`
echo ${red}"    "$"Restarting 3cxsbc Service"$(tput sgr 0)
systemctl start 3cxsbc

whiptail --title $"3CX SBC" --msgbox $"3CXSBC is up and running. You can now restart your IP Phones and access the 3CX Management Console > Phones
to provision your IP Phones." --backtitle $"3CX Session Border Controller Setup" 12 62
echo ${green}"    "$"INFO: To access the 3CXSBC configuration file type the following command sudo nano /etc/3cxsbc.conf "$(tput sgr 0)
echo ${green}"    "$"INFO: To enable logs go to nano /etc/3cxsbc.conf and set [Log] level to DEBUG "$(tput sgr 0)
echo ${green}"    "$"INFO: To open log file type this command tail -f /var/log/3cxsbc.log "$(tput sgr 0)
echo ${green}"    "$"3CXSBC is up and running. You can now restart your IP Phones and access the 3CX Management Console > Phones node to provision your IP Phones.  "$(tput sgr 0)
rm 3cxsbc.*

EOL
chmod +x /usr/bin/3CXSBCInstallation_15.sh

cat > /usr/bin/3CXSBCInstallation.sh<<'EOL'
#!/bin/bash
# Auto Install Script for SBC Linux
function main()
{
	[ $(id -u) -eq 0 ] || fail "You have to be the root to run the installation"

	[ -z "$(which wget)" ] && fail "wget is missing"

	notify_prerequisites

	checkos
	checkpkg 3cxpbx && fail "3CX PBX detected" "it's not possible to install both the PBX and SBC on a machine at the same time"

	while ! ask_license
	do
		ask_cancel && cancel
	done

	cfg=/etc/3cxsbc.conf
	cfgnew=$(mktemp)

	[ -f $cfg ] && parse_config $cfg

	while true
	do
		while true
		do
			prompt_url
			res=$?

			[ $res -eq 3 ] && ask_cancel && cancel
			[ $res -eq 2 ] && notify_invalid url "$pbx_url" || [ $res -eq 0 ] && break
			[ $res -eq 1 ] && notify_insecure
		done

		while ! prompt_key
		do
			ask_cancel && cancel
		done

		cfg_url=$pbx_url/sbc/$pbx_key

		echo "connecting $pbx_url"
		wget -T 10 -t 1 -qO $cfgnew $cfg_url && break

		case $? in
		4|5)
			err="Unable to reach the 3CX Server at $pbx_url\nPlease double check \"3CX PBX Provisioning URL\" value and confirm that the SBC Trunk is created properly from within your 3CX Management Console.\n\nAlso 3CX must have a valid secure SSL Certificate so if you have a custom certificate which has expired or not renewed, the installation will fail."
			;;
		8)
			err="The PBX does not accept the SBC AUTHENTICATION KEY ID\n$pbx_key"
			;;
		*)
			err="Unknown error"
		esac

		warn "Cannot obtain provisional data" "$err"
		ask_retry "$err" || cancel
	done

	sed -i"" -E 's/\r//' $cfgnew

	verify_config $cfgnew && parse_config $cfgnew || fail "The provisioning file has successfully been downloaded but is corrupted" "check $cfgnew"

	[ -f $cfg ] && { chown --reference=$cfg $cfgnew; chmod --reference=$cfg $cfgnew; }

	user=$(systemctl show -p User --value 3cxsbc)
	[ -n "$user" ] || user=nobody

	group=$(id -gn $user)
	[ -n "$group" ] || group=nogroup

	[ -f $cfg ] && chown $user $cfgnew || chown $user:$group $cfgnew
	chmod "u+rw" $cfgnew

	mv -f $cfgnew $cfg || fail "Cannot update the configuration file $cfg"

	systemctl restart 3cxsbc

	echo "INFO: To access the 3CXSBC configuration file type 'sudo nano /etc/3cxsbc.conf'"
	echo "INFO: To enable logs go to 'nano /etc/3cxsbc.conf.local' and set [Log] level to DEBUG"
	echo "INFO: Then restart SBC: systemctl restart 3cxsbc"
	echo "INFO: To open the log file type 'tail -f /var/log/3cxsbc/3cxsbc.log'"

	systemctl is-active --quiet 3cxsbc || { tail /var/log/3cxsbc/3cxsbc.log; fail "3CXSBC has failed to start"; }

	echo "${tgreen}3CXSBC is up and running. You can now restart your IP Phones and access the 3CX Management Console > Phones node to provision your IP Phones.$tdef"

	notify_finish
}

tred=$(tput setaf 1)
tgreen=$(tput setaf 2)
tyellow=$(tput setaf 3)
tdef=$(tput sgr0)

declare -A ptrn
ptrn[num]=0-9
ptrn[hex]=0-9A-Fa-f
ptrn[alnum]=a-zA-Z0-9
ptrn[authority]="((([${ptrn[alnum]}-]+\.)*[${ptrn[alnum]}-]+)|[${ptrn[hex]}:]+)"
ptrn[url]="(((https?):\/\/)([^:/ ]+|(\[[^]]+\]))(:([0-9]+))?)([?/][${ptrn[alnum]}/%&=._-]*)?"

function fail()
{
	echo -e "${tred}error: $1$tdef" >&2
	shift
	for msg in "$@"
	do
		echo -e "       $tred$msg$tdef" >&2
	done
	exit 1
}

function warn()
{
	echo -e "${tyellow}warning: $1$tdef" >&2
	shift
	for msg in "$@"
	do
		echo -e "         $tyellow$msg$tdef" >&2
	done
}

function cancel()
{
	echo "${tred}Installation aborted${tdef}"
	exit 1
}

function match_ptrn()
{
	local pattern=${ptrn[$2]}
	[ -n "$3" ] && sed -nE "s/^${pattern}$/\\$3/p" <<< "$1" || grep -qE "^$pattern$" <<< "$1"
}

function match_url()
{
	local str=$1
	local piece=$2

	local flt_auth="s/^\[(.*)\]$/\1/"

	declare -A pieces
	pieces=( [base]=1 [scheme]=3 [authority]=4 [port]=7 [path]=8 )

	if [ -z "$piece" ]
	then
		 match_ptrn "$str" url || return $?

		 local authority=$(match_ptrn "$str" url ${pieces[authority]} | sed -E "$flt_auth")
		 match_ptrn "$authority" authority
		 return $?
	fi

	local i=${pieces[$piece]}
	[ -z "$i" ] && return 1

	local value=$(echo -n "$str" | sed -nE "s/^${ptrn[url]}$/\\$i/p")
	[ $piece == authority ] && sed -E "$flt_auth" <<< $value || echo $value
	return 0
}

function parse_url()
{
	pbx_scheme=$(match_url "$1" scheme)
	pbx_fqdn=$(match_url "$1" authority)
	pbx_port=$(match_url "$1" port)

	pbx_url=$(match_url "$1" base)

	local path=$(match_url "$1" path)

	local key=$(echo -n $path | sed -nE "s/^\/sbc\/([${ptrn[alnum]}]+)$/\1/p")
	[ -n "$key" ] && pbx_key="$key"
}

backtitle="3CX Session Border Controller Setup"
width=62
height=12

function checkpkg()
{
	dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -qF "ok installed"
}

function checkos()
{
	local path=/etc/os-release

	[ -z "$(which dpkg-query)" ] && fail "Cannot find the package manager (is it a Debian?)"
	checkpkg systemd && [ -f $path ]|| fail "Cannot find systemd (is it a Debian?)"

	os_name=$(sed -nE "s/^\s*ID\"?=(.*)\"?$/\1/p" $path)
	os_parent_name=$(sed -nE "s/^\s*ID_LIKE\"?=(.*)\"?$/\1/p" $path)
	os_version=$(sed -nE "s/^\s*VERSION_ID=\"?([0-9]+)\"?$/\1/p" $path)
	os_code=$(sed -nE "s/^\s*VERSION=\"?$os_version\s*\((.*)\)\"?$/\1/p" $path)

	[ "$os_name" == debian ] || echo "$os_parent_name" | grep -q debian || fail "Unsupported distribution $os_name"
	[ $os_version -ge 9 ] || [ "$os_code" == "buster" ] || fail "Unsupported Debian version $os_code"
}

function notify_prerequisites()
{
	local title="3CX Pre-requisites"
	local text="1. Port 5060 (TCP and UDP) on this computer must be free\n2. Works with 3CX PBX V16\n3. Update 3CX PBX before you install SBC"

	whiptail --backtitle "$backtitle" --title "$title" --msgbox "$text" $height $width
}

function ask_license()
{
	local width=$(tput cols)
	let "width = width * 9 / 10"
	[ $width -gt 120 ] && width=120

	local height=$(tput lines)
	let "height = height * 9 / 10"

	local title="End-User License Agreement"
	local text="$(license)"
	whiptail --backtitle "$backtitle" --title "$title" --yes-button Accept --no-button Decline --scrolltext --yesno "$text"	$height $width
}

function prompt_text()
{
	local var=$1
	local text=$2
	shift 2

	eval "local tmp=\$$var"
	{ tmp=$(whiptail --backtitle "$backtitle" "$@" --inputbox "$text" $height $width "$tmp" 2>&1 1>&3); } 3>&1 && eval "$var='$tmp'"
}

function prompt_url()
{
	local title="3CX Provisioning URL"
	local text="SBC Client for Linux requires the full Provisioning URL of your PBX including the leading \"https://\" protocol and port number at the end.\nExamples: https://mycompany.3cx.com or https://mycompany.3cx.com:5001"

	prompt_text pbx_url "$text" --title "$title" && [ -n "$pbx_url" ] || return 3
	match_url "$pbx_url" || return 2

	parse_url "$pbx_url"
        [ "$pbx_scheme" == "http" ] && return 1

	return 0
}

function notify_invalid()
{
	local text="'$2' doesn't seem to be a valid $1.\nDo you want to continue?"
	whiptail --backtitle "$backtitle" --yes-button "Continue" --no-button "Back" --yesno "$text" --defaultno $height $width
}

function notify_insecure()
{
	local text="Insecure HTTP mode is not supported. Please, provide an HTTPS URL."
	whiptail --backtitle "$backtitle" --ok-button "Back" --msgbox "$text" $height $width
}

function prompt_key()
{
	local title="SBC AUTHENTICATION KEY ID"
	local text="Access the 3CX Management Console > SIP Trunks > Add SBC. An Authentication KEY ID will be generated. Copy this key in the space below."

	prompt_text pbx_key "$text" --title "$title"
}

function ask_cancel()
{
	local text="Are you sure to abort the installation?"
	whiptail --backtitle "$backtitle" --yesno "$text" --yes-button Abort --no-button Continue --defaultno $height $width
}

function ask_retry()
{
	local letters=$(wc -m <<< $1)
	local lines=$(grep -o '\\n' <<< $1 | wc -l)
	local height=$((letters * 11 / 10 / $width + $lines + 7))

	local title="Cannot obtain provisional data"
	whiptail --backtitle "$backtitle" --title "$title" --yes-button Retry --no-button Abort --yesno "$1" $height $width
}

function notify_finish()
{
	local text="3CXSBC is up and running.\nYou can now restart your IP Phones and access the 3CX Management Console > Phones to provision your IP Phones."
	whiptail --backtitle "$backtitle" --msgbox "$text" $height $width
}

function verify_config()
{
	cat "$1" | grep -qF "End of 3CX SBC config file"
}

function access_config()
{
	local path=$1
	local section=$2
	local key=$3
	local value=$4

	declare -A ptrn
	ptrn[eol]="\s*(\s#.*)?$"
	ptrn[section]="^\s*\[[^]]+\]${ptrn[eol]}"
	ptrn[target]="^\s*\[$(echo -n $section | sed -E 's/\//\\\//')\]${ptrn[eol]}"

	if [ -n "$key" ] && [ -n "$value" ]
	then
		if sed -nE "/${ptrn[target]}/,/${ptrn[section]}/p" $path | grep -q "^\s*$key\s*="
		then
			sed -i"" -E "/${ptrn[target]}/,/${ptrn[section]}/{/^\s*$key\s*=/c\
$key=$value
}" $path
		else
			sed -i"" -E "/${ptrn[target]}/a$key=$value" $path
		fi
	else
		if [ -z "$key" ]
		then
			grep -E "${ptrn[target]}" $path | sed -E "s/^.*\[(.*)\].*$/\1/"
		else
			sed -nE "/${ptrn[target]}/,/^\s*\[[^]]+\]\s*$/p" $path | sed -nE "1d;\$d;/^${ptrn[eol]}/d;s/\s*#.*//;p" | sed -nE "/^\s*$key\s*=/s/^.*=\s*([^[:space:]]+).*/\1/p"
		fi
	fi
}

function parse_config()
{
	local path=$1

	cfg_section="$(access_config $path "Bridge/.*")"
	[ -n "$cfg_section" ] || return 1

	tunnel_addr=$(access_config "$path" "$cfg_section" TunnelAddr)
	tunnel_port=$(access_config "$path" "$cfg_section" TunnelPort)

	local url=$(access_config $path "$cfg_section" ProvLink)
	if [ -n "$url" ] && match_url "$url"
	then
		parse_url "$url"
	else
		[ -n "$tunnel_addr" ] && pbx_url=https://$tunnel_addr:5001
	fi

	[ -n "$tunnel_addr" ] && [ -n "$tunnel_port" ] && true || false
}

function license()
{
	cat <<EOF
NO EMERGENCY COMMUNICATIONS

LICENSEE (AS DEFINED BELOW) ACKNOWLEDGES THAT THE SOFTWARE (AS DEFINED BELOW) IS NOT DESIGNED OR INTENDED FOR USE TO CONTACT, OR COMMUNICATE WITH, ANY POLICE AGENCY, FIRE DEPARTMENT, AMBULANCE SERVICE, HOSPITAL OR ANY OTHER EMERGENCY SERVICE OF ANY KIND.  THE SOFTWARE DOES NOT SUPPORT CALLS TO "911," POISON CONTROL CENTERS OR TO ANY OTHER EMERGENCY NUMBER AVAILABLE IN YOUR COMMUNITY.  3CX DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTY OF FITNESS FOR SUCH USES.

LICENSE AGREEMENT

3CX Phone System Software

3CX Software, Ltd. ("3CX") is willing to license, either directly or through  its  resellers, the 3CX Phone System Software defined below, related documentation, and any other material or information relating to such software provided by 3CX to you (personally and/or on behalf of your employer, as applicable) ("Licensee") ONLY IF YOU ACCEPT ALL OF THE TERMS IN THIS LICENSE AGREEMENT ("License").

BEFORE YOU CHOOSE THE "AGREE" BUTTON AT THE BOTTOM OF THIS WINDOW, CAREFULLY READ THE TERMS AND CONDITIONS OF THIS LICENSE.  BY CHOOSING THE "AGREE" BUTTON YOU ARE (1) REPRESENTING THAT YOU ARE OVER THE AGE OF 18 AND HAVE THE CAPACITY AND AUTHORITY TO BIND YOURSELF AND YOUR EMPLOYER, AS APPLICABLE, TO THE TERMS OF THIS LICENSE AND (2) CONSENTING ON BEHALF OF YOURSELF AND/OR AS AN AUTHORIZED REPRESENTATIVE OF YOUR EMPLOYER, AS APPLICABLE, TO BE BOUND BY THIS LICENSE.  IF YOU DO NOT AGREE TO ALL OF THE TERMS AND CONDITIONS OF THIS LICENSE, OR DO NOT REPRESENT THE FOREGOING, CHOOSE THE "DECLINE" BUTTON, IN WHICH CASE YOU WILL NOT AND MAY NOT RECEIVE, INSTALL OR USE THE 3CX PHONE SYSTEM SOFTWARE.  ANY USE OF THE 3CX PHONE SYSTEM SOFTWARE OTHER THAN PURSUANT TO THE TERMS OF THIS LICENSE IS A VIOLATION OF U.S. AND INTERNATIONAL COPYRIGHT LAWS AND CONVENTIONS.


1.  DEFINITIONS

"Software" - 3CX's 3CX Phone System Software and any and all other 3CX applications and tools and related documentation that 3CX may provide to Licensee, directly or through one or more levels of resellers, in conjunction with the 3CX Phone System Software.

2.  GRANT OF LICENSE

Subject to the terms and conditions of this License, 3CX hereby grants to Licensee a limited, personal, nonexclusive, non-sub-licensable, non-transferable license to install on magnetic or optical media and use ONE (1) copy of the Software.
The license granted to Licensee is expressly made subject to the following limitations:  Licensee may not itself (and shall not permit any third party to): (i) copy, other than as expressly permitted, all or any portion of the Software, except that Licensee may make one copy of the Software for archival purposes for use by Licensee only in the event the Software shall become inoperative; (ii) modify or translate the Software; (iii) modify, alter, or use the software so as to enable more extensions than are authorized in the relevant software purchase agreement; (iv) reverse engineer, decompile or disassemble the Software, in whole or in part, (v) use the Software to directly or indirectly provide a time-sharing or subscription service to any third party or to function as a service bureau or application service provider; (vi) create derivative works based on the Software, except in accordance with clause (ii) of this paragraph; (vii) publicly display the Software; (viii) rent, lease, sublicense, sell, market, distribute, assign, transfer, or otherwise permit access to the Software to any third party; (ix) install and use the Software unless Licensee has installed on such magnetic or optical medium a valid, licensed copy of an operating system compatible with said Software,(x) disregard the simultaneous number of calls limit applicable to the particular version of 3CX Phone System; or (xi) exercise any right to the Software not expressly granted in this License.
The Software includes software applications and tools licensed to 3CX by third parties, including without limitation: ReSIProcate, which is licensed and copyrighted by SIPFoundry, Inc. and its licensors; PostgreSQL Database
Management System, which is licensed and copyrighted by The PostgreSQL Global Development Group and The Regents of the University of California.  This third-party software included in the Software is provided AS IS AND WITH ALL FAULTS.

3.  OWNERSHIP OF SOFTWARE

This License does not convey to Licensee an interest in or to the Software, but only a limited right of use revocable in accordance with the terms of this License.  The Software is NOT being sold to Licensee.  3CX and its licensors own all rights, title and interest in and to the Software.  No license or other right in or to the Software is being granted to Licensee except for the rights specifically set forth in this License.  Licensee hereby agrees to abide by all applicable laws and international treaties.

4.  ENTIRE AGREEMENT

The third party software applications and tools included in the Software are governed by the terms and conditions of this License. 3CX, in its sole discretion, may provide additional third party software to Licensee at any time.  The installation and use of any third party software provided to Licensee by 3CX that is not specifically included in the Software, whether provided on the same media as the Software or separately, is governed by its own license agreement that will be provided to Licensee and which is between the respective third party and Licensee  This License, policies, terms and conditions incorporated by reference represent the entire agreement between 3CX and Licensee.

5.  UPDATES AND SUPPORT

3CX may modify the Software at any time, for any reason, and without providing notice of such modification to Licensee.  This License will apply to any such modifications which are rightfully obtained by Licensee unless expressly stated otherwise.  This License does not grant Licensee any right to any maintenance or services, including without limitation, any support, enhancement, modification, bug fix or update to the Software and 3CX is under no obligation to provide or inform Licensee of any such updates, modifications, maintenance or services

6.  CONFIDENTIALITY

Licensee acknowledges that the information about  the Software and certain other materials are confidential as provided herein.  3CX's and its licensors' proprietary and confidential information includes any and all information related to the services and/or business of 3CX or its licensors that is treated as confidential or secret by 3CX or its licensors (that is, it is the subject of efforts by 3CX, or its licensors, as applicable, that are reasonable under the circumstances to maintain its secrecy), including, without limitation, (i) information about  the Software; (ii) any and all other information which is disclosed by 3CX to Licensee orally, electronically, visually, or in a document or other tangible form which is either identified as or should be reasonably understood to be confidential and/or proprietary; and, (iii) any notes, extracts, analysis, or materials prepared by Licensee which are copies of or derivative works of 3CX's or its licensors' proprietary or confidential information from which the substance of Confidential Information can be inferred or otherwise understood (the "Confidential Information").
Confidential Information shall not include information which Licensee can clearly establish by written evidence: (a) is already lawfully known to or independently developed by Licensee without access to the Confidential Information, (b) is disclosed in non-confidential published materials, (c) is generally known to the public, or (d) is rightfully obtained from any third party without any obligation of confidentiality.
Licensee agrees not to disclose Confidential Information to any third party and will protect and treat all Confidential Information with the highest degree of care.  Except as otherwise expressly provided in this License, Licensee will not use or make any copies of Confidential Information, in whole or in part, without the prior written authorization of 3CX.  Licensee may disclose Confidential Information if required by statute, regulation, or order of a court of competent jurisdiction, provided that Licensee provides 3CX with prior notice, discloses only the minimum Confidential Information required to be disclosed, and cooperates with 3CX in taking appropriate protective measures.  These obligations shall continue for two years following any termination of this License with respect to Confidential Information.

7.  NO WARRANTY AND DISCLAIMER OF LIABILITY

THE SOFTWARE IS WARRANTED TO SUBSTANTIALLY CONFORM TO ITS WRITTEN DOCUMENTATION. AS SOLE AND EXCLUSIVE REMEDY IN THE EVENT OF A BREACH OF THIS WARRANTY, 3CX OR ITS LICENSORS WILL,  REPLACE THE SOFTWARE WITH CONFORMING SOFTWARE, 3CX AND ITS LICENSORS DO NOT MAKE ANY, AND HEREBY SPECIFICALLY DISCLAIM ANY, OTHER REPRESENTATIONS, ENDORSEMENTS, GUARANTIES, OR WARRANTIES, EXPRESS OR IMPLIED, RELATED TO THE SOFTWARE INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTY OF MERCHANTABILITY, , FITNESS FOR A PARTICULAR PURPOSE  3CX does not warrant that use of the Software, or Licensee's ability to use the Software will be uninterrupted, virus free or error free.  Licensee acknowledges that 3CX does not guarantee compatibility between the Software and any future versions thereof.  Licensee acknowledges that 3CX does not and cannot guarantee that Licensee's computer environment will be free from unauthorized intrusion or otherwise guarantee the privacy of Licensee's information.  Licensee will have sole responsibility for the adequate protection and backup of Licensee's data and/or equipment used with the Software.
LICENSEE'S SOLE EXCLUSIVE REMEDY FOR ANY CLAIM ARISING UNDER THIS LICENSE OR FROM USE OF THE SOFTWARE IS THAT 3CX WILL USE COMMERCIALLY REASONABLE EFFORTS TO PROVIDE LICENSEE WITH A REPLACEMENT FOR ANY DEFECTIVE SOFTWARE OR MEDIA.  3CX AND ITS PARENTS, SUBSIDIARIES, AFFILIATES, SHAREHOLDERS, DIRECTORS, OFFICERS, EMPLOYEES, LICENSORS AND AGENTS (THE "3CX PARTIES") SHALL NOT BE LIABLE UNDER ANY LEGAL THEORY FOR ANY DAMAGES SUFFERED IN CONNECTION WITH THE USE OF THE SOFTWARE, INCLUDING WITHOUT LIMITATION, INDIRECT, SPECIAL, INCIDENTAL, MULTIPLE, CONSEQUENTIAL, PUNITIVE OR EXEMPLARY DAMAGES, INCLUDING, BUT NOT LIMITED TO, LOSS OF PROFITS, DATA OR USE ("EXCLUDED DAMAGES"), EVEN IF ANY PARTY WAS ADVISED OF THE POSSIBILITY OF ANY EXCLUDED DAMAGES OR ANY EXCLUDED DAMAGES WERE FORESEEABLE.  IN THE EVENT OF A FAILURE OF THE ESSENTIAL PURPOSE OF THE EXCLUSIVE REMEDY, AS LICENSEE'S SOLE AND EXCLUSIVE ALTERNATIVE REMEDY, LICENSEE MAY RECEIVE ACTUAL DIRECT DAMAGES UP TO THE AMOUNT PAID BY LICENSEE TO 3CX FOR THE SOFTWARE.  LICENSEE HEREBY EXPRESSLY RELEASES THE 3CX PARTIES FROM ANY AND ALL LIABILITY OR RESPONSIBILITY FOR ANY DAMAGE CAUSED, DIRECTLY OR INDIRECTLY, TO LICENSEE OR ANY THIRD PARTY AS A RESULT OF THE USE OF THE SOFTWARE OR THE INTRODUCTION THEREOF INTO LICENSEE'S COMPUTER ENVIRONMENT.
The above disclaimer of warranty and liability constitutes an essential part of this License and Licensee acknowledges that Licensee's installation and use of the Software reflect Licensee's acceptance of this disclaimer of warranty and liability. Certain jurisdictions may limit 3CX's and its licensors' ability to disclaim their liability to you, in which case, the foregoing disclaimer shall be construed to limit 3CX's and its licensors' liability to the maximum extent permitted by applicable law.

8.  TERM AND TERMINATION OF LICENSE

This License is valid until terminated.  Licensee may terminate this License at any time. This License will terminate immediately if Licensee defaults or breaches any term of this License.  Upon termination of this License for any reason, any right, license or permission granted to Licensee with respect to the Software shall immediately terminate and Licensee hereby undertakes to: (i) immediately cease to use any part of the Software; and (ii) promptly return the Software and all Confidential Information and related material to 3CX and fully destroy, delete and/or de-install any copy of the Software installed or copied by Licensee. The provisions regarding confidentiality, ownership, disclaimers of warranty, limitation of liability, equitable relief and governing law and venue will survive termination of this License indefinitely in accordance with their terms.

9.  ASSIGNMENT

The License is personal to Licensee and Licensee agrees not to transfer (by operation of law or otherwise), sublicense, lease, rent, or assign their rights under this License, and any such attempt shall be null and void.  3CX may assign, transfer, or sublicense this License or any rights or obligations thereunder at any time in its sole discretion.

10.  GOVERNING LAW

This License shall be governed by and construed in accordance with the laws of the United Kingdom without regard to conflict of law provisions thereto.  Licensee submits to the jurisdiction of any court sitting in the United Kingdom in any action or proceeding arising out of or relating to this Agreement and agrees that all claims in respect of the action or proceeding may be heard and determined in any such court. 3CX may seek injunctive relief in any venue of its choosing. Licensee hereby submits to personal jurisdiction in such courts.  The parties hereto specifically exclude the United Nations Convention on Contracts for the International Sale of Goods and the Uniform Computer Information Transactions Act from this License and any transaction between them that may be implemented in connection with this License.  The original of this License has been written in English.  The parties hereto waive any statute, law, or regulation that might provide an alternative law or forum or to have this License written in any language other than English.

11.  U.S. GOVERNMENT END USERS

The Software is a "commercial item," as that term is defined in 48 C.F.R. 2.101 (Oct. 1995), consisting of "commercial computer software" and "commercial computer software documentation," as such terms are used in 48 C.F.R. 12.212 (Sept. 1995).  Consistent with 48 C.F.R. 12.212 and 48 C.F.R. 227.7202-1 through 227.7202-4 (June 1995), all U.S. Government End Users acquire the Software with only those rights set forth herein.

12.  EQUITABLE RELIEF

It is agreed that because of the proprietary nature of the Software, 3CX's and its Licensors' remedies at law for a breach by the Licensee of its obligations under this License will be inadequate and that 3CX and its Licensors shall, in the event of such breach, be entitled to, in addition to any other remedy available to it, equitable relief, including injunctive relief, without the posting of any bond and in addition to all other remedies provided under this License or available at law.

13.  COPYRIGHT NOTICES AND OTHER NOTICES

The Software is protected by the copyright laws of the United States and all other applicable laws of the United States and other nations and by any international treaties, unless specifically excluded herein.
ReSIProcate is licensed and copyrighted by SIPFoundry, Inc. and its licensors. PostgreSQL Database Management System is licensed and copyrighted by The PostgreSQL Global Development Group and The Regents of the University of California.
This product is licensed for United States Patents No. 4,994,926, No. 5,291,302, No. 5,459,584, No. 6,643,034, No. 6,785,021, No. 7,202,978 and Canadian Patents No. 1329852 and No. 2101327  The speech compression algorithm contained in this equipment uses patented technologies belonging to France TÃ©lÃ©com, Mitsubishi Electric Corporation, Nippon Telephone and Telegraph Corporation, UniversitÃ© de Sherbrooke and NEC Corporation for which 3CX has obtained the necessary patent license agreement.
EOF
}

main "$@"


EOL
chmod +x /usr/bin/3CXSBCInstallation.sh

cat > /usr/bin/3CXStartWizard.sh<<'EOH'
#!/bin/bash
/bin/chvt 2

/bin/cat /var/lib/3cxpbx/Data/Logs/PbxWebConfigTool.log 2> /dev/null | /bin/grep -a "Installation result = Success" > /dev/null 2> /dev/null
SUCCESS_PBXWEBCONFIG=$?

if [ $SUCCESS_PBXWEBCONFIG -eq 0 ]; then
  exit 0;
fi

/bin/cat /var/lib/3cxpbx/Data/Logs/PbxConfigTool.log 2> /dev/null | /bin/grep -a "Installation result = Success" > /dev/null 2> /dev/null
SUCCESS_PBXCONFIG=$?

if [ $SUCCESS_PBXCONFIG -eq 0 ]; then
  exit 0;
fi

/usr/bin/sudo /usr/sbin/3CXWizard --cleanup
sleep 3600

EOH
chmod +x /usr/bin/3CXStartWizard.sh

cat > /etc/systemd/system/3CXFirstInstallation.service<<EOI
[Unit]
Description=Starts 3CX Wizard after first installation
ConditionPathExists=/usr/sbin/3CXWizard
ConditionPathExists=!/var/lib/3cxpbx/Bin/startup
ConditionPathExists=!/var/lib/3cxpbx/Instance1/Bin/config.json
ConditionPathExists=!/var/lib/3cxpbx/Bin/nginx/conf/Instance1/
Conflicts=getty@tty2.service
AllowIsolate=yes

[Service]
Type=simple
RemainAfterExit=true
ExecStart=/usr/bin/3CXStartWizard.sh
User=root
Group=root
StandardInput=tty
TTYPath=/dev/tty2
TTYReset=yes
TTYVHangup=yes

[Install]
WantedBy=multi-user.target

EOI

chmod a+x $post
echo "#!/bin/sh" > /etc/rc.local
echo "clear; sleep 1" >> /etc/rc.local
echo "if [ -x "$post" ]; then /bin/openvt -c 10 -s $post; fi" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod +x /etc/rc.local
mkdir -p /etc/3cxpbx/
