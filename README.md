# scan_lan_ip_monitor

Target OS: Windows

This script will ping all IP's on a specified LAN to identify which IP addresses are in use by connected devices. 

Performing a ping sweep, it will also update the local ARP table, which will be used to get the MAC addresses.

Having the list of identified connected devices, the script will loop indefinitely through the identified connected devices list, checking if they are connected or not.

If a device using a previously scanned IP address is disconnected, a "disconnected device" message with respective IP and MAC addresses is shown.

To stop the infinite loop, press Ctrl^C and (Y)es.

Note: If LAN communication is unstable (example: using WiFi), some transient "disconnected" events may occur. To compensate that, you can change the variables "scanPingRequests" and "monitorPingRequests" to higher values (but the script will run slower) 

[The thread model used in this script was based on a script published by Antonio Perez Ayala, a.k.a. Aacini (https://stackoverflow.com/a/32413876)]
