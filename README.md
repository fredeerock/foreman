# Foreman on Vagrant or Baremetal
The following is a Foreman installation guide running on virtual machines or on baremetal with a minimal install of CentOS 7. The examples below include 1 master node, 1 node with a static IP and existing OS, and 1 node that PXE boots and can provisioned by Foreman.

## Baremetal

The following makes the following assumptions for the master node:
- An FQDN and IP address being supplied via DNS and DHCP.
- CentOS Minimal Install
- 2 NICs one attached to a WAN and one attached to a LAN for your internal nodes

Follow the step below to install Foreman on this master node.

1. Download the shell script.

```bash
curl -O https://raw.githubusercontent.com/fredeerock/foreman-setup/master/master.sh
curl -O https://raw.githubusercontent.com/fredeerock/foreman-setup/master/hammer.sh
```

2. Make a note of your **LAN** and **WAN** interface "device name" using `nmcli` for the next step. Press `q` to exit.

```bash
nmcli
```

3. Make any needed **variable edits** inside of `master.sh` and/or `hammer.sh`. Notably, `WAN_IFACE`, `LAN_IFACE`, `DOMAIN`, and `MASTER_HOSTNAME`

```bash
vi master.sh
vi hammer.sh
``` 

4. Run the shell scripts with sudo.

```bash
chmod +x master.sh
chmod +x hammer.sh
sudo ./master.sh
sudo ./hammer.sh
```

5. Optionally, run the `nodes.sh` shell script on any nodes with CentOS already installed. After downloading the script make sure to change any parameters you wish. In particulare, make sure to comment out the lines that fake DNS, DHCP, and FQDN if you have those running successfully on Foreman master.

```bash
curl -O https://raw.githubusercontent.com/fredeerock/foreman-setup/master/nodes.sh
chmod 744 nodes.sh
sudo ./nodes.sh
```

6. To add nodes via Foreman Discovery, PXE boot a node with DHCP. 

7. Choose **Foreman Discovery Image** from the VirtualBox window. Then wait for Foreman Discovery to read "SUCCESS." 

8. On Foreman Master install the hammer discovery plugin and run the the provision command below with root (`sudo -i`)remembering to replace the id number.

```bash
yum install -y tfm-rubygem-hammer_cli_foreman_discovery
hammer discovery list
hammer user list
hammer hostgroup list
hammer discovery provision --id 2 --owner-id 4 --hostgroup Base --location-title "Default Location" --organization-title "Default Organization" --ask-root-password yes --build yes
```

## Vagrant

1. If you don't have a FQDN for Foreman Master or a test node use the following on your host machine.

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

5. Make any needed **variable** edits inside of `master.sh`, `hammer.sh` and/or `nodes.sh`. You don't have to edit anything if you're using example.com with Vagrant default interface names.

```bash
vi master.sh
vi hammer.sh
``` 

6. Boot Foreman Master using Vagrant.
```bash
cd master
vagrant up
```

7. If all went well, you should be ready to either PXE boot a blank node or manually add a node to Foreman. Take a note of the initial credentials output to you.

8. To **PXE boot** a node with DHCP and have provisioned by Foreman run the following back on your host machine. 

```bash
cd ..
cd node-pxe
vagrant up
```

9. Choose **Foreman Discovery Image** from the VirtualBox window. Then wait (the full 45 seconds) for Foreman Discovery to read "SUCCESS." 

10. On Foreman Master install the hammer discovery plugin and run the the provision command below with root (`sudo -i`)remembering to replace the id number.

```bash
yum install -y tfm-rubygem-hammer_cli_foreman_discovery
hammer discovery list
hammer user list
hammer hostgroup list
hammer discovery provision --id 2 --owner-id 4 --hostgroup Base --location-title "Default Location" --organization-title "Default Organization" --ask-root-password yes --build yes
```

11. **Optionally,** you may use the web interface to provision. Go to foreman.example.com on host machine. 
- If you've forgotten the login username and password check the credentials from `~/.hammer/cli_config.yml` on foreman master. 
- Navigate to Hosts > Discovered Hosts
- Click Provision and choose Host Group **Base**.
- Wait for installation to finish.
- Once complete you can login with the Host Group password made in step 7 above.

12. **Optioanlly,** manually add a CentOS node to Foreman.  

```bash
cd ..
cd node-manual
vagrant up
```

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
- May need to supply user and password to ansible.

## To Do
- Image based creation isn't injecting users
- Associate Kickstart user data template with OS. Maybe this fixes above.
- Figure out how to add SSH keys on host creation (https://access.redhat.com/documentation/en-us/red_hat_satellite/6.5/html/provisioning_guide/provisioning_bare_metal_hosts#Configuring_Provisioning_Resources-Creating_Provisioning_Templates-Deploying_SSH_Keys_during_Provisioning). 
- Would also be nice to be able to set default provision root pass with SHA256 if you don't want to pass one like above. *Note: This isn't working for some reason.*

```bash
ENCPASS="$(python -c 'import crypt,getpass;pw=getpass.getpass(); print(crypt.crypt(pw,crypt.mksalt(crypt.METHOD_SHA256))) if (pw==getpass.getpass("Confirm: ")) else exit()')"
hammer settings set --name root_pass --value "$ENCPASS"
```

## Plugins worth considering
- Docker: `foreman-installer -–enable-foreman-plugin-docker`

## Notes on Creating a KVM Compute Resource and Host on Foreman Master

References:
- https://theforeman.org/manuals/1.21/index.html#4.3.11Libvirt
- https://theforeman.org/manuals/1.21/index.html#5.2.5LibvirtNotes
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.5/html/provisioning_guide/provisioning_virtual_machines_in_kvm

Install libvirt compute.

```bash
foreman-installer --enable-foreman-compute-libvirt`
```

On Foreman Master login and switch to root

```bash
sudo -i
```

Create SSH keys and install libvirt.

```bash
su foreman -s /bin/bash
ssh-keygen
ssh-copy-id root@kvm.example.com
exit
yum install -y qemu-kvm libvirt virt-install libvirt-python virt-manager virt-install libvirt-client libguestfs-tools
systemctl start libvirtd
systemctl enable libvirtd
```

Test your connection with the below. Should get a blank table.

```bash
su foreman -s /bin/bash -c 'virsh -c qemu+ssh://root@kvm.example.com/system list'
```

Change file: vi /etc/libvirt/qemu.conf 
  `#user = root  -> user = root`
  `#group = "root" - > group = "root"` 

  Find password for virt-manager: 
  
  ```bash
  virsh list
  virsh dumpxml <vm-id/name> --security-info
  ```
