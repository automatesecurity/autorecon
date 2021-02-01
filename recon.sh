#!/bin/bash
# Recon automation script v1.0
# Daniel Wood twitter.com/expl01tat10n
# https://github.com/automatesecurity

# This script aids in identifying lives hosts on a network; useful for network penetration tests
# TODO: Implement Top TCP/UDP port scanning per host.
# TODO: Output service specific host files based on services discovered for bulk service scanning


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

banner()
{
    echo "+------------------------------+"
    printf "|`tput bold` %-28s `tput sgr0`|\n" "$@"
    echo "+------------------------------+"
}

mkdir scans
nmap -n -sn $1 -oG - | awk '/Up$/{print $2}' > temp1
banner "PERFORMING NETWORK DISCOVERY"
printf "\nFinding live hosts...\n"
cat temp1 | tee targets.txt
rm temp1

for target in $(cat targets.txt)
do
    mkdir "scans/$target"
    banner "NMAP" > results
    printf "\nRunning Nmap on...$target"
    nmap -sC -sV $target | tail -n +5 | head -n -3 | tee scans/$target/$target.nmap >> results

    while read line
    do
        if [[ $line == *open* ]] && [[ $line == *http* ]]
        then
            printf "\nRunning Gobuster on...$target"
            # Runs gobuster using specified wordlist against target and hides banner and progress
            gobuster dir -u $target -w /usr/share/wordlists/dirb/common.txt -qz | tee scans/$target/$target.web >> temp2

            # banner "\nRunning Aquatone for screenshots..."
            # aquatone -out /screenshots/

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

    printf "\n\nFinished\n"
    cat results
done
