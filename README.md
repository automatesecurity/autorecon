# autorecon
A simple script that automates the process of reconnaissance by scanning for live network hosts and then subsequently kicking off service specific scans. 

After executing a simple pingsweep (if using a CIDR for the target), this script currently scans for the Top 1000 TCP ports and services.  If an http/s service is detected, the script will run through a loop for each service and run gobuster, gowitness and whatweb to fingerprint and screenshot these services.

Upon completion, an extensive (and extensible) series of greps will step through the nmap scan files to identify open services that conform to the desired service batching and will output all IPs per service to a designated service file.  Future plans include automating basic service scanning for vulnerabilities to expedite and automate the identification of vulnerabilities.

## Usage
```./recon.sh <IP/CIDR>```

## Prerequisites
You will need the following installed:
* NMAP
* gobuster binary in the same directory as recon.sh
* WhatWeb (usually a part of Kali)

## TODO
* Implement more robust service scanning on live hosts
* Implement better bulk service output for data organization
* Implement runtime flags to control scanning behavior (e.g. TCP vs UDP)
