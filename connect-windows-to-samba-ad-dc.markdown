# Connect Windows 10/11 Pro to Samba Active Directory Domain Controller

This guide explains how to test connectivity, join a Windows 10 Pro or Windows 11 Pro computer to a Samba Active Directory (AD) Domain Controller (DC), and log in with domain users. It assumes your Samba server is set up with the domain `homepi.local`, running on a server named `ad-serv.homepi.local` (IP: `192.168.0.220`).

## Prerequisites
- **Windows 10/11 Pro**: Windows Home editions do not support domain joining.
- **Network**: Your Windows computer must be on the same network as the Samba server (e.g., 192.168.0.x).
- **Samba Server**: Running and configured as an AD DC.
- **Admin Credentials**: Samba AD Administrator username (`HOMEPI\Administrator`) and password.

## Step 1: Test Connectivity
1. Open **Command Prompt** as Administrator:
   - Press `Win + S`, type `cmd`, right-click **Command Prompt**, select **Run as administrator**.
2. Test connection to the Samba server:
   ```cmd
   ping 192.168.0.220
   ```
   - Success: You see replies (e.g., `Reply from 192.168.0.220`).
   - Failure: Check your network settings or ensure the Samba server is on.
3. Test DNS resolution:
   ```cmd
   nslookup ad-serv.homepi.local
   ```
   - Success: Returns `Address: 192.168.0.220`.
   - Failure: Set the DNS server (Step 2).
4. Test AD ports:
   ```cmd
   Test-NetConnection 192.168.0.220 -Port 88
   Test-NetConnection 192.168.0.220 -Port 53
   Test-NetConnection 192.168.0.220 -Port 389
   Test-NetConnection 192.168.0.220 -Port 445
   ```
   - Success: All show `TcpTestSucceeded: True`.
   - Failure: Check Windows firewall (Step 3).

## Step 2: Configure DNS
1. Open network settings:
   - Press `Win + R`, type `ncpa.cpl`, press **Enter**.
2. Right-click your active network (e.g., Ethernet), select **Properties**.
3. Select **Internet Protocol Version 4 (TCP/IPv4)**, click **Properties**.
4. Set **Preferred DNS Server** to `192.168.0.220`.
5. Click **OK**, then **Close**.
6. Retest DNS:
   ```cmd
   nslookup ad-serv.homepi.local
   ```

## Step 3: Allow Firewall Access
1. Open **Windows Defender Firewall with Advanced Security**:
   - Press `Win + S`, search `firewall`, select **Windows Defender Firewall with Advanced Security**.
2. Create inbound and outbound rules:
   - Click **New Rule** (under **Inbound Rules** and **Outbound Rules**).
   - Select **Port**, click **Next**.
   - Choose **TCP**, enter `53,88,135,389,445,464`, click **Next**.
   - Select **Allow the connection**, click **Next**.
   - Apply to all profiles, click **Next**.
   - Name it "AD DC Ports", click **Finish**.
   - Repeat for **UDP** ports `53,88,389,464`.
3. Retest ports:
   ```cmd
   Test-NetConnection 192.168.0.220 -Port 88
   ```

## Step 4: Synchronize Time
1. In **Command Prompt** (as Administrator):
   ```cmd
   w32tm /config /manualpeerlist:192.168.0.220 /syncfromflags:manual /update
   net stop w32time
   net start w32time
   w32tm /resync
   ```
2. Verify:
   ```cmd
   w32tm /query /source
   ```
   - Should show `192.168.0.220`.

## Step 5: Join the Domain
1. Open **Settings**:
   - Press `Win + I`, go to **System > About**.
   - Under **Device specifications**, click **Join a domain** (or **Domain or workgroup**).
2. Select **Domain**, enter `homepi.local`, click **OK**.
3. Enter credentials:
   - **Username**: `HOMEPI\Administrator` (or `Administrator`).
   - **Password**: The Samba Administrator password.
   - Click **OK**.
4. If successful, see **Welcome to the homepi.local domain**.
5. Restart your computer when prompted.

## Step 6: Log In with Domain Users
1. After restarting, at the Windows login screen:
   - Click **Other user** (or switch user, depending on your setup).
   - Enter the domain username: `HOMEPI\Administrator` (or another domain user, e.g., `HOMEPI\testuser`).
   - Enter the corresponding password.
   - Press **Enter** to log in.
2. If login fails:
   - Ensure the username is in the format `HOMEPI\username`.
   - Verify the password on the Samba server:
     ```bash
     kinit username@HOMEPI.LOCAL
     ```
   - Check network connectivity to `192.168.0.220`.

## Step 7: Verify Domain Join
1. After logging in, open **Command Prompt**:
   ```cmd
   systeminfo | find "Domain"
   ```
   - Should show `Domain: homepi.local`.
2. Test DC connectivity:
   ```cmd
   nltest /dsgetdc:homepi.local
   ```
   - Should show `DC: \\ad-serv.homepi.local`, `Address: 192.168.0.220`.

## Troubleshooting
- **Cannot Contact AD DC**:
  - Recheck connectivity (`ping`, `nslookup`, `Test-NetConnection`).
  - Ensure the Samba server is running:
    ```bash
    sudo systemctl status samba-ad-dc
    ```
- **Authentication Error**:
  - Verify the user password on the Samba server:
    ```bash
    kinit username@HOMEPI.LOCAL
    ```
  - Reset if needed:
    ```bash
    samba-tool user setpassword username
    ```
- **DNS Issues**:
  - Confirm DNS server is `192.168.0.220`:
    ```cmd
    ipconfig /all
    ```
- **Contact Support**:
  - Check Samba logs:
    ```bash
    tail -n 50 /var/log/samba/log.samba
    ```
  - Note the exact error from the Windows join or login dialog.

## Notes
- These steps work for both **Windows 10 Pro** and **Windows 11 Pro**.
- Keep your Samba server updated:
  ```bash
  sudo apt update && sudo apt upgrade samba
  ```
- Backup configurations:
  ```bash
  sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
  ```
- For help, refer to the Samba Wiki: https://wiki.samba.org/