#!/bin/bash

# --- CONFIGURATION VARIABLES ---
IP_SERVER="192.168.2.1"
SUBNET_OCTET="2"          # Third octet for the reverse zone: 2.168.192.in-addr.arpa
LAST_OCTET="1"            # Last octet of the server for PTR record
DOMAIN="izvdns.org"       # Practice domain

echo "--- 3. DNS Server Installation ---"

# Update and install BIND9, utilities, and documentation
apt-get update
apt-get install -y bind9 bind9utils bind9-doc

echo "--- 4. Server Configuration (IPv4) ---"

# 4. Modify /etc/default/named to use only IPv4
echo "OPTIONS=\"-u bind -4\"" > /etc/default/named

echo "--- 4.1-4.4. Copying and applying zone configurations ---"

# Copy configuration and zone files from the shared folder /vagrant/config/
cp /vagrant/config/named.conf.options /etc/bind/named.conf.options
cp /vagrant/config/named.conf.local /etc/bind/named.conf.local

# Copy zone files and set necessary permissions
cp /vagrant/config/db.${DOMAIN} /var/lib/bind/
cp /vagrant/config/db.${SUBNET_OCTET}.rev /var/lib/bind/
chown bind:bind /var/lib/bind/db.${DOMAIN}
chown bind:bind /var/lib/bind/db.${SUBNET_OCTET}.rev

echo "--- 4.5. Checking and restarting BIND9 ---"

# Syntax check before restarting
named-checkconf /etc/bind/named.conf.options
named-checkconf /etc/bind/named.conf.local

# Restart the service to apply changes
systemctl restart bind9
systemctl status bind9