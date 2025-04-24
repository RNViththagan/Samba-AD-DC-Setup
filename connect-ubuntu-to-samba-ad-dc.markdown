# Connect Ubuntu to Samba Active Directory Domain Controller

This guide explains how to test connectivity, join an Ubuntu host (20.04 or 24.04) to a Samba Active Directory (AD) Domain Controller (DC) for the domain `homepi.local` (running on `ad-serv.homepi.local`, IP: `192.168.0.220`), and log in as a domain user (e.g., `HOMEPI\Administrator`). It enables centralized authentication for Ubuntu hosts, similar to Windows 10/11 Pro clients.

## Prerequisites
- **Ubuntu**: 20.04 or 24.04 (Desktop or Server).
- **Network**: Same network as the Samba server (e.g., `192.168.0.x`).
- **Samba Server**: Running AD DC (`homepi.local`).
- **Credentials**: Samba AD Administrator (`HOMEPI\Administrator` and password).
- **Privileges**: User with `sudo` access.
- **Internet**: For package installation.

## Step 1: Test Connectivity
1. Open a terminal (Ctrl+Alt+T or SSH).
2. Test connection to the Samba server:
   ```bash
   ping -c 4 192.168.0.220
   ```
   - **Success**: Shows replies (e.g., `64 bytes from 192.168.0.220`).
   - **Failure**: Check network (`ip addr`) or server status.
3. Test DNS resolution:
   ```bash
   nslookup ad-serv.homepi.local
   ```
   - **Success**: Returns `Address: 192.168.0.220`.
   - **Failure**: Configure DNS (Step 2).
4. Test AD ports:
   ```bash
   sudo apt install telnet -y
   telnet 192.168.0.220 88
   telnet 192.168.0.220 53
   telnet 192.168.0.220 389
   telnet 192.168.0.220 445
   ```
   - **Success**: Shows `Connected to 192.168.0.220` (Ctrl+] and `quit` to exit).
   - **Failure**: Check server firewall:
     ```bash
     ssh siva@192.168.0.220 "sudo ufw status"
     ```

## Step 2: Configure DNS
1. Set the Samba server as the DNS server:
   ```bash
   sudo nano /etc/systemd/resolved.conf
   ```
   - Add:
     ```ini
     [Resolve]
     DNS=192.168.0.220
     Domains=homepi.local
     ```
   - Save and exit.
2. Restart DNS service:
   ```bash
   sudo systemctl restart systemd-resolved
   ```
3. Verify:
   ```bash
   nslookup ad-serv.homepi.local
   ```

## Step 3: Install Required Packages
1. Update packages:
   ```bash
   sudo apt update -y
   ```
2. Install AD integration tools:
   ```bash
   sudo apt install -y realmd sssd sssd-tools libnss-sss libpam-sss krb5-user samba-common-bin packagekit
   ```
   - For `krb5-user`, enter:
     - **Realm**: `HOMEPI.LOCAL`
     - **Servers**: `ad-serv.homepi.local`
     - **Admin server**: `ad-serv.homepi.local`

## Step 4: Synchronize Time
1. Install `chrony`:
   ```bash
   sudo apt install -y chrony
   ```
2. Configure:
   ```bash
   sudo nano /etc/chrony/chrony.conf
   ```
   - Add:
     ```conf
     server 192.168.0.220 iburst
     ```
   - Save and exit.
3. Restart:
   ```bash
   sudo systemctl restart chrony
   ```
4. Verify:
   ```bash
   chronyc sources
   ```

## Step 5: Join the Domain
1. Discover the domain:
   ```bash
   realm discover homepi.local
   ```
   - Should show `homepi.local` details.
2. Join:
   ```bash
   sudo realm join --user=Administrator homepi.local
   ```
   - Enter the Administrator password.
3. Verify:
   ```bash
   realm list
   ```

## Step 6: Configure SSSD
1. Edit SSSD:
   ```bash
   sudo nano /etc/sssd/sssd.conf
   ```
   - Ensure:
     ```ini
     [sssd]
     domains = homepi.local
     config_file_version = 2
     services = nss, pam

     [domain/homepi.local]
     ad_domain = homepi.local
     krb5_realm = HOMEPI.LOCAL
     cache_credentials = True
     id_provider = ad
     krb5_store_password_if_offline = True
     default_shell = /bin/bash
     ldap_id_mapping = True
     use_fully_qualified_names = False
     fallback_homedir = /home/%u
     access_provider = ad
     ```
   - Save and exit.
2. Set permissions:
   ```bash
   sudo chmod 600 /etc/sssd/sssd.conf
   ```
3. Restart:
   ```bash
   sudo systemctl restart sssd
   ```

## Step 7: Enable Home Directory Creation
1. Enable `mkhomedir`:
   ```bash
   sudo pam-auth-update
   ```
   - Select **Create home directory on login** and confirm.
2. Verify:
   ```bash
   grep mkhomedir /etc/pam.d/common-session
   ```

## Step 8: Log In as a Domain User
1. Test Kerberos authentication:
   ```bash
   kinit Administrator@HOMEPI.LOCAL
   ```
   - Enter the Administrator password.
   - Verify:
     ```bash
     klist
     ```
2. Test user lookup:
   ```bash
   id Administrator@homepi.local
   ```
   - Should show UID/GID and groups (e.g., `Domain Admins`).
3. Log in:
   - **Desktop**:
     - Log out, select **Not listed?** or **Other user**.
     - Enter `Administrator@homepi.local` and the password.
     - A home directory (`/home/Administrator`) is created automatically.
   - **SSH**:
     ```bash
     ssh Administrator@homepi.local@localhost
     ```
     - Should log in successfully.
   - **Terminal (su)**:
     ```bash
     su - Administrator@homepi.local
     ```
     - Should switch to the domain user.

## Troubleshooting
- **APT Lock Error**:
  - If `sudo apt update` fails with `E: Could not get lock /var/lib/apt/lists/lock`:
    1. Identify the process (e.g., PID 4755):
       ```bash
       ps aux | grep 4755
       ```
    2. Wait or stop it:
       ```bash
       sudo kill -SIGTERM 4755
       ```
    3. Clean locks (if no processes):
       ```bash
       sudo rm /var/lib/apt/lists/lock
       sudo rm /var/cache/apt/archives/lock
       sudo rm /var/lib/dpkg/lock-frontend
       sudo dpkg --configure -a
       ```
    4. Retry:
       ```bash
       sudo apt update -y
       ```
- **Connectivity**:
  - Recheck: `ping 192.168.0.220`, `nslookup ad-serv.homepi.local`.
  - Verify server: `ssh siva@192.168.0.220 "sudo systemctl status samba-ad-dc"`.
- **Join Failure**:
  - Check: `journalctl -u realmd`.
  - Verify credentials: `kinit Administrator@HOMEPI.LOCAL`.
- **Authentication**:
  - Check: `sudo systemctl status sssd`.
  - Review: `/etc/sssd/sssd.conf`.
- **DNS**:
  - Verify: `systemd-resolve --status`.

## Notes
- Compatible with Ubuntu 20.04/24.04.
- Backup configs:
  ```bash
  sudo cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.bak
  ```
- Complements the Windows 10/11 Pro AD join guide.
- For further help, see the Samba Wiki: https://wiki.samba.org/