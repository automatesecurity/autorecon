#!/bin/bash
# Recon automation script v1.0
# Daniel Wood twitter.com/expl01tat10n
# https://github.com/automatesecurity

# This script aids in identifying lives hosts on a network; useful for network penetration tests
# TODO: Automate bulk service exploitation chaining


if [ -z "$1" ]
then
    echo "Usage: ./recon.sh <IP ADDRESSES/CIDR>"
    exit 1
fi

printf "\n"
printf "   _____                     _____\n"
printf "  (, /   )                  (, /  |\n"
printf "    /__ /  _  _  _____        /---|     _/_ ______   _  _/_ _____\n"
printf " ) /   \__(/_(__(_) / (_   ) /    |_(_(_(__(_) // (_(_(_(__(_)/ (_\n"
printf "(_/                       (_/"
printf "\nRECON AUTOMATOR V1.0"
printf "\nby expl01tat10n\n"
printf "\n"
banner()
{
    echo "+------------------------------+"
    printf "|`tput bold` %-28s `tput sgr0`|\n" "$@"
    echo "+------------------------------+"
}

# Setup initial folder structure
mkdir scans

# Conduct initial ping sweep against supplied target(s)
# Output results to targets.txt and stdout
# Clean up temp 1
nmap -n -sn $1 -oG - | awk '/Up$/{print $2}' > temp1
banner "PERFORMING NETWORK DISCOVERY"
printf "Finding live hosts...\n"
cat temp1 | tee targets.txt
rm temp1

# Setup counter
i=0

# Loop through targets contained within targets.txt
for target in $(cat targets.txt)
do
    # Make folder structure for each target
    mkdir "scans/$target"
    mkdir "scans/$target/exploits"
    mkdir "scans/$target/findings"
    mkdir "scans/$target/loot"
    mkdir "scans/$target/notes"
    mkdir "scans/$target/screenshots"

    # Load each target into nmap and conduct initial scan
    banner "NMAP" > results
    printf "\nRunning Nmap on...$target\n"
    # Run Top 1000 TCP port scan per target and output
    nmap -sC -sV --top-ports 10 $target -oA scans/$target/$target | tail -n +5 | head -n -3 >> results
    # TODO UDP Top 1000 scans
    # nmap -sUV -T4 -F --top-ports 100 --version-intensity 0  $target
    # Delete this and next line once top 1000 is working properly
    # nmap -sC -sV $target | tail -n +5 | head -n -3 | tee scans/$target/$target.nmap >> results

    while read line
    do
        if [[ $line == *open* ]] && [[ $line == *http* ]]
        then
            printf "\nRunning Gobuster on...$target"
            # Runs gobuster using specified wordlist against target and hides banner and progress
            gobuster dir -u $target -w /usr/share/wordlists/dirb/common.txt -qz | tee scans/$target/$target.web >> temp2

            #printf "\nRunning GoWitness on...$target"
            # This assumes gowitness is located in the same directory as autorecon.sh or added to your path
            # You can find gowitness here: https://github.com/sensepost/gowitness
            # You will also need to ensure that you have Chrome Headless installed
            #printf "\nYou can view the screenshots in the screenshots folder manually or run gowitness report serve"
            #./gowitness single http://$target
            ./gowitness nmap --file scans/$target/$target.xml --service http --service https

            printf "\nRunning WhatWeb on...$target\n"
            whatweb $target -v >> scans/$target/$target.web && >> temp3

        fi
    done < results

    if [ -e temp2 ]
    then
        banner "Web Directories" >> results
        cat temp2 >> results
        rm temp2
    fi

    if [ -e temp3 ]
    then
        banner "Web Services" >> results
        cat temp3 >> results
        rm temp3
    fi
    i=$((i+1))
    cat results
done

# Clean-up
rm results

printf "\nFinished scanning $i targets\n\n"

# Compile services from nmap scans
mkdir "scans/services"
printf "Compiling targets by service...\n"
grep -r -e "139/open" -e "445/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/smb_hosts.txt >/dev/null
grep -r "21/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/ftp_hosts.txt >/dev/null
grep -r "22/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/ssh_hosts.txt >/dev/null
grep -r "23/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/telnet_hosts.txt >/dev/null
grep -r "25/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/smtp_hosts.txt >/dev/null
grep -r "53/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/dns_hosts.txt >/dev/null
grep -r -e "5800/open" -e "5900/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/vnc_hosts.txt >/dev/null
grep -r "1433/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/mssql_hosts.txt >/dev/null
grep -r "3306/open" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/mysql_hosts.txt >/dev/null
grep -r -i "sharp" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/sharp_hosts.txt >/dev/null
grep -r -i "ricoh" --include="*.gnmap" scans/* | cut -d " " -f2 | sort -u | tee scans/services/ricoh_hosts.txt >/dev/null

banner "Services at a glance"
wc -l scans/services/*

# TODO service specific scanning from the above
# EOF
