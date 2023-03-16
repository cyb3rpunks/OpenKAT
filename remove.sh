### Step 0 - Remove Old installations (Beta)

#### Delete old installation files
sudo rm -rf *

#### Delete Postgresql
sudo apt-get --purge remove postgresql -y
sudo apt-get --remove purge kat -y
sudo apt-get purge postgresql* -y
sudo apt-get remove kat* -y
sudo apt-get purge rabbitmq* -y
sudo apt-get --purge remove postgresql postgresql-doc postgresql-common -y
sudo rm -rf /var/lib/postgresql/ 
sudo rm -rf /var/log/postgresql/ 
sudo rm -rf /etc/postgresql/ 

#### Delete OpenKAT
sudo apt-get remove --purge $(dpkg -l | grep -i kat | awk '{print $2}') -y