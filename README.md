# Foreman on Vagrant or Baremetal
The following is a Foreman installation guide running on virtual machines or on baremetal with a minimal install of CentOS 7. The examples below include 1 master node, 1 node with a static IP and existing OS, and 1 node that PXE boots and can provisioned by Foreman.

## Baremetal

The following assumes your master node has an FQDN already being supplied to it via DNS. It also assumes you have 2 NICs, one attached to a WAN and one attached to a LAN for your internal nodes. 

1. Download the shell script.

```bash
curl -O https://raw.githubusercontent.com/fredeerock/foreman-setup/master/master.sh
curl -O https://raw.githubusercontent.com/fredeerock/foreman-setup/master/hammer.sh
```

2. Make a note of your LAN interface "device name" and "connection name."

```bash
nmcli con show
```

3. Use somehting like `nmcli` to create a static ip address for you LAN interface. Replace "Wired connection 1" with the name of your connection from the previous step.

```bash
sudo nmcli c mod "Wired connection 1" ipv4.method manual ipv4.addr "192.168.33.10/24"
sudo nmcli c up "Wired connection 1"
```

4. SSH into Forman Master and enable masquearading. Use `ip a` and `nmcli con show` to verify WAN (external) connection name. Look for the connection that does **not** have the ip address `192.168.33.10`. Replace "System eth0" with this connection's name.

```bash
ip a
nmcli con show
sudo nmcli con mod "System eth0" connection.zone external
sudo nmcli con up "System eth0"
```

5. Make needed **variable** edits inside of `master.sh` and/or `hammer.sh`. Notably, `DOMAIN`, `MASTER_HOSTNAME`, and `LAN_IFACE`. *Use the device name from step 2 for the `LAN_IFACE` varaible in `master.sh`.*

6. Run the shell script.

```bash
chmod 744 master.sh
sudo ./master.sh
chmod 744 hammer.sh
sudo ./hammer.sh
```

7. Optionally, run the `nodes.sh` shell script on any nodes with CentOS already installed. After downloading the script make sure to change any parameters you wish. In particulare, make sure to comment out the lines that fake DNS, DHCP, and FQDN if you have those running successfully on Foreman master.

```bash
curl -O https://raw.githubusercontent.com/fredeerock/foreman-setup/master/nodes.sh
chmod 744 nodes.sh
sudo ./nodes.sh
```

8. To add nodes via Foreman Discovery, PXE boot a node with DHCP. 

2. Choose **Foreman Discovery Image** from the VirtualBox window. Then wait for Foreman Discovery to read "SUCCESS." 

3. Go to foreman.example.com on host machine. 
- If you've forgotten the login username and password check the credentials from `~/.hammer/cli_config.yml` on foreman master. 
- Navigate to Hosts > Discovered Hosts
- Click Provision and choose Host Group **Base**.
- Wait for installation to finish.
- Once complete you can login with the Host Group password made in step 7 above.

4. You may also choose to do the above step using the command line, but you have to install the hammer discovery plugin `yum install rubygem-hammer_cli_foreman_discovery` and set it up via: https://theforeman.org/plugins/foreman_discovery/4.0/index.html. 

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

3. Check that VirtualBox doesn't have any **Host-Only** networks or if you do have `vboxnet0` already that it uses the default `192.168.33.1` address without DHCP and has `192.168.33.10` available.

```bash
vboxmanage list hostonlyifs 
```

4. Clone the repo.

```bash
git clone https://github.com/fredeerock/foreman-setup
cd foreman-setup
```

5. Make any needed **variable** edits inside of `master.sh`, `hammer.sh` and/or `nodes.sh`. In particular, for `DOMAIN` and `MASTER_HOSTNAME`.

6. Boot Foreman Master using Vagrant.
```bash
cd master
vagrant up
```

7. SSH into Forman Master and enable masquearading. Use `ip a` and `nmcli con show` to verify WAN (external) connection name. Look for the connection that does **not** have the ip address `192.168.33.10`. Replace "System eth0" with this connection's name.

```bash
ip a
nmcli con show
sudo nmcli con mod "System eth0" connection.zone external
```

8. If all went well, you should be ready to either PXE boot a blank node or manually add a node to Foreman.

8. Optionally, boot a CentOS node with static IP to immediately add to Foreman.  

```bash
cd ..
cd node1
vagrant up
```

10. To PXE boot a node with DHCP to provision with Foreman. Run the following back on your host machine. *Make sure private network name (ex: vboxnet0) matchs in Vagrantfile.* 

```bash
cd ..
cd node2
vagrant up
```
11. Choose **Foreman Discovery Image** from the VirtualBox window. Then wait for Foreman Discovery to read "SUCCESS." 

12. Go to foreman.example.com on host machine. 
- If you've forgotten the login username and password check the credentials from `~/.hammer/cli_config.yml` on foreman master. 
- Navigate to Hosts > Discovered Hosts
- Click Provision and choose Host Group **Base**.
- Wait for installation to finish.
- Once complete you can login with the Host Group password made in step 7 above.

13. You may also choose to do the above step using the command line, but you have to install the hammer discovery plugin `yum install rubygem-hammer_cli_foreman_discovery` and set it up via: https://theforeman.org/plugins/foreman_discovery/4.0/index.html. 

## Manual Provisioning Setup using the WebUI

Instead of running the `hammer.sh` script in the **Baremetal** or **Vagrant** sections above you may choose to setup Foreman using the WebUI with the below commands. 

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

## References
- https://www.theforeman.org/manuals/1.21/index.html
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.4

## Troubleshooting
- Putting host IP in for nameserver in /etc/resolv.conf seems to help anisble reach guests using FQDNs.
- Make sure to supply user and password to ansible.

## To Do
- Probably should add SSH keys on host creation.
