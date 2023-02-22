# Installation for Debian 11

### Step 1 - Add user to sudo file
`sudo visudo`

`# User privilege specification`

`root    ALL=(ALL:ALL) ALL`

`user    ALL=(ALL:ALL) ALL`

### Step 2 - Install VirtualBox Guest Additions
`cd /mnt/`

`sudo sh VBoxLinuxAdditions.run`

### Step 3 - Download and Install OpenKAT
`wget https://github.com/minvws/nl-kat-coordination/releases/download/v1.5.2/kat-debian11-1.5.2.tar.gz && wget https://github.com/dekkers/xtdb-http-multinode/releases/download/v1.0.2/xtdb-http-multinode_1.0.2_all.deb && tar zvxf kat-*.tar.gz && sudo apt install --no-install-recommends ./kat-*_amd64.deb ./xtdb-http-multinode_*_all.deb -y`

### Step 4 - Setup Databases
`sudo apt-get install postgresql -y`

### Step 4.1 Generating Passwords
`export ROCKYDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)`

`export KATALOGUSDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)`

`export BYTESDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)`

`export RABBITMQ_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)`

### Step 4.2 Saving Passwords to passwords.txt
`echo ROCKYDB: $ROCKYDB_PASSWORD >> passwords.txt`

`echo KATALOGUSDB: $KATALOGUSDB_PASSWORD >> passwords.txt`

`echo BYTESDB: $BYTESDB_PASSWORD >> passwords.txt`

`echo RABBITMQ: $RABBITMQ_PASSWORD >> passwords.txt`

### Step 4.2 - RockyDB
`sudo -u postgres createdb rocky_db`

`echo "CREATE USER rocky WITH PASSWORD '$ROCKYDB_PASSWORD';" | sudo -u postgres psql`

`sudo -u postgres psql -c 'GRANT ALL ON DATABASE rocky_db TO rocky;'`

`sudo -u kat rocky-cli migrate`

`sudo -u kat rocky-cli loaddata /usr/share/kat-rocky/OOI_database_seed.json`

### Step 4.3 - KAT-alogusDB
`sudo -u postgres createdb katalogus_db`

`echo "CREATE USER katalogus WITH PASSWORD '$KATALOGUSDB_PASSWORD';" | sudo -u postgres psql`

`sudo -u postgres psql -c 'GRANT ALL ON DATABASE katalogus_db TO katalogus;'`

`sudo -u kat update-katalogus-db`
#### Remember updating /etc/kat/boefjes.conf with 

`KATALOGUS_DB_URI=postgresql://katalogus:<password>@localhost/katalogus_db`

### Step 4.4 - BytesDB
`sudo -u postgres createdb bytes_db`

`echo "CREATE USER bytes WITH PASSWORD '$BYTESDB_PASSWORD';" | sudo -u postgres psql`

`sudo -u postgres psql -c 'GRANT ALL ON DATABASE bytes_db TO bytes;'`

`sudo -u kat update-bytes-db`
#### Remember updating /etc/kat/bytes.conf with 

`BYTES_DB_URI=postgresql://bytes:<password>@localhost/bytes_db`

### Step 5 - Create Superuser
`sudo -u kat rocky-cli createsuperuser`

`sudo -u kat rocky-cli setup_dev_account`

### Step 6 - RabbitMQ-server
`sudo apt install rabbitmq-server -y`

`sudo systemctl stop rabbitmq-server`

`sudo epmd -kill`

`echo listeners.tcp.local = 127.0.0.1:5672 > /etc/rabbitmq/rabbitmq.conf`

`cat > /etc/rabbitmq/advanced.config << 'EOF'`
`    {kernel,[`
`        {inet_dist_use_interface,{127,0,0,1}}`
`    ]}`
`EOF`

`rabbitmqctl add_user kat ${RABBITMQ_PASSWORD}`

`rabbitmqctl add_vhost kat`

`rabbitmqctl set_permissions -p "kat" "kat" ".*" ".*" ".*"`

#### Remember to update /etc/kat/mula.conf with
`SCHEDULER_RABBITMQ_DSN=amqp://kat:<password>@localhost:5672/kat`

`SCHEDULER_DSP_BROKER_URL=amqp://kat:<password>@localhost:5672/kat`

# Update QUEUE_URI to rocky.conf bytes.conf boefjes.conf octopoes.conf
`sed -i "s|QUEUE_URI= *\$|QUEUE_URI=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/*.conf`

# Configure Bytes credentials in rocky.conf boefjes.conf mula.conf
`sed -i "s/BYTES_PASSWORD= *\$/BYTES_PASSWORD=$(grep BYTES_PASSWORD /etc/kat/bytes.conf | awk -F'=' '{ print $2 }')/" /etc/kat/*.conf`

# Restart KAT
`sudo systemctl restart kat-rocky kat-mula kat-bytes kat-boefjes kat-normalizers kat-katalogus kat-keiko kat-octopoes kat-octopoes-worker`

# Start at systemboot
`sudo systemctl enable kat-rocky kat-mula kat-bytes kat-boefjes kat-normalizers kat-katalogus kat-keiko kat-octopoes kat-octopoes-worker`