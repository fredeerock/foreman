DOMAIN=example.com
MASTER_HOSTNAME=foreman
MASTER_IP=192.168.33.10
LAN_IFACE=eth1

REVERSE_DNS_ZONE=33.168.192.in-addr.arpa
DHCP_RANGE="192.168.33.101 192.168.33.150"
NODE1_HOSTNAME=node1
NODE1_IP=192.168.33.20

MASTER_FQDN=$MASTER_HOSTNAME.$DOMAIN
NODE1_FQDN=$NODE1_HOSTNAME.$DOMAIN

mkdir .hammer
echo -e ":foreman:\n\
  :host: 'https://$MASTER_FQDN/'\n\
  :username: 'admin'\n\
  :password: '$(sudo awk '/^ *initial_admin_password:/ { print $2 }' /etc/foreman-installer/scenarios.d/foreman-answers.yaml)'" > ~/.hammer/cli_config.yml
sudo chmod 600 ~/.hammer/cli_config.yml

hammer defaults add --param-name organization_id --param-value 2
hammer defaults add --param-name location_id --param-value 1

hammer domain create --name "$DOMAIN" --dns-id 1
