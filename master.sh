#!/bin/sh -x

# This script sets up Foreman Master with DHCP, DNS, and PXE. 
# It assumes a development environment with no FQDN on master or node1.

# Uncomment if you want to update everything first.
# sudo yum update -y

# Comment out these lines if your host has a FQDN.
sudo hostnamectl set-hostname foreman.example.com
echo "192.168.33.10 foreman.example.com" | sudo tee -a /etc/hosts

# Comment out if running DHCP or DNS on Foreman Master and want to test a node out.
echo "192.168.33.20 node1.example.com" | sudo tee -a /etc/hosts

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
sudo yum -y install https://yum.theforeman.org/releases/1.19/el7/x86_64/foreman-release.rpm

# Install Foreman
sudo yum -y install foreman-installer
sudo foreman-installer \
--foreman-proxy-tftp=true \
--foreman-proxy-tftp-managed=true \
--foreman-proxy-tftp-servername=192.168.33.10 \
--foreman-proxy-dhcp=true \
--foreman-proxy-dhcp-managed=true \
--foreman-proxy-dhcp-interface=eth1 \
--foreman-proxy-dhcp-gateway=192.168.33.10 \
--foreman-proxy-dhcp-range="192.168.33.101 192.168.33.150" \
--foreman-proxy-dhcp-nameservers="192.168.33.10" \
--foreman-proxy-dhcp-server "192.168.33.10" \
--foreman-proxy-dns=true \
--foreman-proxy-dns-managed=true \
--foreman-proxy-dns-interface=eth1 \
--foreman-proxy-dns-zone=example.com \
--foreman-proxy-dns-reverse=33.168.192.in-addr.arpa \
--foreman-proxy-dns-forwarders="8.8.8.8; 1.1.1.1" \
--foreman-proxy-dns-server "192.168.33.10" \
--enable-foreman-plugin-ansible \
--enable-foreman-proxy-plugin-ansible \
--enable-foreman-plugin-discovery \
--enable-foreman-proxy-plugin-discovery \
--foreman-proxy-plugin-discovery-install-images=true \
--puppet-autosign-entries='*.example.com'

# Initialize Node
sudo /opt/puppetlabs/bin/puppet agent --test
