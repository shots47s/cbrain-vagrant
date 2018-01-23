# cbrain-vagrant
This is a VagrantFile that will provision and create a CBRAIN instance using a base of ubuntu/xenial64.

Currently this vagrant image provides a CBRAIN installation to the point of bringing up a BrainPortal.  
Dataproviders and Borreaux must still be manually set up.

To use:
1. vagrant up (will provision)
1. at the end of the provision process, the temporary CBRAIN password will be displayed in the log
1. vagrant ssh
1. cd cbrain/BrainPortal
1. type 'rails server puma -b 0.0.0.0 -p 3000 -e development'
1. go to your local browser and type in the address '127.0.0.1:3000' and you should see the CBRAIN login page.


Note the VagrantFile is using the new plugin interface, if would like to change the resources allocated to the Vagrant, you can set the diskspace and memory requirements there, it is currently set to use 8GB of RAM and 20GB of disk space.
