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

source /home/ubuntu/.rvm/scripts/rvm >> $logFile

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

gem install bundler > $logFile
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
rake db:sanity:check RAILS_ENV=development

cd $HOME/cbrain/BrainPortal
rake cbrain:plugins:install:all

cd $HOME/cbrain/Bourreau
rake cbrain:plugins:install:all

mkdir $HOME/BPCache
