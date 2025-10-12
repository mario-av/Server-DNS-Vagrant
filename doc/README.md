# Server-DNS-Vagrant: BIND9 DNS Server Deployment 🌐

This project uses **Vagrant** to automatically provision a **BIND9 (named)** DNS server on a `debian/bullseye64` virtual machine. It establishes a local, private DNS zone (`izvdns.org`) for internal network resolution.

## Prerequisites

  - **[Vagrant](https://www.vagrantup.com/downloads)**: For creating and managing the VM.
  - **[VirtualBox](https://www.virtualbox.org/wiki/Downloads)**: The underlying virtualization provider.
  - **[Git](https://git-scm.com/downloads)**: For cloning the repository and version control.
  - **A Terminal or Command Prompt**.

-----

## 1\. Project Configuration and Setup

This section guides you through preparing the local environment and starting the server.

### 1.1. Clone and Navigate

1.  Clone the repository (replace `<repository_url>` with your actual URL):

    ```bash
    git clone <repository_url>
    ```
2.  Navigate to the project directory:

    ```bash
    cd Server-DNS-Vagrant
    ```

### 1.2. Server Settings Summary

The server is provisioned with the following network and DNS settings, defined in the `Vagrantfile` and configuration files:

| Setting | Value | Purpose |
| :--- | :--- | :--- |
| **VM Box** | `debian/bullseye64` | Base operating system. |
| **Domain** | `izvdns.org` | The local authoritative zone. |
| **Server IP** | **`192.168.2.1`** | Static private network address. |
| **Subnet** | `192.168.2.0/24` | Network range for DNS access control (ACL). |
| **Primary DNS** | `192.168.2.1` | The server itself. |
| **Forwarders** | `8.8.8.8` & `1.1.1.1` | Used to resolve external domain names. |

### 1.3. Deploy the Environment

Start the virtual machine. This command automatically executes the `bootstrap.sh` provisioning script to install and configure BIND9.

```bash
vagrant up
```

*(Insert Capture: `vagrant up` successful output)*

-----

## 2\. Verification and Troubleshooting

Once the VM is running, you must verify the BIND9 service status and the configuration files.

### 2.1. Access the VM

Connect to the server via SSH:

```bash
vagrant ssh
```

### 2.2. Verify BIND9 Service Status

Check if the `bind9` service is running and active:

```bash
sudo systemctl status bind9
```

*(Insert Capture: `sudo systemctl status bind9` showing "Active: active (running)")*

### 2.3. Check Zone Syntax

Verify that the DNS zone configuration files are syntactically correct using BIND's utility commands.

#### Direct Zone (`izvdns.org`)

```bash
sudo named-checkzone izvdns.org /etc/bind/db.izvdns.org
```

*(Expected Output: `zone izvdns.org/IN: loaded serial <number>` followed by `OK`)*

#### Reverse Zone (`2.168.192.in-addr.arpa`)

```bash
sudo named-checkzone 2.168.192.in-addr.arpa /etc/bind/db.2.168.192.in-addr.arpa
```

*(Expected Output: `zone 2.168.192.in-addr.arpa/IN: loaded serial <number>` followed by `OK`)*

*(Insert Capture: `named-checkzone` commands showing successful OK message)*

-----

## 3\. Testing DNS Resolution

Use `dig` (Domain Information Groper) to test the server's ability to resolve names both locally (authoritative zone) and externally (using forwarders).

### 3.1. Test Local Resolution (Authoritative Zone)

Test the direct and reverse resolution of the DNS server's own name and IP address, querying the local host loopback (`@127.0.0.1`).

#### Direct Query (`A` record)

```bash
dig @127.0.0.1 debian.izvdns.org
```

*(Expected Answer Section: `debian.izvdns.org. ... IN A 192.168.2.1`)*

#### Reverse Query (`PTR` record)

```bash
dig @127.0.0.1 -x 192.168.2.1
```

*(Expected Answer Section: `1.2.168.192.in-addr.arpa. ... IN PTR debian.izvdns.org.`)*

### 3.2. Test External Resolution (Forwarders)

Test resolution for an external domain name (e.g., `google.com`). This confirms that the forwarders (`8.8.8.8`, `1.1.1.1`) configured in `named.conf.options` are working.

```bash
dig google.com
```

*(Expected Answer Section: should show the current IP addresses for https://www.google.com/url?sa=E\&source=gmail\&q=google.com)*

*(Insert Capture: `dig` commands showing both successful local and external resolutions)*

-----

## 4\. Configuration Reference

The provisioning script copies the configuration files from the host's **`/config/config-files/etc/bind/`** directory to the VM's **`/etc/bind/`**.

| File | Purpose | Key Settings |
| :--- | :--- | :--- |
| **`named.conf.options`** | Global settings. | Defines the **`acl confiables`** (`192.168.2.0/24`), **`listen-on`** (`192.168.2.1`), **`allow-recursion`**, and **`forwarders`**. |
| **`named.conf.local`** | Zone declarations. | Declares the **`izvdns.org`** zone (master) and the **`2.168.192.in-addr.arpa`** reverse zone. |
| **`db.izvdns.org`** | Direct zone file. | Contains the **SOA**, **NS**, and **A** record for `debian.izvdns.org` (`192.168.2.1`). |
| **`db.2.168.192.in-addr.arpa`** | Reverse zone file. | Contains the **SOA**, **NS**, and **PTR** record mapping `1` to `debian.izvdns.org`. |

-----

## 5\. Maintenance and Customization

### 5.1. Modify Settings

To change the domain or IP addresses:

1.  Edit the relevant files located in the host's configuration path (`/config/config-files/etc/bind/`).
2.  Update the `Serial` number in both zone files (`db.izvdns.org` and `db.2.168.192.in-addr.arpa`).
3.  Run the provisioning command again to apply changes:

    ```bash
    vagrant provision
    ```

### 5.2. Restart BIND9 Manually

If you only modify configuration files directly within the VM via SSH, you must restart the service to load the new settings:

```bash
sudo systemctl restart bind9
```

---

## 6. DNS Server FAQ – Common Questions and Issues

### 6.1. What happens if a client from a different network tries to use your DNS server?

It won’t work. In `named.conf.options`, recursion is restricted to the ACL **`confiables`**, which only includes the network `192.168.2.0/24`:

```bash
allow-recursion { confiables; };
```

Clients outside this subnet cannot make recursive queries.

---

### 6.2. Why do we need to allow recursive queries?

Recursive queries allow the DNS server to fully resolve domain names on behalf of clients.
Without recursion, the server can only answer for zones it is authoritative for or provide referrals to other servers.

---

### 6.3. Is the DNS server authoritative? Why?

✅ Yes. It is authoritative for the configured zones (`izvdns.org` and `2.168.192.in-addr.arpa`) because in `named.conf.local` the zones are defined as:

```bash
type master;
```

This makes the server the official source of information for those zones.

---

### 6.4. Where can we find the `$ORIGIN` directive and what is it used for?

The `$ORIGIN` directive is found in **zone files** (e.g., `db.izvdns.org`).
It defines the **base domain name** for relative records in the file.
If not set, it defaults to the zone name declared in `named.conf.local`.

---

### 6.5. Is a zone the same as a domain?

Not exactly.

* A **domain** is the complete namespace (e.g., `izvdns.org`).
* A **zone** is the part of the domain managed by a particular DNS server.
  A domain can consist of multiple zones.

---

### 6.6. How many root servers exist?

There are **13 main root servers**, named **A to M** (e.g., `a.root-servers.net`).
Through anycast, there are actually **over 1,000 physical instances worldwide**.

---

### 6.7. What is an iterative referral query?

An iterative referral query occurs when a DNS server does **not fully resolve a name** but instead returns a **referral** to another server closer to the answer.
The client or resolver continues the query until it reaches the authoritative server.

---

### 6.8. In a reverse lookup, what name would the IP `172.16.34.56` map to?

It would map to:

```
56.34.16.172.in-addr.arpa
```

This is used in **reverse DNS zones** to map IP addresses to hostnames.

---


## 7 Additional Common Issues 


### 7.9. Why am I getting “SERVFAIL” when querying my DNS?

This often happens due to **syntax errors** in the zone files or `named.conf` files.
Check logs with:

```bash
sudo journalctl -u bind9
```

and test zones with:

```bash
named-checkzone izvdns.org /var/lib/bind/db.izvdns.org
named-checkconf
```

---

### 7.10. Why does `nslookup` or `dig` time out when querying my server?

Possible causes:

* Firewall blocking **UDP/TCP port 53**
* Server listening only on specific IPs (`listen-on { 192.168.2.1; };`)
  Check network access and firewall rules.

---

### 7.11. Why are reverse lookups failing?

Common reasons:

* Reverse zone not correctly configured in `named.conf.local`
* PTR records missing or pointing to wrong hostnames
* Ensure the reverse zone matches the network (e.g., `2.168.192.in-addr.arpa` for `192.168.2.0/24`)

---

### 7.12. Why aren’t changes in zone files reflected immediately?

BIND caches zone data. After editing a zone, either:

* Increment the **SOA serial number**
* Reload the zone:

```bash
sudo rndc reload izvdns.org
```

---

### 7.13. Why do I get “REFUSED” when querying my DNS from another network?

This is due to **ACL restrictions**. Only IPs in the `confiables` ACL can perform recursive queries.
Check `allow-recursion` and `allow-query` settings in `named.conf.options`.

---
