# Foreman + Vagrant
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

SSH into Forman Master and enable masquearading. Use `ip a` and `nmcli con show` to verify LAN (internal) and WAN (external) connection names.

```bash
vagrant ssh
ip a
nmcli con show
sudo nmcli con mod "System eth0" connection.zone external
sudo nmcli con mod "System eth1" connection.zone internal
```

Boot a node with static IP. 
```bash
cd ..
cd node1
vagrant up
```

Boot a node with DHCP to provision with Foreman using PXE. 
```bash
cd ..
cd node2
vagrant up
```

## References
- https://projects.theforeman.org/projects/foreman/wiki/Unattended_installations
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.3/html-single/provisioning_guide/
- https://access.redhat.com/discussions/2085933
