# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  # VM 2 Configuration
  config.vm.define "vm2" do |vm2|
    vm2.vm.box = "politessebaume0r/rocky9"
    vm2.vm.box_version = "1.2"

    vm2.vm.network "private_network", ip: "192.168.33.11"
    
    # Provisioning script for VM2 to install rsync
    vm2.vm.provision "shell", inline: <<-SHELL
      # Update the system
      sudo dnf -y update

      # Install rsync
      sudo dnf -y install rsync

      echo "Rsync installation completed on VM2."
    SHELL
  end

  # VM 1 Configuration
  config.vm.define "vm1" do |vm1|
    vm1.vm.box = "politessebaume0r/rocky9"
    vm1.vm.box_version = "1.2"

    # Synced folder for provisioning files (scripts, pem files, etc.)
    vm1.vm.synced_folder "./vagrant_provisioning", "/vagrant/vagrant_provisioning"

    # Provisioning script
    vm1.vm.provision "shell", inline: <<-SHELL
      # Install required tools
      sudo dnf -y update
      sudo dnf -y install rsync

      # Set up directories
      mkdir -p /var/backups/media
      mkdir -p /var/scripts

      # Copy script and configuration file
      echo "Copying scripts and configuration..."
      cp /vagrant/vagrant_provisioning/bkmedia.sh /var/scripts/bkmedia.sh
      cp /vagrant/vagrant_provisioning/locations.cfg /var/scripts/locations.cfg

      # Set permissions
      sudo chown vagrant:vagrant /var/scripts/bkmedia.sh /var/scripts/locations.cfg
      sudo chown -R vagrant:vagrant /var/backups/media/
      chmod -R 755 /var/backups/media/ #write permissions for dir
      chmod +x /var/scripts/bkmedia.sh # make the script executble

      # Create the .ssh directory in the VM if it doesn't exist
      echo "Setting up .ssh directory for vagrant user"
      # Ensure the .ssh directory exists and has the correct permissions
      sudo -u vagrant mkdir -p /home/vagrant/.ssh
      sudo chmod 700 /home/vagrant/.ssh

      # Copy the private key for vm2
      if [ -f /vagrant/.vagrant/machines/vm2/vmware_desktop/private_key ]; then
        sudo -u vagrant cp /vagrant/.vagrant/machines/vm2/vmware_desktop/private_key /home/vagrant/.ssh/vm2_key.pem
        echo "Private key for vm2 copied!"
      else
          echo "Private key for vm2 not found!"
      fi

      # Copy the necessary files into the .ssh directory
      sudo -u vagrant cp /vagrant/vagrant_provisioning/*.pem /home/vagrant/.ssh/ || echo "No .pem files to copy"
      sudo -u vagrant cp /vagrant/vagrant_provisioning/config /home/vagrant/.ssh/config || echo "No config file"

      # Adjust permissions
      sudo chown vagrant:vagrant /home/vagrant/.ssh/*.pem 2>/dev/null || echo "No .pem files to set ownership"
      sudo chmod 400 /home/vagrant/.ssh/*.pem 2>/dev/null || echo "No .pem files to set permissions"
      sudo chown vagrant:vagrant /home/vagrant/.ssh/config
      sudo chmod 600 /home/vagrant/.ssh/config

    SHELL
  end

  
end
