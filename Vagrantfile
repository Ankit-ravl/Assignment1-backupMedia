# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Vagrant development environment box.
  config.vm.box = "politessebaume0r/rocky9"
  config.vm.box_version = "1.2"

  # Synced folder for provisioning files (scripts, pem files, etc.)
  config.vm.synced_folder "./vagrant_provisioning", "/vagrant/vagrant_provisioning"

  # Provisioning script
  config.vm.provision "shell", inline: <<-SHELL
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
    echo "Making .ssh directory"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # Copy all `.pem` files from the synced folder to the VM's .ssh directory
    echo "Copying pem files"
    cp /vagrant/vagrant_provisioning/*.pem ~/.ssh/ || echo "No .pem files to copy"
    cp /vagrant/vagrant_provisioning/config ~/.ssh/config || echo "No config file"
    chmod 400 ~/.ssh/*.pem 2>/dev/null || echo "No .pem files to set permissions"
    echo "Setup complete!"
  SHELL
end
