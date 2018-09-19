# Host
- `git clone`
- `cd foreman`
- `cd master`
- `vagrant up`
- `cd ../nodes/`
- `vagrant up`
- `sudo echo "192.168.33.10 foreman.example.com" | sudo tee -a /etc/hosts`
- `sudo echo "192.168.33.20 node1.example.com" | sudo tee -a /etc/hosts`

# Foreman
- `cd master`
- `vagrant ssh`
- `sudo yum update -y`

- `sudo hostnamectl set-hostname foreman.example.com`
- `echo "192.168.33.10 foreman.example.com" | sudo tee -a /etc/hosts`
- `echo "192.168.33.20 node1.example.com" | sudo tee -a /etc/hosts`

- `sudo systemctl start firewalld && \
sudo systemctl enable firewalld && \
sudo firewall-cmd --permanent --add-service=http && \
sudo firewall-cmd --permanent --add-service=https && \
sudo firewall-cmd --permanent --add-port=69/tcp && \
sudo firewall-cmd --permanent --add-port=67-69/udp && \
sudo firewall-cmd --permanent --add-port=53/tcp && \
sudo firewall-cmd --permanent --add-port=53/udp && \
sudo firewall-cmd --permanent --add-port=3000/tcp && \
sudo firewall-cmd --permanent --add-port=3306/tcp && \
sudo firewall-cmd --permanent --add-port=5910-5930/tcp && \
sudo firewall-cmd --permanent --add-port=5432/tcp && \
sudo firewall-cmd --permanent --add-port=8140/tcp && \
sudo firewall-cmd --permanent --add-port=8443/tcp && \
sudo firewall-cmd --reload`

- `sudo yum -y install https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm`
- `sudo yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm`
- `sudo yum -y install https://yum.theforeman.org/releases/1.19/el7/x86_64/foreman-release.rpm`
- `sudo yum -y install foreman-installer`
- `sudo foreman-installer`

- `sudo /opt/puppetlabs/bin/puppet agent --test`

# Nodes
- `cd master`
- `vagrant ssh`
- `sudo yum update -y`

- `sudo hostnamectl set-hostname node1.example.com`
- `echo "192.168.33.10 foreman.example.com" | sudo tee -a /etc/hosts`
- `echo "192.168.33.20 node1.example.com" | sudo tee -a /etc/hosts`

- `sudo rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm`
- `sudo yum -y install puppet-agent`

- `echo "server = foreman.example.com" | sudo tee -a /etc/puppetlabs/puppet/puppet.conf`
- `echo "runinterval = 120s" | sudo tee -a /etc/puppetlabs/puppet/puppet.conf`

- `sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true`

- `sudo /opt/puppetlabs/bin/puppet agent --test`
