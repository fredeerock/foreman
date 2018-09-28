# Foreman + Vagrant
The following is a simple Foreman installation running on Virtual Machines. There is 1 Master node, 1 node with a static IP and existing OS, and 1 node that PXE boots and can provisioned by Foreman.

## Foreman Master
Install Vagrant and VirtualBox.

```bash
brew cask install virtualbox
brew cask install vagrant
```

If you don't have FQDN on Foreman Master or a test node use the following on your host machine.

```bash
echo "192.168.33.10 foreman.example.com" | sudo tee -a /etc/hosts
echo "192.168.33.20 node1.example.com" | sudo tee -a /etc/hosts
```

Clone the repo.

```bash
git clone https://github.com/fredeerock/foreman
cd foreman
```

Boot Foreman Master using Vagrant.
```bash
cd master
vagrant up
```

SSH into Forman Master and enable masquearading. Use `ip a` and `nmcli con show` to verify WAN (external) connection name.

```bash
vagrant ssh
ip a
nmcli con show
sudo nmcli con mod "System eth0" connection.zone external
```

Boot a node with static IP. 
```bash
cd ..
cd node1
vagrant up
```

## Provisioning

### Option 1: WebUI

1. Login to Foreman WebUI with url and credentials given at end of install.
2. Change login password: **Admin User > My Account**.
3. **Infrastructure > Domains > example.com > DNS Proxy> foreman.example.com**.
4. **Infrastructure > Smart Proxies > foreman.example.com > Actions > Import IPv4 Subnets**
    - Name: My Subnet
5. **Infrastructure > Subnets > My Subnet**
    - Subnet
      - Primary DNS Server: 192.168.33.10
      - Secondary DNS Server: 8.8.8.8
      - IPAM: DHCP
    - Domains
      - example.com
    - Proxies
      - DHCP, TFTP, DNS, Discovery: foreman.example.com
6. **Hosts > Provisioning Templates** 
    - Kickstart default iPXE > Association > CentOS
    - Kickstart default PXELinux > Association > CentOS
    - Kickstart default > Association > CentOS
    - Kickstart default finish> Association > CentOS
7. **Hosts > Operating Systems > CentOS** 
    - Partition Table: Kickstart default
    - Installation Media: CentOS
    - Templates: All Kickstart Defaults
8. **Configure > Host Groups > Create**
    - Host Groups
      - Puppet Master: foreman.example.com
      - Pupper CA: foreman.example.com
      - Environment: production
    - Network
      - Domain: example.com
      - IPv4 Subnet: My Subnet
    - Operating Systems
      - Architecture: x86_64
      - OS: CentOS
      - Media: CentOS Mirror
      - Partition Table: Kickstart default
      - PXE Loader: PXELinux BIOS
      - Root Pass: changeme
9. **Hosts > Provisioning Templates > Build PXE Default**
10. Not working yet.
    - Maybe need to change name server settings in the installer.
    - May have to change proxy_url in kernel options on new host to IP instead of hostname if DNS isn't functional. 
    - Also this should be change other places too. Maybe include in kickstart script to use IP instead of FQDN.

### Option 2: Hammer CLI

1. Create a Hammer authentication file.

```bash
echo ":foreman:" > ~/.hammer/cli_config.yml \
echo "  :host: 'https://foreman.example.com/'" >> ~/.hammer/cli_config.yml \
echo "  :username: 'admin'" >> ~/.hammer/cli_config.yml \
echo "  :password: '$(sudo awk '/^ *admin_password:/ { print $2 }' /etc/foreman-installer/scenarios.d/foreman-answers.yaml)'" >> ~/.hammer/cli_config.yml \
sudo chmod 600 ~/.hammer/cli_config.yml
```

2. Associate Domain with DNS Proxy

```bash
hammer domain update --name "example.com" --dns "foreman.example.com"
```

3. Create a subnet.

```bash
hammer subnet create --name "ACME's Internal Network" \
--description "your_description" \
--network "192.168.33.0" --mask "255.255.255.0" \
--gateway "192.168.33.10" --dns-primary "192.168.33.10" \
--dns-secondary "8.8.8.8" --ipam "DHCP" \
--from "192.168.33.111" --to "192.168.33.250" --boot-mode "DHCP" \
--domains "example.com" --dhcp-id 1 --dns-id 1 --tftp-id 1 --discovery-id 1
```

4. Add OS associations (configuration templates, partition table, installation media).

```bash
hammer os add-config-template --id 1 --config-template "Kickstart default" &&
hammer os add-config-template --id 1 --config-template "Kickstart default finish" &&
hammer os add-config-template --id 1 --config-template "Kickstart default PXELinux" &&
hammer os add-config-template --id 1 --config-template "Kickstart default iPXE" &&
hammer os set-default-template --id 1 --config-template-id 31 &&
hammer os set-default-template --id 1 --config-template-id 34 &&
hammer os set-default-template --id 1 --config-template-id 35 &&
hammer os set-default-template --id 1 --config-template-id 38 &&
hammer os add-ptable --id 1 --partition-table "Kickstart default" &&
hammer os update --id 1 --media "CentOS mirror"
```

5. Create Host Group

```bash
hammer hostgroup create --name "Base" \
--environment "production" \
--puppet-ca-proxy-id 1 \
--puppet-proxy-id 1 \
--domain "example.com" \
--subnet "ACME's Internal Network" \
--architecture "x86_64" \
--operatingsystem "CentOS 7.5.1804" \
--medium "CentOS mirror" \
--partition-table "Kickstart default" \
--root-pass "p@55w0rd"
```

6. Build PXE Defaults

```bash
hammer template build-pxe-default
```

Boot a node with DHCP to provision with Foreman using PXE. *Make sure private network name (ex: vboxnet42) matchs in Vagrantfile.* 
```bash
cd ..
cd node2
vagrant up
```

## References
- https://theforeman.org/manuals/1.19
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.4-beta 