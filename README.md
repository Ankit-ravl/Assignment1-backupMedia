# STEPS

### 1 Provision the virtual machine
`vagrant up`
### 2 ssh into the machine
`vagrant ssh`
### 3  Copy the secret key from the sync folder to the `.ssh` folder
 `cp /vagrant/vagrant_provisioning/backup_test.pem ~/.ssh/`
### 4 Copy the config file
`cp /vagrant/vagrant_provisioning/config ~/.ssh/`

### 5 Go to ssh folder and change permissions
`chmod 400 backup_test.pem`

### 6 Go the folder where `bkmedia.sh` script is 

`cd /var/scripts/`

### 7 Run the script with different options

`./bkmedia.sh -B -L 4`
 this will back up the 4th server




