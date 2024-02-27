# cbrain-vagrant
This is a VagrantFile that will provision and create a CBRAIN instance using a base of Ubuntu 22.04

The Vagrant provisions an image to provide you with the following components:
1. An admin account which you will be asked to change the password on upon first instantiation.
1. A Brain Portal that is called CBRAINVagrant
1. Three Data Providers: A CBRAIN Enhannced DP, a SSH DP, and a Local DP.
1. A Bourreau in which you can run tools inside the virtual machine.

To use:
1. vagrant up (will provision)
1. at the end of the provision process, the temporary CBRAIN password will be displayed in the log
1. Currently rvm is installed in a direct way. The method of rvm install with rsa key is commented out, it might need several attempts or/and some troubleshooting. You may uncomment it, if you like, on your own risk, but no support is provided
1. vagrant ssh
1. cd cbrain/BrainPortal
1. type 'rails server puma -b 0.0.0.0 -p 3000 -e development'
1. go to your local browser and type in the address '127.0.0.1:3000' and you should see the CBRAIN login page.

Note the VagrantFile is using the new plugin interface, if would like to change the resources allocated to the Vagrant, you can set the diskspace and memory requirements 
