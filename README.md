# Setting Up Samba as an Active Directory (AD) Domain Controller

Using Samba as an Active Directory (AD) Domain Controller (DC) is a robust approach that allows users to log in with their domain credentials. Their profiles, settings, and files will be dynamically retrieved when they log in to Windows or Linux.

## Overview of Active Directory-Based Setup

### Samba AD Domain Controller
- Users authenticate with their domain credentials.
- Profiles are stored centrally and retrieved on login.
- Group policies (GPOs) can enforce security settings.

### Windows/Linux Clients Join the Domain
- Users can log in from any computer in the lab.
- Their Desktop, Documents, and other settings stay consistent.

---
## Step-by-Step Implementation

### Step 1: Prepare the Samba Server

#### Install Samba and Required Packages
On your Linux server (Ubuntu/Debian example):
```sh
sudo apt update
sudo apt install samba krb5-user winbind libnss-winbind libpam-winbind samba-dsdb-modules acl attr samba-vfs-modules smbclient winbind libpam-winbind libnss-winbind libpam-krb5 krb5-config krb5-user dnsutils chrony net-tools
```

During installation, enter the appropriate Kerberos configuration:
```
Default Kerberos Verion 5 Realm: HOMEPI.LOCAL
Kerberos Servers for your realm: ad-serv.homepi.local
Administrative server for your Kerberos realm: ad-serv.homepi.local
```

#### Set the Server Hostname
```sh
hostnamectl set-hostname ad-nexus.test.local
```

#### Modify the Hosts File
Add the following line to `/etc/hosts`:
```
127.0.0.1 ad-serv.homepi.local  ad-serv
192.168.0.220 ad-serv.homepi.local
```

#### Verify Hostname
```sh
hostname -f
ping -c3 ad-serv.homepi.local
```

---
### Step 2: Configure DNS Resolver

#### Disable the DNS Resolver
```sh
sudo systemctl disable --now systemd-resolved
sudo unlink /etc/resolv.conf
```

#### Configure `/etc/resolv.conf`
```sh
sudo nano /etc/resolv.conf
```
Add the following:
```
nameserver 192.168.0.220
nameserver 9.9.9.9
search homepi.local
```
Lock the file to prevent changes:
```sh
chattr +i /etc/resolv.conf
```

---
### Step 3: Provision Samba as an AD Domain Controller

#### Stop Existing Samba Services
```sh
sudo systemctl stop smbd nmbd winbind
sudo systemctl disable smbd nmbd winbind
```

#### Modify Kerberos Configuration
```sh
nano /etc/krb5.conf
```
Add the following:
```
[libdefaults]
    default_realm = HOMEPI.LOCAL
    kdc_timesync = 1
    ccache_type = 4
    forwardable = true
    proxiable = true
    rdns = false
    dns_lookup_realm = false
    dns_lookup_kdc = true

[domain_realm]
    .homepi.local = AD-SERV.HOMEPI.LOCAL
```

#### Provision the Domain Controller
```sh
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
rm /etc/samba/smb.conf
sudo samba-tool domain provision --use-rfc2307 --interactive
```
During setup, enter:
```
Realm: HOMEPI.LOCAL
Domain: HOMEPI
Server Role: DC
DNS backend: SAMBA_INTERNAL
Set a strong password (e.g., P@ssw0rd)
```

#### Start Samba AD DC
```sh
sudo systemctl unmask samba-ad-dc
sudo systemctl enable samba-ad-dc
sudo systemctl start samba-ad-dc
sudo systemctl status samba-ad-dc
```

---
### Step 4: Configure Time Synchronization

#### Set Permissions
```sh
sudo chown root:_chrony /var/lib/samba/ntp_signd/
sudo chmod 750 /var/lib/samba/ntp_signd/
```

#### Update Chrony Configuration
```sh
sudo nano /etc/chrony/chrony.conf
```
Add the following:
```
bindcmdaddress 192.168.0.220
allow 192.168.0.0/24
ntpsigndsocket /var/lib/samba/ntp_signd
```
Reload configuration:
```sh
sudo systemctl daemon-reload
timedatectl set-timezone "Asia/Colombo"
sudo systemctl restart chrony.service
```

---
### Step 5: Verify AD Setup

#### Verify DNS Records
```sh
host -t SRV _kerberos._udp.homepi.local
host -t SRV _ldap._tcp.homepi.local
```

#### Verify Administrator Account
```sh
samba-tool user show Administrator
```

---
### Step 6: Create Users and Groups

#### Create User Groups
```sh
samba-tool group addunixattrs Administrators 1000
samba-tool group addunixattrs 'Domain Admins' 1001
samba-tool group addunixattrs 'Schema Admins' 1002
samba-tool group addunixattrs 'Enterprise Admins' 1003
samba-tool group addunixattrs 'Group Policy Creator Owners' 1004
samba-tool group create students
samba-tool group addunixattrs 'students' 1005
samba-tool group addunixattrs 'Domain Users' 1006
```

#### Create Users
```sh
samba-tool user add 2020CSC052 P@ssw0rd
samba-tool user addunixattrs 2020CSC052 20052 --gid-number=1006,1005
samba-tool user add 2020CSC051 P@ssw0rd
```

#### Add Users to Groups
```sh
samba-tool group addmembers 1005 2020CSC052
```

---
### Step 7: Configure User Profiles

Modify Samba configuration:
```sh
nano /etc/samba/smb.conf
```
Add:
```
[profiles]
    path = /srv/samba/profiles
    read only = no
    store dos attributes = yes
    browseable = yes
    create mask = 0600
    directory mask = 0700
    csc policy = disable
```

#### Verify Samba DNS Query
```sh
samba-tool dns query 127.0.0.1 homepi.local @ ALL
```

#### Test Authentication
```sh
kinit Administrator
klist
```

---
## Conclusion
This guide walks through setting up Samba as an Active Directory Domain Controller. With proper user and group configurations, centralized authentication, and profile management, users can log in seamlessly across Windows and Linux machines.
