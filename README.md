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

1. Login to Foreman WebUI with url and credentials given at end of install.
2. Change login password: **Admin User > My Account**.
3. **Infrastructure > Domains > example.com > DNS Proxy> foreman.example.com**.
4. **Infrastructure > Smart Proxies > foreman.example.com > Actions > Import IPv4 Subnets**
    - Name: My Subnet
5. **Infrastructure > Subnets > My Subnet**
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

Boot a node with DHCP to provision with Foreman using PXE. *Make sure private network name (ex: vboxnet42) matchs in Vagrantfile.* 
```bash
cd ..
cd node2
vagrant up
```

## References
- https://theforeman.org/manuals/1.19
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.3