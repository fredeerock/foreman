#!/bin/bash -x

# This script sets up Foreman Master with DHCP, DNS, and PXE on either baremetal or Vagrant. 

# Variables that likely should be changed if running on baremetal.
DOMAIN=example.com
MASTER_HOSTNAME=foreman
LAN_IFACE=eth1
WAN_IFACE=eth0

# Variables that likely don't need to be changed.
MASTER_IP=192.168.33.10
REVERSE_DNS_ZONE=33.168.192.in-addr.arpa
DHCP_RANGE="192.168.33.11 192.168.33.110"
NODE1_HOSTNAME=node1
NODE1_IP=192.168.33.20

MASTER_FQDN=$MASTER_HOSTNAME.$DOMAIN
NODE1_FQDN=$NODE1_HOSTNAME.$DOMAIN

# Exit if any commands fail
set -e

# Sets hostname based on variables above.
hostnamectl set-hostname $MASTER_FQDN

# Set internal network to same hostname as external network
echo "$MASTER_IP $MASTER_FQDN" | tee -a /etc/hosts

# MAYBE NOT NEEDED: In case you're using example.com presume no DNS so add domain to /etc/hosts.
# if [ $DOMAIN = example.com ]; then echo "$MASTER_IP $MASTER_FQDN" | tee -a /etc/hosts; fi

# Uncomment if not running DNS on Foreman Master and want to test a node out.
# echo "$NODE1_IP $NODE1_FQDN" | tee -a /etc/hosts

# Firewall
systemctl start firewalld 
systemctl enable firewalld

firewall-cmd --zone=external --permanent --add-port=80/tcp
firewall-cmd --zone=external --permanent --add-port=443/tcp

firewall-cmd --zone=public --permanent --add-port=53/tcp
firewall-cmd --zone=public --permanent --add-port=53/udp
firewall-cmd --zone=public --permanent --add-port=67-69/udp
firewall-cmd --zone=public --permanent --add-port=69/tcp
firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=3000/tcp
firewall-cmd --zone=public --permanent --add-port=3306/tcp
firewall-cmd --zone=public --permanent --add-port=5000/tcp
firewall-cmd --zone=public --permanent --add-port=5432/tcp
firewall-cmd --zone=public --permanent --add-port=5647/tcp
firewall-cmd --zone=public --permanent --add-port=5910-5930/tcp
firewall-cmd --zone=public --permanent --add-port=8000/tcp
firewall-cmd --zone=public --permanent --add-port=8140/tcp
firewall-cmd --zone=public --permanent --add-port=8443/tcp
firewall-cmd --zone=public --permanent --add-port=9090/tcp
firewall-cmd --reload

# Rename NetworkManager Connections
nmcli -g UUID c show | while read line; do if [ "`nmcli -g GENERAL.DEVICES c s $line`" = "$LAN_IFACE" ] || [ "`nmcli -g connection.interface-name c s $line`" = "$LAN_IFACE" ]; then nmcli c mod $line con-name lan-con; fi; done
nmcli -g UUID c show | while read line; do if [ "`nmcli -g GENERAL.DEVICES c s $line`" = "$WAN_IFACE" ] || [ "`nmcli -g connection.interface-name c s $line`" = "$WAN_IFACE" ]; then nmcli c mod $line con-name wan-con; fi; done

# Set Static IP LAN interface and Persistent Firewall Zones
nmcli c mod lan-con ipv4.method manual ipv4.addr "$MASTER_IP/24" connection.zone "public"

# Also set DNS to self so Foreman can find nodes
nmcli c mod lan-con +ipv4.dns 192.168.33.10 ipv4.dns-priority 1
nmcli c up lan-con

nmcli c mod wan-con connection.zone "external"
nmcli c up wan-con

# Repositories
yum -y install https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install https://yum.theforeman.org/releases/1.21/el7/x86_64/foreman-release.rpm

# Install Foreman
yum -y install foreman-installer
foreman-installer \
--foreman-proxy-tftp=true \
--foreman-proxy-tftp-managed=true \
--foreman-proxy-tftp-servername=$MASTER_IP \
--foreman-proxy-dhcp=true \
--foreman-proxy-dhcp-managed=true \
--foreman-proxy-dhcp-interface=$LAN_IFACE \
--foreman-proxy-dhcp-gateway=$MASTER_IP \
--foreman-proxy-dhcp-range="$DHCP_RANGE" \
--foreman-proxy-dhcp-nameservers=$MASTER_IP \
--foreman-proxy-dhcp-server $MASTER_IP \
--foreman-proxy-dns=true \
--foreman-proxy-dns-managed=true \
--foreman-proxy-dns-interface=$LAN_IFACE \
--foreman-proxy-dns-zone=$DOMAIN \
--foreman-proxy-dns-reverse=$REVERSE_DNS_ZONE \
--foreman-proxy-dns-forwarders="8.8.8.8; 1.1.1.1" \
--foreman-proxy-dns-server $MASTER_IP \
--puppet-autosign-entries="*.$DOMAIN" \
--enable-foreman-plugin-ansible \
--enable-foreman-proxy-plugin-ansible \
--enable-foreman-plugin-discovery \
--enable-foreman-proxy-plugin-discovery \
--foreman-proxy-plugin-discovery-install-images=true \
--enable-foreman-plugin-remote-execution \
--enable-foreman-proxy-plugin-remote-execution-ssh \
--enable-foreman-plugin-cockpit
# -–enable-foreman-plugin-docker # this is breaking the install currently.

# Initialize Node
while [ -f /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock ]
do
  sleep 2
done
/opt/puppetlabs/bin/puppet agent --test