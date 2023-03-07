# OpenKAT Installation on Debian 11 
##### (https://docs.openkat.nl/technical_design/debianinstall.html)

Please run the commands in 

### Step 1 - Add user to sudo file
<pre>
## Login as root
su 
sudo visudo

## add the user like below

# User privilege specification
root    ALL=(ALL:ALL) ALL
user    ALL=(ALL:ALL) ALL
</pre>

### Step 2 - Install VirtualBox Guest Additions
# Open file explorer and open the cddrive
<pre>
## Goto Devices in Virtualbox and Insert Guest Additions
## Click in FileExplorer on the DiskDrive to initiate the disk and run following commands

cd /media/cdrom
sudo sh VBoxLinuxAdditions.run
sudo reboot
</pre>

### Step 3 - Run the unattend.sh 
<pre>
## You can also copy the file contents and paste it in to the terminal
</pre>