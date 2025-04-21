# Configure a VMware Virtual Machine for Bridged Network

This guide provides instructions to configure a VMware virtual machine (VM) to connect to the same network as the host machine using Bridged networking mode. This setup allows the VM to act as a separate device on the network, obtaining its own IP address from the router’s DHCP server.

## Prerequisites
- VMware Workstation or another VMware product installed.
- A powered-off virtual machine.
- Administrator access to VMware and the host machine.
- A host machine connected to a router via Ethernet or Wi-Fi.

## Steps to Configure the VM Network

1. **Open VMware and Select the VM**  
   - Launch VMware Workstation (or your VMware product).  
   - Select the virtual machine you want to configure from the VMware interface.

2. **Edit Virtual Machine Settings**  
   - Ensure the VM is powered off.  
   - Right-click the VM and select **Settings**, or navigate to **Edit > Virtual Machine Settings**.

3. **Configure the Network Adapter**  
   - In the VM settings window, select the **Network Adapter**.  
   - Set the network connection to **Bridged** mode:  
     - Choose **Bridged: Connected directly to the physical network**.  
     - Ensure the **Replicate physical network connection state** option is checked. This allows the VM to adapt to network changes on the host.  
   - Bridged mode enables the VM to function as an independent device on the same network as the host, receiving an IP address from the router’s DHCP server.

4. **Verify Bridged Network Settings**  
   - If the host has multiple network adapters (e.g., Ethernet and Wi-Fi), verify the correct adapter is used:  
     - Open VMware as an administrator.  
     - Navigate to **Edit > Virtual Network Editor**.  
     - Select the Bridged network and click **Configure Adapters**.  
     - Ensure the desired network adapter (e.g., the Ethernet adapter connected to the router) is selected.  
   - Apply the changes and close the Virtual Network Editor.

5. **Start the VM and Configure the Guest OS**  
   - Power on the VM.  
   - In the guest operating system (e.g., Windows), configure the network settings to use DHCP:  
     - Open **Control Panel > Network and Sharing Center > Change adapter settings**.  
     - Right-click the network adapter and select **Properties**.  
     - Select **Internet Protocol Version 4 (TCP/IPv4)** and click **Properties**.  
     - Choose **Obtain an IP address automatically** and **Obtain DNS server address automatically**.  
     - Save the settings.  
   - Alternatively, use the Command Prompt in the guest OS:  
     ```cmd
     netsh interface ip set address "Ethernet" dhcp
     netsh interface ip set dns "Ethernet" dhcp
     ```

6. **Verify Connectivity**  
   - After booting, the VM should receive an IP address from the router’s DHCP server.  
   - In the guest OS, open a Command Prompt and run:  
     ```cmd
     ipconfig /all
     ```  
     - Confirm the VM has an IP address on the same subnet as the host (e.g., 192.168.x.x).  
     - Check the Subnet Mask, Default Gateway, and DNS Servers match the host’s network configuration.  
   - Test connectivity:  
     - Ping the router (e.g., `ping 192.168.x.1`).  
     - Ping an external server (e.g., `ping 8.8.8.8`).  

7. **Troubleshooting**  
   - **No IP Address**:  
     - Ensure the router’s DHCP server is enabled and has available IP addresses.  
     - In the guest OS, run:  
       ```cmd
       ipconfig /release
       ipconfig /renew
       ```  
   - **Wrong Network**:  
     - Confirm the VM is in Bridged mode and bound to the correct host network adapter in the Virtual Network Editor.  
   - **Firewall Issues**:  
     - Check the guest OS firewall settings to ensure network traffic is allowed.  
   - **VMware Network Adapter**:  
     - Verify the network adapter is enabled and connected in the VM settings.  
   - **Router Restrictions**:  
     - Ensure the router does not have MAC address filtering enabled that might block the VM.

## Optional: Configure a Static IP
If you prefer to assign a static IP address to the VM:  
- In the guest OS, manually set the IPv4 properties:  
  - **IP Address**: Choose an address outside the router’s DHCP range (e.g., 192.168.x.200).  
  - **Subnet Mask**: Match the host’s subnet mask (e.g., 255.255.255.0).  
  - **Default Gateway**: Set to the router’s IP (e.g., 192.168.x.1).  
  - **DNS Servers**: Use the router’s DNS or public DNS (e.g., 8.8.8.8, 8.8.4.4).  
- Verify the IP is not in use by pinging it from another device:  
  ```cmd
  ping <chosen-IP-address>
  ```

## Notes
- **Bridged Mode**: Ideal for placing the VM on the same network as the host, allowing communication with other devices and internet access via the router.  
- **Alternative Modes**:  
  - **NAT**: Shares the host’s IP but doesn’t allow the VM to be directly accessible as a separate device.  
  - **Host-Only**: Isolates the VM to communicate only with the host.  
- **VMware Tools**: Install VMware Tools in the guest OS for optimal network performance.  

Your VM should now be connected to the same network as the host, with its own IP address and full network access. For further assistance, consult VMware documentation or your network administrator.