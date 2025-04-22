# Install and Set Up Webmin 2.203 on Ubuntu

## Introduction to Webmin
Webmin is an open-source, web-based system administration tool for Linux and Unix systems. It provides a graphical interface to manage server tasks such as user accounts, file sharing, disk quotas, and services like Samba, Apache, and DNS, without relying on command-line interfaces. Webmin is highly modular, allowing administrators to extend functionality with additional modules.

**License**: Webmin is released under the **BSD 3-Clause License**, making it free and open-source software. This license allows users to use, modify, and distribute Webmin, provided they include the original copyright notice and disclaimers.

This guide explains how to install Webmin 2.203 on an Ubuntu server, resolve dependency errors, access the interface, manage Samba users and groups, configure disk quotas, automate quota setup for new users, and create and share a folder with specific permissions, all primarily through the Webmin interface. Bash commands are included where necessary.

## Prerequisites
- **Operating System**: Ubuntu 20.04 or 24.04 (tested on both).
- **User Privileges**: A non-root user with `sudo` privileges.
- **Network**: Internet access for downloading packages and a static IP (e.g., `192.168.0.220`).
- **Firewall**: UFW (Uncomplicated Firewall) configured, if enabled.
- **Samba AD DC**: Assumed to be set up (e.g., `ad-serv.homepi.local`, domain: `homepi.local`), as per prior context.
- **Disk Quotas**: Filesystem (e.g., `/home` or `/var/lib/samba/sysvol`) must support quotas.

## Installation Steps

### Step 1: Update System Packages
Ensure your system is up-to-date to avoid compatibility issues.

- **Via Terminal**:
  ```bash
  sudo apt update -y && sudo apt upgrade -y
  ```

### Step 2: Add Webmin Repository
Webmin 2.203 is not in Ubuntu’s default repositories, so add the official Webmin repository.

- **Via Terminal**:
  ```bash
  sudo curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
  sudo bash setup-repos.sh
  ```
  - This script adds the Webmin repository to `/etc/apt/sources.list.d/webmin.list` and imports the GPG key for package verification.

### Step 3: Install Webmin 2.203
Install Webmin using the `apt` package manager.

- **Via Terminal**:
  ```bash
  sudo apt install webmin -y
  ```
  - Expected output:
    ```
    Webmin install complete. You can now login to https://<your-server-ip>:10000/
    ```

### Step 4: Resolve Dependency Errors
If dependency errors occur during installation (e.g., missing `libnet-ssleay-perl`, `libauthen-pam-perl`, `libio-pty-perl`, or `apt-show-versions`), fix them.

- **Common Error Example**:
  ```
  dpkg: dependency problems prevent configuration of webmin:
  webmin depends on libnet-ssleay-perl; however: Package libnet-ssleay-perl is not installed.
  ```
- **Fix via Terminal**:
  ```bash
  sudo apt-get install -f -y
  ```
  - This command resolves unmet dependencies by installing missing packages.
  - If errors persist, manually install specific dependencies:
    ```bash
    sudo apt install libnet-ssleay-perl libauthen-pam-perl libio-pty-perl apt-show-versions -y
    sudo apt install webmin -y
    ```

- **Verify Installation**:
  ```bash
  sudo systemctl status webmin
  ```
  - Should show:
    ```
    ● webmin.service - LSB: web-based administration interface for Unix systems
       Active: active (running)
    ```

### Step 5: Configure Firewall
Allow Webmin’s default port (10000) if UFW is enabled.

- **Via Terminal**:
  ```bash
  sudo ufw allow 10000
  sudo ufw reload
  sudo ufw status
  ```
  - Should show:
    ```
    10000  ALLOW  Anywhere
    ```

## Accessing Webmin
- Open a web browser and navigate to:
  ```
  https://<your-server-ip>:10000
  ```
  - Example: `https://192.168.0.220:10000` (replace with your server’s IP).
- **SSL Warning**: You’ll see an “Invalid SSL” warning due to Webmin’s self-signed certificate. Accept the warning to proceed (or install a Let’s Encrypt certificate later for security).
- **Login**:
  - **Username**: `root` or a user with sudo privileges (e.g., `siva`).
  - **Password**: The corresponding system password.
- **Dashboard**: Upon login, you’ll see the Webmin dashboard with system information (CPU, memory, disk usage).

## Managing Samba Server, Users, and Groups

### View Samba Server Configuration
- In Webmin:
  - Go to **Servers > Samba Windows File Sharing**.
  - The main page displays:
    - **Shares**: Lists shares like `sysvol`, `netlogon`, or custom shares (e.g., `Apps`).
    - **Status**: Samba service status (start/stop/restart).
    - **Configuration**: Paths to Samba binaries and config files (`/etc/samba/smb.conf`).
  - Verify shares like `sysvol` (path: `/var/lib/samba/sysvol`).

### Manage Samba Users
- In Webmin:
  - Navigate to **Servers > Samba Windows File Sharing > Samba Users**.
  - **View Users**:
    - Lists existing Samba users (e.g., `HOMEPI\Administrator`, `HOMEPI\testuser`).
  - **Convert Unix Users to Samba Users**:
    - Click **Convert Unix Users to Samba Users**.
    - Select users or click **Convert Users** to sync all Unix users to Samba.
    - This creates Samba accounts for Unix users, enabling network access.
  - **Edit User Passwords**:
    - Click **Edit Samba Users and Passwords**.
    - Select a user, set a password, and click **Save**.

### Manage Groups
- In Webmin:
  - Go to **System > Users and Groups**.
  - **View Groups**:
    - Lists Unix groups (e.g., `Domain Admins`, `Domain Users`).
    - Samba uses these groups for access control (e.g., `Domain Admins` for admin tasks).
  - **Create/Edit Groups**:
    - Click **Create a new group** or select an existing group.
    - Add users to groups (e.g., add `testuser` to `Domain Users`).
    - Save changes.
  - **Sync with Samba**: Changes to Unix groups are automatically reflected in Samba if configured to use the same user database.

## Setting Up Disk Quotas
Enable and configure disk quotas for users on a filesystem (e.g., `/home` or `/var/lib/samba/sysvol`).

### Step 1: Enable Quotas
- **Via Terminal** (initial setup):
  - Edit `/etc/fstab` to enable quotas:
    ```bash
    sudo nano /etc/fstab
    ```
    - Add `usrquota,grpquota` to the options for the target filesystem (e.g., `/home`):
      ```
      /dev/sda1 /home ext4 defaults,usrquota,grpquota 0 2
      ```
    - Save and exit.
  - Remount the filesystem:
    ```bash
    sudo mount -o remount /home
    ```
  - Initialize quota files:
    ```bash
    sudo quotacheck -avugm
    sudo quotaon -av
    ```

- **Via Webmin**:
  - Go to **System > Disk Quotas**.
  - Select the filesystem (e.g., `/home`).
  - Click **Enable Quotas** if not already enabled.
  - Click **Apply** to initialize quota files.

### Step 2: Set User Quotas
- In Webmin:
  - Navigate to **System > Disk Quotas**.
  - Select the filesystem (e.g., `/home`).
  - Click **Edit User Quotas**.
  - Find a user (e.g., `testuser`).
  - Set:
    - **Soft Limit**: 500MB (warning threshold).
    - **Hard Limit**: 600MB (maximum usage).
  - Click **Save**.
  - Repeat for other users.

### Step 3: Verify Quotas
- **Via Terminal**:
  ```bash
  quota -u testuser
  ```
  - Should show:
    ```
    Disk quotas for user testuser (uid 1001):
    Filesystem  blocks  soft  hard
    /home       0      500M  600M
    ```
- **Via Webmin**:
  - In **Disk Quotas**, check the user’s quota status.

## Automating Quota Setup for New Users
Automate quota assignment for new users using Webmin’s batch processing or a script triggered by user creation.

### Option 1: Webmin Batch File
- Create a batch file to set quotas for new users.
- **Via Terminal**:
  ```bash
  echo "setquota:testuser:500M:600M:0:0:/home" > /tmp/quota.batch
  ```
  - Format: `setquota:username:softlimit:hardlimit:inodesoft:ihard:filesystem`.
- **In Webmin**:
  - Go to **System > Disk Quotas**.
  - Select the filesystem (e.g., `/home`).
  - Choose **Execute batch file** and upload `/tmp/quota.batch`.
  - Click **Execute**.
  - For new users, add their entries to the batch file and re-run.

### Option 2: Script Triggered by Webmin
- Create a script to set quotas on user creation.
- **Via Terminal**:
  ```bash
  sudo nano /usr/local/bin/set_user_quota.sh
  ```
  - Add:
    ```bash
    #!/bin/bash
    USER=$1
    setquota -u $USER 500M 600M 0 0 /home
    ```
  - Make executable:
    ```bash
    sudo chmod +x /usr/local/bin/set_user_quota.sh
    ```

- **In Webmin**:
  - Go to **System > Users and Groups > Module Config**.
  - Set **Command to run after making changes** to:
    ```
    /usr/local/bin/set_user_quota.sh $USERADMIN_USER
    ```
  - Save. Now, when a new user is created, the script sets a 500MB soft/600MB hard quota.

## Creating and Sharing a Folder with Specific Permissions
Create an `Apps` folder in the `sysvol` share and share it with users (e.g., `Authenticated Users`) with **read-only and execute** permissions.

### Step 1: Create the Folder
- In Webmin:
  - Go to **Tools > File Manager**.
  - Navigate to `/var/lib/samba/sysvol/homepi.local/`.
  - Click **New Folder**, name it `Apps`, and click **Create**.
- Set initial permissions:
  - Right-click `Apps`, select **File Permissions**.
  - Set:
    - **Owner**: `root`.
    - **Group**: `Domain Admins`.
    - **Permissions**: `750`.
  - Click **Save**.

### Step 2: Share the Folder
The `Apps` folder is accessible via the `sysvol` share (`\\ad-serv.homepi.local\sysvol\homepi.local\Apps`).

- In Webmin:
  - Go to **Servers > Samba Windows File Sharing**.
  - Click the `sysvol` share.
  - Confirm:
    - **Path**: `/var/lib/samba/sysvol`.
    - **Read only**: `No` (required for `sysvol`; permissions control access).
  - Click **Save**.

### Step 3: Set Read-Only and Execute Permissions
- **Filesystem Permissions**:
  - In **Tools > File Manager**, navigate to `/var/lib/samba/sysvol/homepi.local/Apps`.
  - Right-click `Apps`, select **File Permissions**.
  - Set:
    - **Owner**: `root`.
    - **Group**: `Domain Admins`.
    - **Permissions**: `750`.
  - Add ACL:
    - Click **ACL** (if available).
    - Add `Authenticated Users` with `Read & Execute`.
    - Save.
  - **Via Terminal** (if ACL not available in Webmin):
    ```bash
    sudo setfacl -R -m u:"Authenticated Users":rx /var/lib/samba/sysvol/homepi.local/Apps
    sudo setfacl -R -m d:u:"Authenticated Users":rx /var/lib/samba/sysvol/homepi.local/Apps
    ```

- **Samba Permissions (via Windows)**:
  - On a Windows 10/11 Pro client (logged in as `HOMEPI\Administrator`):
    - Open File Explorer, navigate to `\\ad-serv.homepi.local\sysvol\homepi.local\Apps`.
    - Right-click `Apps`, select **Properties > Security**.
    - Click **Edit**.
    - Add `Authenticated Users` (type `Authenticated Users`, click **Check Names**).
    - Grant:
      - `Read & execute`
      - `List folder contents`
      - `Read`
      - Uncheck write permissions.
    - Ensure `Domain Admins` has `Full control`.
    - Click **OK**.

### Step 4: Test Access
- On a Windows 10/11 Pro client:
  - Log in as a non-admin user (e.g., `HOMEPI\testuser`).
  - Navigate to `\\ad-serv.homepi.local\sysvol\homepi.local\Apps`.
  - **Read Test**: Copy a file (e.g., `test.txt`) to your desktop (should succeed).
  - **Execute Test**: Run an executable (e.g., `setup.exe`) from `Apps` (should succeed).
  - **Write Test**: Try creating a file (should fail with **Access Denied**).

## Troubleshooting
- **Dependency Errors**:
  - Run `sudo apt-get install -f` or manually install missing packages.
  - Check logs: `tail -n 50 /var/log/apt/term.log`.
- **Webmin Not Accessible**:
  - Verify service: `sudo systemctl status webmin`.
  - Check firewall: `sudo ufw status`.
- **Samba Issues**:
  - Check logs: `tail -n 50 /var/log/samba/log.samba`.
  - Verify AD: `samba-tool domain info 192.168.0.220`.
- **Quota Not Working**:
  - Ensure `usrquota,grpquota` in `/etc/fstab`.
  - Check: `quota -u testuser`.
- **Permission Errors**:
  - Recheck ACLs: `getfacl /var/lib/samba/sysvol/homepi.local/Apps`.
  - Reset: `sudo setfacl -R -m u:"Authenticated Users":rx /var/lib/samba/sysvol/homepi.local/Apps`.

## Security Recommendations
- **SSL Certificate**: Replace Webmin’s self-signed certificate with Let’s Encrypt:
  - In Webmin: **Webmin > Webmin Configuration > SSL Encryption > Let’s Encrypt**.
  - Follow prompts to configure.
- **Backup**: Before changes:
  ```bash
  sudo cp -r /var/lib/samba/sysvol /var/lib/samba/sysvol.bak
  ```
- **Restrict Access**: Limit Webmin to specific IPs:
  - Edit `/etc/webmin/miniserv.conf`, add:
    ```
    allow=192.168.0.0/24
    ```
  - Restart: `sudo systemctl restart webmin`.

## Conclusion
You’ve installed Webmin 2.203, resolved dependency errors, accessed the interface, managed Samba users and groups, set up quotas, automated quota assignment, and shared the `Apps` folder with read-only and execute permissions. Use Webmin’s intuitive interface to streamline server management for your Samba AD DC (`homepi.local`).

For more details, visit the [Webmin Documentation](https://webmin.com/documentation/).[](https://webmin.com/docs/)