# Host
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

Clone the repo and use Vagrant

```bash
git clone https://github.com/fredeerock/foreman
cd foreman
cd master
vagrant up
cd ..

# For a node with OS and static IP use: 
cd node1
vagrant up

# For a node without OS and DHCP to PXE boot use: 
cd node2
vagrant up
```

# Notes

- also set up masquerading on foreman master

## References
- https://projects.theforeman.org/projects/foreman/wiki/Unattended_installations
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.3/html-single/provisioning_guide/
- https://access.redhat.com/discussions/2085933
