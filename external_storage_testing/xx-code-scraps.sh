#!/usr/bin/env bash

# SSH login

user_name="ubuntu"
ip_address="13.236.52.8"
pem_file="/Users/s57405/.aws/minus34/postgres_testing.pem"

sudo chmod 400 ${pem_file}

ssh -i ${pem_file} ${user_name}@${ip_address}



# --------------------------------------------------------------------------------------
# Install Postgres & PostGIS, add a read only user and enables access to the database
#
# Input vars:
#   0 = postgres user password
#   1 = read-only user (rouser) password
#   2 = CIDP IP range(s) that can access the database server - space delimited
#
# --------------------------------------------------------------------------------------

# add repo
sudo add-apt-repository -y "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# install
sudo DEBIAN_FRONTEND=noninteractive apt -q -y update
sudo DEBIAN_FRONTEND=noninteractive apt -q -y install postgresql-11
sudo DEBIAN_FRONTEND=noninteractive apt -q -y install postgresql-11-postgis-2.5 postgresql-contrib-11
sudo DEBIAN_FRONTEND=noninteractive apt -q -y install postgis

# TO DO : add Postgres to PATH (for all users)
echo "PATH=$PATH:/usr/lib/postgresql/11/bin" | sudo tee --append /etc/environment
source /etc/environment

# alter postgres user and create database
sudo -u postgres psql -c "ALTER USER postgres ENCRYPTED PASSWORD 'password';"
#sudo -u postgres psql -c "CREATE EXTENSION adminpack;CREATE EXTENSION postgis;" postgres
sudo -u postgres psql -c "CREATE EXTENSION postgis;" postgres

# create read only user and grant access to all tables & sequences in public schema (to enable PostGIS use)
sudo -u postgres psql -c "CREATE USER rouser WITH ENCRYPTED PASSWORD 'password';" postgres
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE postgres TO rouser;" postgres
sudo -u postgres psql -c "GRANT USAGE ON SCHEMA public TO rouser;" postgres
sudo -u postgres psql -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO rouser;" postgres
sudo -u postgres psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public to rouser;" postgres  # for PostGIS coordinate systems
sudo -u postgres psql -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO rouser;" postgres  # for PostGIS functions

# allow external access to postgres
sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/11/main/postgresql.conf

echo -e "host\t postgres\t postgres\t 128.250.0.133\t md5" | sudo tee -a /etc/postgresql/11/main/pg_hba.conf


## whitelist postgres clients (if any)
#ip_ranges=({2})
#
#if [[ ${#ip_ranges[@]} -gt 0 ]]; then
#
#    # enable client IP range access for read-only user
#    for ip_range in ${ip_ranges[@]}; do
#        echo -e "host\t postgres\t rouser\t ${ip_range}\t md5" | sudo tee -a /etc/postgresql/11/main/pg_hba.conf
#    done
#fi

sudo service postgresql restart


# --------------------------------------------------------------------------------------
# copy dump files from s3
# --------------------------------------------------------------------------------------

