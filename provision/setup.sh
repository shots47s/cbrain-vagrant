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
\curl -sSL https://rvm.io/mpapis.asc | gpg --import - >> $logFile
\curl -sSL https://get.rvm.io | bash -s stable >> $logFile

source $HOME/.rvm/scripts/rvm >> $logFile

echo "Installing Ruby" > $logFile
echo "-----------------------------------------------" >> $logFile

rvm info >> $logFile
rvm install 2.4 >> $logFile
rvm --default 2.4 >> $logFile

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

## install singularity
singLog=/tmp/singularity.log

mkdir $HOME/singTemp; cd $HOME/singTemp
sudo apt-get install python dh-autoreconf build-essential -y > $singLog 
wget https://github.com/singularityware/singularity/releases/download/2.4.1/singularity-2.4.1.tar.gz >> $singLog
tar -xvzf singularity-2.4.1.tar.gz >> $singLog
cd singularity-2.4.1
./configure --prefix=/usr/local --sysconfdir=/etc >> $singLog
make >> $singLog
sudo make install >> $singLog

cd $HOME
rm -rf $HOME/singTemp

#### Set up the BrainPortal Cache and timezone
cd $HOME/cbrain/BrainPortal

echo $HOME | xargs -I {} echo 'p=RemoteResource.first; p.dp_cache_dir="{}/BorCache"; p.save' | rails c >> $logFile
timezone=`timedatectl status | grep 'Time zone' | awk '{print $3}'`
echo 'p=User.first; p.time_zone = "$timezone"; p.save' | rails c >> $logFile

### Setup local DataProvider

echo $HOME | xargs -I {} echo 'DataProvider.create :id => 2, :name => "LocalDP", :type => "FlatDirLocalDataProvider", :remote_dir => "{}/FlatLocalDP", :time_zone => $timezone, :description => "Automatically Generated Local Data Provider", :user_id => 1, :group_id => 1, :online => 1' | rails c >> $logFile

cat ~/.ssh/id_cbrain_portal.pub >> ~/.ssh/authorized_keys
echo $HOME | xargs -I {} echo 'DataProvider.create :id => 3, :name => "SshDP", :type => "FlatDirSshDataProvider", :remote_dir => "{}/SshDP", :time_zone => $timezone, :description => "Automatically Generated SSH Data Provider", :user_id => 1, :group_id => 1, :online => 1' | rails c >> $logFile
echo $USER | xargs -I {} echo 'd=DataProvider.where("id=3").first; d.remote_user = "{}"; d.remote_host = "localhost"; d.remote_port = 22; d.save' | rails c >> $logFile

echo $HOME | xargs -I {} echo 'DataProvider.create :id => 4, :name => "CbrainDP", :type => "EnCbrainSmartDataProvider", :remote_dir => "{}/CBLocalDP", :time_zone => $timezone, :description => "Automatically Generated Smart Data Provider", :user_id => 1, :group_id => 1, :online => 1' | rails c >> $logFile
echo $USER | xargs -I {} echo 'd=DataProvider.where("id=4").first; d.remote_user = "{}"; d.remote_host = "localhost"; d.remote_port = 22; d.save' | rails c >> $logFile

