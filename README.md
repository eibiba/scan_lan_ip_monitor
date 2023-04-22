# scan_lan_ip_monitor

This script will ping all IP's on a specified LAN to identify which IP addresses are in use by connected devices. 
Performing a ping sweep, it will also update the local ARP table, which will be used to get the MAC addresses.
Having the list of identified connected devices, the script will loop indefinitely through the identified connected devices list, checking if they are connected or not.
To stop the infinite loop, press Ctrl^C and (Y)es.

 [The thread model used in this script was based on a script published by Antonio Perez Ayala, a.k.a. Aacini (https://stackoverflow.com/a/32413876)]
