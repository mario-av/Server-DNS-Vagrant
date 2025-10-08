# Server-DNS-Vagrant

This project uses Vagrant to provision a DNS server with BIND9 on a `debian/bullseye64` virtual machine.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Git](https://git-scm.com/downloads)
- A terminal or command prompt

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone
   ```

2. Navigate to the project directory:
   ```bash
   cd Server-DNS-Vagrant
   ```

3. Start the Vagrant environment:
   ```bash
   vagrant up
   ```

4. SSH into the virtual machine:
   ```bash  
   vagrant ssh
   ```

5. Verify BIND9 installation:
   ```bash
   sudo systemctl status bind9
   ```

## Configuration
- The DNS server is provisioned with the following settings:

  - Domain: `izvdns.org` (example domain; to use your own domain, edit `/config/config-files/etc/bind/named.conf.local` and zone files in `/config/config-files/etc/bind/`, replacing all instances of `izvdns.org` with your actual domain name)
  - IP Address: `192.168.2.1`
  - Subnet: `192.168.2.0/24`
  - Gateway: `192.168.2.254`
  - Primary DNS: `192.168.2.1`
  - Extra DNS Forwarders:
    - `8.8.8.8`
    - `1.1.1.1`

- Zone files are located in `/config/config-files/etc/bind/` on the repository and are copied to `/etc/bind/` in the VM.

- Configuration files are located in `/config/config-files/etc/bind/named.conf.options` and `/config/config-files/etc/bind/named.conf.local` on the repository.

- You can modify these files to customize your DNS server settings.

- After making changes, restart BIND9:
  ```bash
  sudo systemctl restart bind9
  ```

