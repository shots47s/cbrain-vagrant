# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = "sylabs/singularity-3.7-ubuntu-bionic64"

  config.vm.network "forwarded_port", guest: 3000, host: 3000
  # config.vm.network "public_network"
  # config.vm.synced_folder "../data", "/vagrant_data"

  required_plugins = %w( vagrant-vbguest vagrant-disksize )
  _retry = false
  required_plugins.each do |plugin|
    unless Vagrant.has_plugin? plugin
      system "vagrant plugin install #{plugin}"
      _retry=true
    end
  end

  if (_retry)
      exec "vagrant " + ARGV.join(' ')
  end 
   
  config.disksize.size="20GB"

  config.vm.provider "virtualbox" do |vb|
     vb.memory = "8129"
  end

  ## Set the timezone that you are in here
  require 'time'
  timezonetmp = (-1*((Time.zone_offset(Time.now.zone)/60)/60))
  timezone = timezonetmp >- 1 ? "Etc/GMT+" + timezonetmp.to_s : "Etc/GMT" + timezonetmp.to_s 
  config.vm.provision :shell, privileged: true, run: "always", inline: <<-SHELL
      apt-get install ntp -y
      sudo timedatectl set-timezone #{timezone}
      sudo service ntp restart
  SHELL
  
  # View the documentation for the provider you are using for more
  # information on available options.

  config.vm.provision "fix-no-tty", type: "shell" do |s|
    s.privileged = false
    s.path = "provision/setup.sh"
  end

  config.vm.provision "shell", privileged: false, run: "always", inline: <<-SHELL
    cd ~/cbrain/BrainPortal
    echo "Please login in to the portal for the first time as user 'admin'"
    cat /tmp/cbinit.txt
#    rails server puma -e development -p 3000 -b 0.0.0.0> ~/cbrain.log &
  SHELL
end
