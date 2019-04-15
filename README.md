# Foreman on Vagrant or Baremetal
The following is a Foreman installation guide running on virtual machines or on baremetal with a minimal install of CentOS 7. The examples below include 1 master node, 1 node with a static IP and existing OS, and 1 node that PXE boots and can provisioned by Foreman.

## Baremetal

The following assumes your master node has an FQDN already being supplied to it via DNS. It also assumes you have 2 NICs, one attached to a WAN and one attached to a LAN for your internal nodes. 

1. Download the shell script.

```bash
curl -O https://raw.githubusercontent.com/fredeerock/foreman/master/master.sh
```

2. Make a note of your LAN interface "device name" and "connection name."

```bash
nmcli c s
```

3. Use somehting like `nmcli` to create a static ip address for you LAN interface. Replace "Wired connection 1" with the name of your connection from the previous step.

```bash
sudo nmcli c mod "Wired connection 1" ipv4.method manual ipv4.addr "192.168.33.10/24"
sudo nmcli c up "Wired connection 1"
```

4. Make needed **variable** edits inside of `master.sh` and/or `nodes.sh`. Notably, `DOMAIN`, `MASTER_HOSTNAME`, `MASTER_IP`, and `LAN_IFACE`. *Use the device name from step 2 for the `LAN_IFACE` varaible.*

5. Run the shell script.

```bash
chmod 744 master.sh
sudo ./master.sh
```

6. SSH into Forman Master and enable masquearading. Use `ip a` and `nmcli con show` to verify WAN (external) connection name. Look for the connection that does **not** have the ip address `192.168.33.10`. 

```bash
ip a
nmcli con show
sudo nmcli con mod "System eth0" connection.zone external
```

7. A this point you can proceed to the provisioning section to add nodes via PXE booting.

8. You may also choose to run the `nodes.sh` shell script on any nodes with CentOS already installed. After downloading the script make sure to change any parameters you wish.

```bash
curl -O https://raw.githubusercontent.com/fredeerock/foreman/master/nodes.sh
chmod 744 nodes.sh
sudo ./nodes.sh
```

## Vagrant

1. If you don't have FQDN on Foreman Master or a test node use the following on your host machine.

```bash
echo "192.168.33.10 foreman.example.com" | sudo tee -a /etc/hosts
echo "192.168.33.20 node1.example.com" | sudo tee -a /etc/hosts
```

2. Install Vagrant and VirtualBox.

```bash
brew cask install virtualbox
brew cask install vagrant
```

3. Check that VirtualBox  doesn't have any **Host-Only** networks and if you do have `vboxnet0` already that it uses the default `192.168.33.1` address without DHCP and has `192.168.33.10` available.

4. Clone the repo.

```bash
git clone https://github.com/fredeerock/foreman
cd foreman
```

5. Make any needed **variable** edits inside of `master.sh` or `nodes.sh`. In particular, for `DOMAIN` and `MASTER_HOSTNAME`.

6. Boot Foreman Master using Vagrant.
```bash
cd master
vagrant up
```

7. SSH into Forman Master and enable masquearading. Use `ip a` and `nmcli con show` to verify WAN (external) connection name. Look for the connection that does **not** have the ip address `192.168.33.10`. 

```bash
ip a
nmcli con show
sudo nmcli con mod "System eth0" connection.zone external
```

8. Optionally, boot a node with static IP to immediately add to Foreman.  
```bash
cd ..
cd node1
vagrant up
```

9. Oherwise proceed to the next step to set up a provisioning and PXE boot a blank node.

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

### Option 2: Hammer CLI

`**I'm shifting this content to the hammer.sh script in the repo.**`

1. SSH into foreman master.

2. Create a Hammer authentication file.

```bash
mkdir .hammer
echo -e ":foreman:\n\
  :host: 'https://foreman.example.com/'\n\
  :username: 'admin'\n\
  :password: '$(sudo awk '/^ *initial_admin_password:/ { print $2 }' /etc/foreman-installer/scenarios.d/foreman-answers.yaml)'" > ~/.hammer/cli_config.yml
sudo chmod 600 ~/.hammer/cli_config.yml
```

3. Set default organization and location.

Note current oranization and location names and IDs.

```bash
hammer organization list
hammer location list
```

Change domains, environments, and smart proxies to defaults.

```bash
hammer location update --name "Default Location" --domains "example.com" --environments "production" --smart-proxies "foreman.example.com" --media "CentOS mirror"
hammer organization update --name "Default Organization" --domains "example.com" --environments "production" --smart-proxies "foreman.example.com" --media "CentOS mirror"
```

Set defaults using above IDs.

```bash
hammer defaults add --param-name organization_id --param-value 2
hammer defaults add --param-name location_id --param-value 1
```

4. Associate Domain with DNS Proxy

```bash
hammer domain update --name "example.com" --dns "foreman.example.com"
```

5. Create a subnet.

```bash
hammer subnet create --name "My Subnet" \
--description "your_description" \
--network "192.168.33.0" --mask "255.255.255.0" \
--gateway "192.168.33.10" --dns-primary "192.168.33.10" \
--dns-secondary "8.8.8.8" --ipam "DHCP" \
--from "192.168.33.111" --to "192.168.33.250" --boot-mode "DHCP" \
--domains "example.com" --dhcp-id 1 --dns-id 1 --tftp-id 1 --discovery-id 1
```

6. Add OS associations (configuration templates, partition table, installation media).

Note config-template-id numbers with the ones output with the command below.

```bash
hammer template list | grep 'Kickstart'
```

Associate the templates with the OS using above IDs.

```bash
hammer os add-config-template --id 1 --config-template "Kickstart default"
hammer os add-config-template --id 1 --config-template "Kickstart default finish"
hammer os add-config-template --id 1 --config-template "Kickstart default PXELinux"
hammer os add-config-template --id 1 --config-template "Kickstart default iPXE"
hammer os set-default-template --id 1 --config-template-id 47
hammer os set-default-template --id 1 --config-template-id 30
hammer os set-default-template --id 1 --config-template-id 14
hammer os set-default-template --id 1 --config-template-id 37
hammer os add-ptable --id 1 --partition-table "Kickstart default"
hammer os update --id 1 --media "CentOS mirror"
```

7. Create Host Group

Check what operating systems are available with the following command.

```bash
hammer os list
```

Make sure the above output matches the **operatingsystem** argument below.

```bash
hammer hostgroup create --name "Base" \
--environment "production" \
--puppet-ca-proxy-id 1 \
--puppet-proxy-id 1 \
--domain "example.com" \
--subnet "My Subnet" \
--architecture "x86_64" \
--operatingsystem "CentOS 7.6.1810" \
--medium "CentOS mirror" \
--partition-table "Kickstart default" \
--root-pass "p@55w0rd"
```

8. Build PXE Defaults

```bash
hammer template build-pxe-default
```

## Forman Node

Back on your host machine.

1. Boot a node with DHCP to provision with Foreman using PXE. *Make sure private network name (ex: vboxnet0) matchs in Vagrantfile.* 

```bash
cd ..
cd node2
vagrant up
```
2. Choose **Foreman Discovery Image** from the VirtualBox window. Then wait for Foreman Discovery to read "SUCCESS." 

3. Go to foreman.example.com on host machine. 
- If you've forgotten the login username and password check the credentials from `~/.hammer/cli_config.yml` on foreman master. 
- Navigate to Hosts > Discovered Hosts
- Click Provision and choose Host Group **Base**.
- Wait for installation to finish.
- Once complete you can login with the Host Group password made in step 7 above.

4. You may alos choose to do the above step using the command line, but you have to install the hammer discovery plugin `yum install rubygem-hammer_cli_foreman_discovery` and set it up via: https://theforeman.org/plugins/foreman_discovery/4.0/index.html. 

## References
- https://www.theforeman.org/manuals/1.21/index.html
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.4

## Troubleshooting
- Putting host IP in for nameserver in /etc/resolv.conf seems to help anisble reach guests using FQDNs.
- Make sure to supply user and password to ansible.

## To Do
- Probably should add SSH keys on host creation.
