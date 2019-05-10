#!/bin/bash -x

# Variables

DOMAIN=example.com
MASTER_HOSTNAME=foreman

MASTER_IP=192.168.33.10
MASTER_FQDN=$MASTER_HOSTNAME.$DOMAIN

# Create a Hammer authentication file.

mkdir .hammer
echo -e ":foreman:\n\
  :host: 'https://$MASTER_FQDN/'\n\
  :username: 'admin'\n\
  :password: '$(sudo awk '/^ *initial_admin_password:/ { print $2 }' /etc/foreman-installer/scenarios.d/foreman-answers.yaml)'" > ~/.hammer/cli_config.yml
sudo chmod 600 ~/.hammer/cli_config.yml

# Change domains, environments, and smart proxies to defaults.

hammer location update --name "Default Location" --domains "$DOMAIN" --environments "production" --smart-proxies "$MASTER_FQDN" --media "CentOS mirror"
hammer organization update --name "Default Organization" --domains "$DOMAIN" --environments "production" --smart-proxies "$MASTER_FQDN" --media "CentOS mirror"

# Set defaults using above IDs.

hammer defaults add --param-name organization_id --param-value 2
hammer defaults add --param-name location_id --param-value 1

# Associate Domain with DNS Proxy

hammer domain update --name "$DOMAIN" --dns-id 1

# Create a subnet.

hammer subnet create --name "My Subnet" \
--network "192.168.33.0" --mask "255.255.255.0" \
--gateway "$MASTER_IP" --dns-primary "$MASTER_IP" \
--dns-secondary "8.8.8.8" --ipam "DHCP" \
--from "192.168.33.111" --to "192.168.33.250" --boot-mode "DHCP" \
--domains "$DOMAIN" --dhcp-id 1 --dns-id 1 --tftp-id 1 --discovery-id 1

# Add OS associations (configuration templates, partition table, installation media).

hammer os add-config-template --id 1 --config-template "Kickstart default"
hammer os add-config-template --id 1 --config-template "Kickstart default finish"
hammer os add-config-template --id 1 --config-template "Kickstart default PXELinux"
hammer os add-config-template --id 1 --config-template "Kickstart default iPXE"
hammer os set-default-template --id 1 --config-template-id 47
hammer os set-default-template --id 1 --config-template-id 30
hammer os set-default-template --id 1 --config-template-id 14
hammer os set-default-template --id 1 --config-template-id 37
hammer os add-ptable --id 1 --partition-table "Kickstart default"

# Create Host Group

hammer hostgroup create --name "Base" \
--environment "production" \
--puppet-ca-proxy-id 1 \
--puppet-proxy-id 1 \
--domain "$DOMAIN" \
--subnet "My Subnet" \
--architecture "x86_64" \
--operatingsystem "CentOS 7.6.1810" \
--medium "CentOS mirror" \
--partition-table "Kickstart default" \
--root-pass "p@55w0rd!"

# Because of a bug the following actions error out when defaults are set so deleting them.

hammer defaults delete --param-name organization_id
hammer defaults delete --param-name location_id

# Associate medium with OS.

hammer os update --id 1 --media "CentOS mirror"

# Build PXE Defaults

hammer template build-pxe-default
