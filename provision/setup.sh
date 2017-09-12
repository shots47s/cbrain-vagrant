#!/bin/bash

sudo apt-get install mariadb-server -y > /dev/null

sqlscript="/tmp/tmp.sql"

touch $sqlscript
echo "CREATE USER 'cbrain'@'localhost' IDENTIFIED BY 'CBRAIN';" >> $sqlscript
echo "CREATE DATABASE cbrain_db CHARACTER SET 'utf8';" >> $sqlscript
echo "GRANT ALL ON cbrain_db.* TO 'cbrain'@'localhost';" >> $sqlscript
echo "FLUSH PRIVILEGES;" >> $sqlscript

cat $sqlscript | sudo mysql -u root

### Installing Ruby Version Manager

cd $HOME
\curl -sSL https://rvm.io/mpapis.asc | gpg --import -
\curl -sSL https://get.rvm.io | bash -s stable

source /home/ubuntu/.rvm/scripts/rvm

rvm info > out.info
rvm install 2.2
rvm --default 2.2

## Get CBRAIN Code

cd $HOME
git clone https://github.com/aces/cbrain.git

### Make sure we have all of the requirements

sudo apt-get install libmysqlclient-dev -y > /dev/null
sudo apt-get install libxml2 libxml2-dev -y > /dev/null
sudo apt-get install libxslt1.1 -y > /dev/null


## create database.yml file

cd $HOME/cbrain/BrainPortal/config
sed 's/cbrain_db_name_here/cbrain_db/g' database.yml.TEMPLATE | sed 's/cbrain_db_user_name_here/cbrain/g' | sed 's/cbrain_db_user_pw_here/CBRAIN/g' > database.yml

## install bundler

gem install bundler
cd $HOME/cbrain/BrainPortal; bundle install
cd $HOME/cbrain/Bourreau; bundle install

cd `bundle show sys-proctable`; rake install; cd $HOME

