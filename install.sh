#!/bin/bash

# Installation for Debian 11 
##### (https://docs.openkat.nl/technical_design/debianinstall.html)

# Step 1 - Get latest prerelease of OpenKAT

# The URL of the xtdb-http-multinode GitHub releases page
xtdb_url='https://github.com/dekkers/xtdb-http-multinode/releases'

# The URL of the nl-kat-coordination GitHub releases page
nl_kat_url='https://github.com/minvws/nl-kat-coordination/releases'

### Step 2 - Dowmload OpenKAT and Postgresql

# Get the latest version of xtdb-http-multinode
xtdb_content=$(curl -s $xtdb_url)
xtdb_version=$(echo $xtdb_content | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//' | head -n 1)

# Get the latest version of nl-kat-coordination
nl_kat_content=$(curl -s $nl_kat_url)
nl_kat_version=$(echo $nl_kat_content | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+rc[0-9]+' | sed 's/v//' | head -n 1)

# Download the latest version of xtdb-http-multinode
echo "Downloading xtdb-http-multinode version $xtdb_version..."
curl -LO "https://github.com/dekkers/xtdb-http-multinode/releases/download/v${xtdb_version}/xtdb-http-multinode_${xtdb_version}_all.deb"

# Download the latest version of nl-kat-coordination
echo "Downloading nl-kat-coordination version $nl_kat_version..."
curl -LO "https://github.com/minvws/nl-kat-coordination/releases/download/v${nl_kat_version}/kat-debian11-${nl_kat_version}.tar.gz"

### Step 3 - Install OpenKAT and Postgresql
sudo tar zvxf kat-*.tar.gz 
sudo apt install --no-install-recommends ./kat-*_amd64.deb ./xtdb-http-multinode_*_all.deb -y

### Step 4 - Setup Databases
sudo apt-get install postgresql -y

### Step 4.1 - Generating Passwords
ROCKYDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export ROCKYDB_PASSWORD
KATALOGUSDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export KATALOGUSDB_PASSWORD
BYTESDB_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export BYTESDB_PASSWORD
RABBITMQ_PASSWORD=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
export RABBITMQ_PASSWORD

### Step 4.2 - Saving Passwords to passwords.txt
echo "ROCKYDB_PASSWORD=${ROCKYDB_PASSWORD}" > passwords.txt
echo "KATALOGUSDB_PASSWORD=${KATALOGUSDB_PASSWORD}" >> passwords.txt
echo "BYTESDB_PASSWORD=${BYTESDB_PASSWORD}" >> passwords.txt
echo "RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}" >> passwords.txt
source /home/user/passwords.txt

### Step 4.3 - RockyDB
sudo -u postgres createdb rocky_db
sudo -u postgres psql -c "CREATE USER rocky WITH PASSWORD '${ROCKYDB_PASSWORD}';"
sudo -u postgres psql -c 'GRANT ALL ON DATABASE rocky_db TO rocky;'

### Step 4.4 - KAT-alogusDB
sudo -u postgres createdb katalogus_db
sudo -u postgres psql -c "CREATE USER katalogus WITH PASSWORD '${KATALOGUSDB_PASSWORD}';"
sudo -u postgres psql -c 'GRANT ALL ON DATABASE katalogus_db TO katalogus;'

### Step 4.5 - BytesDB
sudo -u postgres createdb bytes_db
sudo -u postgres psql -c "CREATE USER bytes WITH PASSWORD '${BYTESDB_PASSWORD}';"
sudo -u postgres psql -c 'GRANT ALL ON DATABASE bytes_db TO bytes;'

### Step 4.6 - Update configs'
#### Update ROCKY_DB_PASSWORD in /etc/kat/rocky.conf
sudo sed -i "s|ROCKY_DB_PASSWORD= *\$|ROCKY_DB_PASSWORD=${ROCKYDB_PASSWORD}|" /etc/kat/rocky.conf
sudo sed -i "/BYTES_PASSWORD=/s/.*/BYTES_PASSWORD=${BYTESDB_PASSWORD}/" /etc/kat/bytes.conf

#### Update BYTES_DB_URI in /etc/kat/bytes.conf
sudo sed -i "s|BYTES_DB_URI= *\$|BYTES_DB_URI=postgresql://bytes:${BYTESDB_PASSWORD}@localhost/bytes_db|" /etc/kat/bytes.conf

#### Update KATALOGUS_DB_URI in /etc/kat/boefjes.conf
sudo sed -i "s|KATALOGUS_DB_URI= *\$|KATALOGUS_DB_URI=postgresql://katalogus:${KATALOGUSDB_PASSWORD}@localhost/katalogus_db|" /etc/kat/boefjes.conf

##### Update SCHEDULER_DSP_BROKER_URL in /etc/kat/mula.conf
sudo sed -i "s|SCHEDULER_DSP_BROKER_URL= *\$|SCHEDULER_DSP_BROKER_URL=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/mula.conf

##### Update SCHEDULER_RABBITMQ_DSN in /etc/kat/mula.conf 
sudo sed -i "s|SCHEDULER_RABBITMQ_DSN= *\$|SCHEDULER_RABBITMQ_DSN=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/mula.conf

#### Update QUEUE_URI in rocky.conf bytes.conf, boefjes.conf, octopoes.conf
sudo '/home/user/passwords.txt'
sudo sed -i "s|QUEUE_URI= *\$|QUEUE_URI=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/rocky.conf 
sudo sed -i "s|QUEUE_URI= *\$|QUEUE_URI=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/bytes.conf
sudo sed -i "s|QUEUE_URI= *\$|QUEUE_URI=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/boefjes.conf
sudo sed -i "s|QUEUE_URI= *\$|QUEUE_URI=amqp://kat:${RABBITMQ_PASSWORD}@localhost:5672/kat|" /etc/kat/octopoes.conf

#### Update BYTES_PASSWORD in rocky.conf, boefjes.conf, mula.conf
sudo sed -i "s|BYTES_PASSWORD= *\$|BYTES_PASSWORD=${BYTESDB_PASSWORD}|" /etc/kat/rocky.conf
sudo sed -i "s|BYTES_PASSWORD= *\$|BYTES_PASSWORD=${BYTESDB_PASSWORD}|" /etc/kat/boefjes.conf
sudo sed -i "s|BYTES_PASSWORD= *\$|BYTES_PASSWORD=${BYTESDB_PASSWORD}|" /etc/kat/mula.conf

### Step 4.7 - Initialize Databases
sudo -u kat rocky-cli migrate
sudo -u kat rocky-cli loaddata /usr/share/kat-rocky/OOI_database_seed.json
sudo -u kat update-bytes-db
sudo -u kat update-katalogus-db

### Step 5 - Create Superuser
sudo -u kat rocky-cli createsuperuser
sudo -u kat rocky-cli setup_dev_account

### Step 6 - RabbitMQ-server
sudo apt install rabbitmq-server -y
sudo systemctl stop rabbitmq-server
sudo epmd -kill
su -c "echo listeners.tcp.local = 127.0.0.1:5672 > /etc/rabbitmq/rabbitmq.conf"
su -c "echo export ERL_EPMD_ADDRESS=127.0.0.1 > /etc/rabbitmq/rabbitmq-env.conf"
su -c "echo export NODENAME=rabbit@localhost >> /etc/rabbitmq/rabbitmq-env.conf"
su -c "sudo cat > /etc/rabbitmq/advanced.conf << 'EOF'
[
    {kernel,[
        {inet_dist_use_interface,{127,0,0,1}}
    ]}
].    
EOF"

sudo systemctl restart rabbitmq-server
source '/home/user/passwords.txt'
cd /usr/lib/rabbitmq/bin/rabbitmqctl
sudo rabbitmqctl add_user kat ${RABBITMQ_PASSWORD}
sudo rabbitmqctl add_vhost kat
sudo rabbitmqctl set_permissions -p "kat" "kat" ".*" ".*" ".*"
cd ~
#### Start at systemboot
sudo systemctl enable kat-rocky kat-mula kat-bytes kat-boefjes kat-normalizers kat-katalogus kat-keiko kat-octopoes kat-octopoes-worker

#### Restart KAT
sudo systemctl restart kat-rocky kat-mula kat-bytes kat-boefjes kat-normalizers kat-katalogus kat-keiko kat-octopoes kat-octopoes-worker

