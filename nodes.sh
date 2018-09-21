#!/bin/sh -x

# This script is useful for connecting a node already running an OS to Foreman Master. 

# Uncomment if you want to update everything first.
# sudo yum update -y

# Comment out if Foreman Master has a FQDN.
echo "192.168.33.10 foreman.example.com" | sudo tee -a /etc/hosts

# Comment out these lines if DHCP and DNS aren't running on Foreman Master.
sudo hostnamectl set-hostname node1.example.com
echo "192.168.33.20 node1.example.com" | sudo tee -a /etc/hosts

# Install Puppet Agent
sudo rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
sudo yum -y install puppet-agent

# Replace server variable with FQDN of Foreman Master.
echo "server = foreman.example.com" | sudo tee -a /etc/puppetlabs/puppet/puppet.conf

# Comment this line out when not testing configurations
echo "runinterval = 120s" | sudo tee -a /etc/puppetlabs/puppet/puppet.conf

# Enable Puppet Agent
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

# Initialize Node
sudo /opt/puppetlabs/bin/puppet agent --test --waitforcert 60

# Go to Formeman Master > Infrastructure > Smart Proxies > Puppet CA > Certificates to for sign new node.