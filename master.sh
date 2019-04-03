#!/bin/sh -x

# This script sets up Foreman Master with DHCP, DNS, and PXE. 
# It assumes a development environment with no FQDN on master or node1.

# VARIABLES
DOMAIN=example.com
MASTER_HOSTNAME=foreman
MASTER_IP=192.168.33.10
REVERSE_DNS_ZONE=33.168.192.in-addr.arpa
DHCP_RANGE="192.168.33.101 192.168.33.150"
NODE1_HOSTNAME=node1
NODE1_IP=192.168.33.20

MASTER_FQDN=$MASTER_HOSTNAME.$DOMAIN
NODE1_FQDN=$MASTER_HOSTNAME.$DOMAIN

# Uncomment if you want to update everything first.
# sudo yum update -y

# Change the following to you hostname
sudo hostnamectl set-hostname $MASTER_FQDN

# Comment out these lines if your host has a FQDN.
echo "$MASTER_IP $MASTER_FQDN" | sudo tee -a /etc/hosts

# Comment out if running DHCP or DNS on Foreman Master and want to test a node out.
echo "192.168.33.20 $NODE1_FQDN" | sudo tee -a /etc/hosts

# Firewall
sudo systemctl start firewalld 
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=69/tcp
sudo firewall-cmd --permanent --add-port=67-69/udp
sudo firewall-cmd --permanent --add-port=53/tcp
sudo firewall-cmd --permanent --add-port=53/udp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --permanent --add-port=5910-5930/tcp
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --permanent --add-port=8140/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --reload

# Repositories
sudo yum -y install https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
sudo yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install https://yum.theforeman.org/releases/1.21/el7/x86_64/foreman-release.rpm

# Install Foreman
sudo yum -y install foreman-installer
sudo foreman-installer \
--foreman-proxy-tftp=true \
--foreman-proxy-tftp-managed=true \
--foreman-proxy-tftp-servername=$MASTER_IP \
--foreman-proxy-dhcp=true \
--foreman-proxy-dhcp-managed=true \
--foreman-proxy-dhcp-interface=eth1 \
--foreman-proxy-dhcp-gateway=$MASTER_IP \
--foreman-proxy-dhcp-range="192.168.33.101 192.168.33.150" \
--foreman-proxy-dhcp-nameservers=$MASTER_IP \
--foreman-proxy-dhcp-server $MASTER_IP \
--foreman-proxy-dns=true \
--foreman-proxy-dns-managed=true \
--foreman-proxy-dns-interface=eth1 \
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
--enable-foreman-proxy-plugin-remote-execution-ssh
# -–enable-foreman-plugin-docker

# Initialize Node
while [ -f /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock ]
do
  sleep 2
done
sudo /opt/puppetlabs/bin/puppet agent --test