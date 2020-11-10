#!/bin/bash

logFile=/tmp/provision.log

echo "Installing MySQL Server" > $logFile
echo "-----------------------------------------------" >> $logFile
sudo apt-get update
sudo apt-get install mariadb-server -y >> $logFile

sqlscript="/tmp/tmp.sql"

echo "Creating MySQL Database" >> $logFile
echo "-----------------------------------------------" >> $logFile

touch $sqlscript
echo "CREATE USER 'cbrain'@'localhost' IDENTIFIED BY 'CBRAIN';" >> $sqlscript
echo "CREATE DATABASE cbrain_db CHARACTER SET 'utf8';" >> $sqlscript
echo "GRANT ALL ON cbrain_db.* TO 'cbrain'@'localhost';" >> $sqlscript
echo "FLUSH PRIVILEGES;" >> $sqlscript

cat $sqlscript | sudo mysql -u root >> $logFile

### Installing Ruby Version Manager

echo "Installing Ruby Version Manager" >> $logFile
echo "-----------------------------------------------" >> $logFile

cd $HOME

sudo apt-get install curl libsodium-dev gnupg2 -y
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
# \curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - >> $logFile
\curl -sSL https://get.rvm.io | bash -s stable >> $logFile

source $HOME/.rvm/scripts/rvm >> $logFile

echo "Installing Ruby" > $logFile
echo "-----------------------------------------------" >> $logFile

rvm info >> $logFile
rvm install 2.6 >> $logFile
rvm --default 2.6 >> $logFile

## Get CBRAIN Code

echo "Cloning CBRAIN" >> $logFile
echo "-----------------------------------------------" >> $logFile

cd $HOME
git clone https://github.com/aces/cbrain.git >> $logFile

### Make sure we have all of the requirements

echo "Installing additional packages" >> $logFile
echo "-----------------------------------------------" >> $logFile

sudo apt-get install libmysqlclient-dev -y >> $logFile
sudo apt-get install libxml2 libxml2-dev -y >> $logFile
sudo apt-get install libxslt1.1 -y >> $logFile
sudo apt-get install libsodium-dev -y >> $logFile
sudo apt-get install libcurl4-openssl-dev -y >>  $logFile


## create database.yml file

echo "Installing BrainPortal" >> $logFile

cd $HOME/cbrain/BrainPortal/config
sed 's/cbrain_db_name_here/cbrain_db/g' database.yml.TEMPLATE | sed 's/cbrain_db_user_name_here/cbrain/g' | sed 's/cbrain_db_user_pw_here/CBRAIN/g' > database.yml

## install bundler

gem install bundler >> $logFile
cd $HOME/cbrain/BrainPortal; bundle install >> $logFile
cd $HOME/cbrain/Bourreau; bundle install >> $logFile

cd `bundle show sys-proctable`; rake install >> $logFile

### For now, we will make this the developer setup

cd $HOME/cbrain/BrainPortal/config/initializers
sed 's/simple_name/CBRAINVagrant/g' config_portal.rb.TEMPLATE > config_portal.rb

cd $HOME/cbrain/Bourreau/config/initializers
sed 's/simple_name/LocalBourreau/g' config_bourreau.rb.TEMPLATE > config_bourreau.rb

### Initialize Database Schema

echo "Database Schema Initialization" >> $logFile
cd $HOME/cbrain/BrainPortal
rake db:schema:load RAILS_ENV=development >> $logFile
rake db:seed RAILS_ENV=development | grep "admin password" > /tmp/cbinit.txt

echo "Running Sanity Checks" >> $logFile
rake db:sanity:check RAILS_ENV=development >> $logFile

cd $HOME/cbrain/BrainPortal >> $logFile
rake cbrain:plugins:install:all >> $logFile

cd $HOME/cbrain/Bourreau >> $logFile
rake cbrain:plugins:install:all >> $logFile

### Make local directories for Caching and DP
mkdir $HOME/BPCache
mkdir $HOME/BorCache
mkdir $HOME/BorWork
mkdir $HOME/FlatLocalDP
mkdir $HOME/SshDP
mkdir $HOME/CBLocalDP

### install docker

dockerLog=/tmp/docker-install.log
sudo apt-get install docker.io -y > $dockerLog
sudo usermod -a -G docker ubuntu >> $dockerLog

cd $HOME


#### Set up the BrainPortal Cache and timezone
cd $HOME/cbrain/BrainPortal

echo $HOME | xargs -I {} echo 'p=RemoteResource.first; p.dp_cache_dir="{}/BPCache"; p.save' | rails c >> $logFile
timezone=`timedatectl status | grep 'Time zone' | awk '{print $3}'`
echo $timezne | xargs -I {} echo 'p=User.first; p.time_zone = "{}"; p.save' | rails c >> $logFile

### Setup local DataProvider

echo $HOME | xargs -I {} echo 'DataProvider.create :id => 2, :name => "LocalDP", :type => "FlatDirLocalDataProvider", :remote_dir => "{}/FlatLocalDP", :description => "Automatically Generated Local Data Provider", :user_id => 1, :group_id => 1, :online => 1' | rails c >> $logFile
echo $timezone | xargs -I {} echo 'd=DataProvider.where("id=2").first; d.time_zone = "{}"; d.save' | rails c >> $logFile

cat ~/.ssh/id_cbrain_portal.pub >> ~/.ssh/authorized_keys
echo $HOME | xargs -I {} echo 'DataProvider.create :id => 3, :name => "SshDP", :type => "FlatDirSshDataProvider", :remote_dir => "{}/SshDP", :description => "Automatically Generated SSH Data Provider", :user_id => 1, :group_id => 1, :online => 1' | rails c >> $logFile
echo $timezone | xargs -I {} echo 'd=DataProvider.where("id=3").first; d.time_zone = "{}"; d.save' | rails c >> $logFile
echo $USER | xargs -I {} echo 'd=DataProvider.where("id=3").first; d.remote_user = "{}"; d.remote_host = "localhost"; d.remote_port = 22; d.save' | rails c >> $logFile

echo $HOME | xargs -I {} echo 'DataProvider.create :id => 4, :name => "CbrainDP", :type => "EnCbrainSmartDataProvider", :remote_dir => "{}/CBLocalDP", :description => "Automatically Generated Smart Data Provider", :user_id => 1, :group_id => 1, :online => 1' | rails c >> $logFile
echo $USER | xargs -I {} echo 'd=DataProvider.where("id=4").first; d.remote_user = "{}"; d.remote_host = "localhost"; d.remote_port = 22; d.save' | rails c >> $logFile
echo $timezone | xargs -I {} echo 'd=DataProvider.where("id=4").first; d.time_zone = "{}"; d.save' | rails c >> $logFile

#### Set up the local Bourreaux

# Make sure you can see bundle at login
cd $HOME
echo 'export PATH="$PATH:$HOME/.rvm/bin"' > .tmpbashrc
echo  '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> .tmpbashrc
cat .bashrc >> .tmpbashrc
cp .bashrc .bashrc.old
mv .tmpbashrc .bashrc

# Create the Bourreau
cd $HOME/cbrain/BrainPortal

echo $HOME | xargs -I {} echo 'RemoteResource.create :id => 2, :name => "LocalBourreau", :type => "Bourreau", :user_id => 1, :group_id => 1, :online => 1, :description => "Automatically Generated Local Bourreau", :ssh_control_host => "localhost", :ssh_control_port => 22, :ssh_control_rails_dir => "{}/cbrain/Bourreau", :tunnel_mysql_port => 3333, :tunnel_actres_port => 3334, :dp_cache_dir => "{}/BorCache", :workers_instances=> 3, :workers_chk_time => 5, :workers_log_to => "combined", :workers_verbose => 1, :read_only => 0, :portal_locked => 0, :cache_trust_expire => 2592000, :cms_class => "ScirUnix", :cms_shared_dir => "{}/BorWork", :docker_executable_name => "docker", :singularity_executable_name => "singularity"' | rails c >> $logFile
echo $USER | xargs -I {} echo 'p=RemoteResource.where("id=2").first; p.ssh_control_user = "{}"; p.save' | rails c >> $logFile
echo $timezone | xargs -I {} echo 'p=RemoteResource.where("id=2").first; p.time_zone = "{}"; p.save' | rails c >> $logFile
