# scan_lan_ip_monitor

Target OS: Windows

This script will ping all IP's on a specified Class C LAN to identify which IP addresses are in use by connected devices. 

While performing a ping sweep, it will also update the local ARP table, useful to get the MAC addresses.

Having the list of identified connected devices, the script will loop indefinitely through the identified connected devices list, checking if they are connected or not.

If a device using a previously scanned IP address is disconnected, a "disconnected device" message with it's IP and MAC addresses is shown.

To stop the monitor infinite loop, press Ctrl^C and (Y)es.

This tool can help find the IP address when you don't know the MAC address but have access to the physical link: with the device connected to LAN, start the script, insert the LAN subnet and let it scan all 255 IP addresses. After the scan process, you'll be prompted to start the monitor process. Press Enter and the monitor process starts. Now, disconnect the device from LAN. During the next monitor cycle, a "disconnected device" with it's IP and MAC addresses message is triggered and will keep showing at each cycle, until the device is connected back to LAN.

The results will depend on the DHCP server lease time and politics: the lease time should allow the device to be disconnected and connected back, with the same IP address. 
If, every time a device disconnects and connects back, gets a random IP address, then the results will be unreliable.

Note: If LAN communication is unstable (example: using WiFi), some transient "disconnected" messages may occur. To compensate that, you can change the variables "scanPingRequests" and "monitorPingRequests" to higher values (but the script will run slower) 

[The thread model used in this script was based on a script published by Antonio Perez Ayala, a.k.a. Aacini (https://stackoverflow.com/a/32413876)]
