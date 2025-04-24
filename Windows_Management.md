# Windows Configuration for Roaming Profile Quota Setup (Including RSAT and MMC)

This document outlines the Windows-specific steps to configure and manage roaming profiles with a 5GB per-user quota in a Samba Active Directory Domain Controller (AD DC) environment. It starts with installing the Remote Server Administration Tools (RSAT), setting up the Microsoft Management Console (MMC) with necessary snap-ins, creating a new user, configuring Group Policy, and verifying the setup on a Windows client.

## Prerequisites
- A Windows client (e.g., Windows 11 Pro or Enterprise) that supports RSAT.
- The client is domain-joined to `homepi.local`.
- Samba server is configured with filesystem quotas and `vfs objects = quotas` in `smb.conf` (assumed completed).

## Steps

### Step 1: Install Remote Server Administration Tools (RSAT)
1. Verify your Windows edition supports RSAT (e.g., Windows 11 Pro or Enterprise). RSAT is not supported on Windows Home editions.
2. Open the Settings app:
   - Press `Win + I` to open Settings.
3. Navigate to `Apps` > `Optional features`.
4. Click `Add an optional feature` or `View features`.
5. Search for `RSAT`.
6. Select the following RSAT components:
   - **RSAT: Active Directory Domain Services and Lightweight Directory Tools**
   - **RSAT: Group Policy Management Tools**
7. Click `Install` to add the selected RSAT tools.
8. Wait for the installation to complete, then restart the computer if prompted.

### Step 2: Open Microsoft Management Console (MMC)
1. Press `Win + R`, type `mmc`, and press Enter to launch the Microsoft Management Console.

### Step 3: Add Snap-ins to MMC
1. In MMC, go to the `File` menu and select `Add/Remove Snap-in`.
2. In the left pane, under `Available snap-ins`, select and add the following snap-ins to the right pane (`Selected snap-ins`):
   - **Active Directory Users and Computers**
   - **Group Policy Management**
3. For **Computer Management** (optional, if managing the Samba server directly):
   - Select `Computer Management`, click `Add`, then choose `Another computer`.
   - Enter the Samba AD DC’s hostname (e.g., `samba-dc.homepi.local`) and click `OK`.
4. Click `OK` to close the Add/Remove Snap-in dialog.
5. Save the MMC console for future use:
   - Go to `File` > `Save As`, name it (e.g., `AD_Management.msc`), and save it to your desktop.

### Step 4: Create a New User in Active Directory
1. In the MMC console, under the `Active Directory Users and Computers` snap-in, expand `homepi.local`.
2. Navigate to the `Users` container.
3. Right-click the `Users` container, select `New` > `User`.
4. Fill in the user details:
   - **First name**: e.g., `Test`.
   - **Last name**: e.g., `User`.
   - **Full name**: `Test User` (auto-filled).
   - **User logon name**: `testuser`.
   - **User logon name (pre-Windows 2000)**: `HOMEPI\testuser` (auto-filled).
5. Click `Next`.
6. Set the password:
   - Enter a password (e.g., `P@ssw0rd123`).
   - Uncheck `User must change password at next logon` (optional, for testing).
7. Click `Next`, then `Finish` to create the user.

### Step 5: Configure Group Policy for Roaming Profiles
1. In the MMC console, under the `Group Policy Management` snap-in, expand `homepi.local`.
2. Right-click the domain or an Organizational Unit (OU) containing user accounts (e.g., `Users`).
3. Select `Create a GPO in this domain, and Link it here`.
4. Name the GPO (e.g., "Roaming Profile Quota").
5. Right-click the new GPO and select `Edit` to open the Group Policy Management Editor.
6. Navigate to:  
   ```
   User Configuration > Policies > Administrative Templates > System > User Profiles
   ```
7. Enable the policy: **Set roaming profile path for all users logging onto this computer**.
8. Set the path to:  
   ```
   \\samba-dc\profiles\%username%
   ```
   This maps profiles to `\\samba-dc\profiles\username.V6` (Samba appends `.V6` for Windows 10/11).
9. In the same `User Profiles` section, enable the policy: **Limit profile size**.
10. Set the maximum size to:  
    ```
    5120000 KB
    ```
    (5GB = 5 * 1024 * 1000 KB).
11. Check `Notify user when profile storage space is exceeded` to alert users.
12. Optionally, check `Prevent users from logging off until profile cleanup is complete` to ensure oversized profiles are cleaned up.
13. Save the settings and close the editor.

### Step 6: Apply the GPO
1. Ensure the GPO is linked to the domain or OU containing user accounts.
2. On a domain-joined Windows client, open a Command Prompt as Administrator.
3. Force GPO application:  
   ```
   gpupdate /force
   ```

### Step 7: Verify GPO Application
1. Log in to a Windows client as the new user (e.g., `HOMEPI\testuser`).
2. Check applied GPOs:  
   ```
   gpresult /r
   ```
   Confirm the "Roaming Profile Quota" GPO is listed under `Applied Group Policy Objects`.
3. Verify the profile path:
   - Right-click `This PC` > `Properties` > `Advanced system settings` > `User Profiles` > `Settings`.
   - Confirm the profile path is `\\samba-dc\profiles\testuser.V6`.

### Step 8: Verify Quota Display in Windows
1. While logged in as `testuser`, open File Explorer.
2. Navigate to `\\samba-dc\profiles\testuser.V6`.
3. Right-click the folder and select `Properties`.
4. In the `General` tab, verify:
   - Used space: Current usage.
   - Free space: ~5GB (or 5120000 KB minus used space).
   - Capacity: 5GB (5120000 KB).

### Step 9: Test Quota Enforcement
1. While logged in as `testuser`, copy large files to the profile (e.g., to `Desktop`) to exceed 5GB.
2. Log off. Windows should:
   - Display a warning if the profile approaches or exceeds 5GB (due to GPO).
   - Prevent saving data beyond 5GB, deleting excess files during logoff.

## Verification Checklist
1. **RSAT Installed**:
   - RSAT tools (Active Directory Domain Services and Group Policy Management) are available in Optional Features.
2. **MMC Configured**:
   - Snap-ins for Active Directory Users and Computers and Group Policy Management are added.
3. **GPO Configured**:
   - Profile path set to `\\samba-dc\profiles\%username%`.
   - Profile size limited to 5120000 KB with notifications enabled.
4. **User Created**:
   - `testuser` exists in `Users` container of `homepi.local`.
5. **GPO Applied**:
   - `gpresult /r` confirms the GPO is applied.
   - Profile path is `\\samba-dc\profiles\testuser.V6`.
6. **Quota Display**:
   - Folder properties show 5GB capacity (requires Samba `vfs objects = quotas`).
7. **Quota Enforcement**:
   - Profile cannot exceed 5GB (tested by adding files).

## Potential Issues and Fixes
1. **RSAT Installation Fails**:
   - Ensure the Windows edition supports RSAT (Pro or Enterprise).
   - Check internet connectivity for downloading RSAT components.
2. **Snap-ins Fail to Connect**:
   - Verify the Windows client’s DNS points to the Samba DC:  
     ```
     nslookup homepi.local
     ```
   - Ensure the Samba server is reachable (`ping samba-dc.homepi.local`).
   - Check firewall ports (e.g., TCP 445, 389, 53 for AD and DNS).
3. **Full Disk Space Displayed**:
   - If the folder shows the entire server disk space, ensure Samba is configured with `vfs objects = quotas` (server-side setting).
   - Verify SMB protocol (SMB2 or higher):  
     ```
     smbclient -L samba-dc -U testuser --option="client min protocol=SMB2"
     ```
4. **Temporary Profiles**:
   - Check permissions on `\\samba-dc\profiles\testuser.V6` (should be owned by `testuser:Domain Users` with `700` permissions).
   - Review Event Viewer (`Windows Logs > Application`) for profile load errors.
5. **User Creation Fails**:
   - Ensure the Windows client’s DNS points to the Samba DC:  
     ```
     nslookup homepi.local
     ```
   - Check Event Viewer for AD-related errors.

## Summary
These steps install RSAT, configure MMC with necessary snap-ins, set up Group Policy to enforce a 5GB roaming profile limit, create a new user in Active Directory, and verify the setup on a Windows client. The GPO ensures profiles are mapped correctly and limited to 5GB, while verification confirms the setup. Note that displaying the 5GB quota in folder properties requires Samba server-side configuration (`vfs objects = quotas`), which is assumed to be in place.