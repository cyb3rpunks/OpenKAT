# Installation for Debian 11 
##### (https://docs.openkat.nl/technical_design/debianinstall.html)

### Step 1 - Add user to sudo file
<pre>
sudo visudo

# User privilege specification
root    ALL=(ALL:ALL) ALL
user    ALL=(ALL:ALL) ALL
</pre>

### Step 2 - Install VirtualBox Guest Additions
<pre>
cd /media/cdrom
sudo sh VBoxLinuxAdditions.run
sudo reboot
</pre>

### Step 3 - Download and Install OpenKAT
<pre>
wget https://github.com/minvws/nl-kat-coordination/releases/download/v1.5.2/kat-debian11-1.5.2.tar.gz && wget https://github.com/dekkers/xtdb-http-multinode/releases/download/v1.0.2/xtdb-http-multinode_1.0.2_all.deb && tar zvxf kat-*.tar.gz && sudo apt install --no-install-recommends ./kat-*_amd64.deb ./xtdb-http-multinode_*_all.deb -y
</pre>

### Step 4 - Setup Databases


#### Troubleshooting
<pre>
sudo apt-get --purge remove postgresql -y
sudo apt-get purge postgresql* -y
sudo apt-get --purge remove postgresql postgresql-doc postgresql-common -y
sudo rm -rf /var/lib/postgresql/ 
sudo rm -rf /var/log/postgresql/ 
sudo rm -rf /etc/postgresql/ 
sudo apt-get install postgresql -y
</pre>

sudo -u postgres psql -c " SELECT rolname, rolpassword FROM pg_authid;"





<pre>
sudo apt-get install postgresql -y
</pre>

### Step 4.1 - Generating Passwords
<pre>
ROCKYDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export ROCKYDB_PASSWORD=$ROCKYDB_PASSWORD
KATALOGUSDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export KATALOGUSDB_PASSWORD=$KATALOGUSDB_PASSWORD
BYTESDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export BYTESDB_PASSWORD=$BYTESDB_PASSWORD
RABBITMQ_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD
</pre>

### Step 4.2 - Saving Passwords to passwords.txt
<pre>
echo ROCKYDB: $ROCKYDB_PASSWORD >> passwords.txt
echo KATALOGUSDB: $KATALOGUSDB_PASSWORD >> passwords.txt
echo BYTESDB: $BYTESDB_PASSWORD >> passwords.txt
echo RABBITMQ: $RABBITMQ_PASSWORD >> passwords.txt
</pre>

### Step 4.3 - RockyDB
<pre>
sudo -u postgres createdb rocky_db
sudo -u postgres psql -c "CREATE USER rocky WITH PASSWORD '${ROCKYDB_PASSWORD}';"
sudo -u postgres psql -c 'GRANT ALL ON DATABASE rocky_db TO rocky;'
</pre>

### Step 4.4 - KAT-alogusDB
<pre>
sudo -u postgres createdb katalogus_db
sudo -u postgres psql -c "CREATE USER katalogus WITH PASSWORD '${KATALOGUSDB_PASSWORD}';"
sudo -u postgres psql -c 'GRANT ALL ON DATABASE katalogus_db TO katalogus;'
</pre>

### Step 4.5 - BytesDB
<pre>
sudo -u postgres createdb bytes_db
sudo -u postgres psql -c "CREATE USER bytes WITH PASSWORD '${BYTESDB_PASSWORD}';"
sudo -u postgres psql -c 'GRANT ALL ON DATABASE bytes_db TO bytes;'
</pre>

### Step 4.6 - Update configs'
#### Update ROCKY_DB_PASSWORD in /etc/kat/rocky.conf
<pre>
sudo sed -i "s|ROCKY_DB_PASSWORD= *\$|ROCKY_DB_PASSWORD=${ROCKYDB_PASSWORD}|" /etc/kat/rocky.conf
</pre>

#### Update BYTES_DB_URI in /etc/kat/bytes.conf
<pre>
sudo sed -i "s|BYTES_DB_URI= *\$|BYTES_DB_URI=postgresql://bytes:${BYTESDB_PASSWORD}@localhost/bytes_db|" /etc/kat/bytes.conf
</pre>
#### Update KATALOGUS_DB_URI in /etc/kat/boefjes.conf
<pre>
sudo sed -i "s|KATALOGUS_DB_URI= *\$|postgresql://katalogus:${KATALOGUSDB_PASSWORD}@localhost/katalogus_db|" /etc/kat/boefjes.conf
</pre>
##### Update SCHEDULER_DSP_BROKER_URL in /etc/kat/mula.conf
<pre>
sudo sed -i "s|SCHEDULER_DSP_BROKER_URL= *\$|SCHEDULER_DSP_BROKER_URL=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/mula.conf
</pre>
##### Update SCHEDULER_RABBITMQ_DSN in /etc/kat/mula.conf 
<pre>
sudo sed -i "s|SCHEDULER_RABBITMQ_DSN= *\$|SCHEDULER_RABBITMQ_DSN=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/mula.conf
</pre>
#### Update QUEUE_URI in rocky.conf bytes.conf, boefjes.conf, octopoes.conf
<pre>
su -c 'sed -i "s|QUEUE_URI= *\$|QUEUE_URI=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/*.conf'
</pre>
#### Update Bytes credentials in rocky.conf, boefjes.conf, mula.conf
<pre>
su -c 'sed -i "s|BYTES_PASSWORD= *\$|BYTES_PASSWORD=${BYTESDB_PASSWORD}|" /etc/kat/rocky.conf'
su -c 'sed -i "s|BYTES_PASSWORD= *\$|BYTES_PASSWORD=${BYTESDB_PASSWORD}|" /etc/kat/boefjes.conf'
su -c 'sed -i "s|BYTES_PASSWORD= *\$|BYTES_PASSWORD=${BYTESDB_PASSWORD}|" /etc/kat/mula.conf'
</pre>

### Step 4.7 - Initialize Databases
<pre>
sudo -u kat rocky-cli migrate
sudo -u kat rocky-cli loaddata /usr/share/kat-rocky/OOI_database_seed.json
sudo -u kat update-bytes-db
sudo -u kat update-katalogus-db
</pre>

### Step 5 - Create Superuser
<pre>
sudo -u kat rocky-cli createsuperuser
sudo -u kat rocky-cli setup_dev_account
</pre>

### Step 6 - RabbitMQ-server
<pre>
sudo apt install rabbitmq-server -y
sudo systemctl stop rabbitmq-server
sudo epmd -kill
echo listeners.tcp.local = 127.0.0.1:5672 > /etc/rabbitmq/rabbitmq.conf
cat > /etc/rabbitmq/advanced.config << 'EOF'
    {kernel,[
        {inet_dist_use_interface,{127,0,0,1}}
    ]}
EOF

sudo /usr/lib/rabbitmq/bin/rabbitmqctl add_user kat ${RABBITMQ_PASSWORD}
sudo /usr/lib/rabbitmq/bin/rabbitmqctl add_vhost kat
sudo /usr/lib/rabbitmq/bin/rabbitmqctl set_permissions -p "kat" "kat" ".*" ".*" ".*"
</pre>

#### Start at systemboot
<pre>
sudo systemctl enable kat-rocky kat-mula kat-bytes kat-boefjes kat-normalizers kat-katalogus kat-keiko kat-octopoes kat-octopoes-worker
</pre>
#### Restart KAT
<pre>
sudo systemctl restart kat-rocky kat-mula kat-bytes kat-boefjes kat-normalizers kat-katalogus kat-keiko kat-octopoes kat-octopoes-worker
</pre>
