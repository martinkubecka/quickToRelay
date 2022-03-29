#!/bin/bash
##########################################
# Script Name   : quickToRelay
# Description   : Automate the process of setting up a Middle/Guard Tor Relay on Debian
# Author        : Martin Kubecka
# Last revised 2022/03/29
##########################################

# define colors
clear='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'

printf "${green}              _      _    _____     ____      _              ${clear}\n"
printf "${green}   __ _ _   _(_) ___| | _|_   _|__ |  _ \ ___| | __ _ _   _  ${clear}\n"
printf "${green}  / _\` | | | | |/ __| |/ / | |/ _ \| |_) / _ \ |/ _\` | | | | ${clear}\n"
printf "${green} | (_| | |_| | | (__|   <  | | (_) |  _ <  __/ | (_| | |_| | ${clear}\n"
printf "${green}  \__, |\__,_|_|\___|_|\_\ |_|\___/|_| \_\___|_|\__,_|\__, | ${clear}\n"
printf "${green}     |_|                                              |___/  ${clear}\n"
printf "                                                             \n"
printf "                                    by Martin Kubecka, 2022\n"

printf "${yellow}\n[~] Updating repositories ...${clear}\n"
apt update

# -------------------------------- #
#    torrc file configuration	   #
# -------------------------------- #
printf "${yellow}\n[+] Configuration for torrc file${clear}\n"
read -p "Nickname : " Nickname
read -p "Email : " ContactInfo
read -p "ORPort : " ORPort

printf "\n${yellow}[?] Would you like to configure bandwidth limits for your relay traffic? [Y/n] : ${clear}"
read Option1
if [[ ${Option1} == "Y" || ${Option1} == "y" ]] ; then
    read -p "Relay Bandwidth Rate (KB/s) : " RelayBandwidthRateSet
    read -p "Relay Bandwidth Burst (KB/s) : " RelayBandwidthBurstSet
    RelayBandwidthRate="RelayBandwidthRate ${RelayBandwidthRateSet}"
    RelayBandwidthBurst="RelayBandwidthBurst ${RelayBandwidthBurstSet}"
else
    RelayBandwidthRate="#RelayBandwidthRate 100KB"
    RelayBandwidthBurst="#RelayBandwidthBurst 200KB"
fi

printf "\n${yellow}[?] Would you like to configure accounting limits for your relay traffic? [Y/n] : ${clear}"
read Option2
if [[ ${Option2} == "Y" || ${Option2} == "y" ]] ; then
    read -p "Accounting Max : " AccountingMaxSet
    read -p "Accounting Start : " AccountingStartSet
    AccountingMax="AccountingMax ${AccountingMaxSet}"
    AccountingStart="AccountingStart ${AccountingStartSet}"
else
    AccountingMax="#AccountingMax 4 GB"
    AccountingStart="#AccountingStart day 00:00"
fi

# -------------------------------- #
#   ufw firewall configuration     #
# -------------------------------- #
printf "\n${yellow}[?] Would you like to open ports with ufw? [Y/n] : ${clear}"
read Option3
if [[ ${Option3} == "Y" || ${Option3} == "y" ]] ; then
    if ! [[ -x "$(command -v ufw)" ]] ; then
        printf "\n${yellow}[~] Installing ufw ....${clear}\n"
        apt install ufw -y
    fi
    printf "\n${yellow}[~] Allowing port 22 and chosen ORPort ....${clear}\n"
    ufw allow ssh
    ufw allow ${ORPort}
    printf "\n${yellow}[~] Enabling ufw ....${clear}\n"
    ufw --force enable
    printf "\n${yellow}[~] Listing ufw rules ....${clear}\n"
    ufw status
else
    printf "\n${red}[!] Do not forget to open your chosen ORPort in your firewall.${clear}\n"
fi

# -------------------------------- #
#     enable automatic updates     #
# -------------------------------- #
#printf "${yellow}\n[~] Updating repositories ...${clear}\n"
#apt update

printf "\n${yellow}[~] Enabling automatic software updates ...${clear}\n"
apt install unattended-upgrades apt-listchanges -y
# create a backup file
cp /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.bak
# edit config
echo "" > /etc/apt/apt.conf.d/50unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOL
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=\${distro_codename},label=Debian-Security";
    "origin=TorProject";
};
Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::Automatic-Reboot "true";
EOL

# create a backup file
cp /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.bak
# edit config
echo "" > /etc/apt/apt.conf.d/20auto-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::AutocleanInterval "5";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Verbose "1";
EOL

# ---------------------------------- #
# configure Tor project's repository #
# ---------------------------------- #
printf "\n${yellow}[~] Verifying the CPU architecture ...${clear}\n"
# Prerequisite : verify the CPU architecture
architecture=`dpkg --print-architecture`

if [[ "${architecture}" == "amd64" || "${architecture}" == "arm64" || "${architecture}" == "i386" ]] ; then
    printf "${green}[*] Supported architecture${clear}\n"
else
    printf "${red}[!] Unsupported CPU architecture ...${clear}\n"
    printf "${red}[!] Exiting program ...${clear}\n"
    exit 1
fi

printf "\n${yellow}[~] Configuring Tor Project's repository ...${clear}\n"

# enable all package managers to access resources accessible over https
apt install apt-transport-https -y

# create tor.list file
printf "\n${yellow}[~] Creating the tor.list file ...${clear}\n"
touch /etc/apt/sources.list.d/tor.list

distrubution=`lsb_release -c | cut -d ":" -f2 | sed -e "s/[^ a-zA-Z']//g" -e 's/ \+/ /'`
printf "${yellow}[~] Writing to the tor.list file ...${clear}\n"
cat > /etc/apt/sources.list.d/tor.list << EOL
deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org ${distrubution} main
deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org ${distrubution} main
EOL

# add the gpg key used to sign the packages 
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

# ---------------------------------- #
# tor and tor debian keyring install #
# ---------------------------------- #
printf "\n${yellow}[~] Installing Tor and Tor Debian keyring ...${clear}\n"
apt update
apt install tor deb.torproject.org-keyring -y

# ---------------------------------- #
#     monitoring configuration       #
# ---------------------------------- #
printf "\n${yellow}[?] Would you like to install and configure Nyx for monitoring? [Y/n] : ${clear}"
read Option4
if [[ ${Option4} == "Y" || ${Option4} == "y" ]] ; then
    read -p "Control Port : " ControlPortSet
    ControlPort="ControlPort ${ControlPortSet}"
    read -p "Password for Control Port access : " Password
    HashedPassword=`tor --hash-password "${Password}" | sed -n '2p'`
    HashedControlPassword="HashedControlPassword ${HashedPassword}"
    # install nyx
    printf "\n${yellow}[~] Installing nyx ....${clear}\n"
    apt install nyx -y
else
    ControlPort="#ControlPort 9051"
    HashedControlPassword="#HashedControlPassword 16:872860B76453A77D60CA2BB8C1A7042072093276A3D701AD684053EC4C"
fi

# ---------------------------------- #
#    configuration of torrc file     #
# ---------------------------------- #
printf "\n${yellow}[~] Configuring torrc file ...${clear}\n"
cp /etc/tor/torrc /etc/tor/torrc.bak
cat > /etc/tor/torrc << EOL
## Configuration file for a middle/guard Tor relay 
## See 'man tor', or https://www.torproject.org/docs/tor-manual.html,
## for more options you can use in this file.

## Tor opens a socks proxy on port 9050 by default -- even if you don't
## configure one below. Set "SocksPort 0" if you plan to run Tor only
## as a relay, and not make any local application connections yourself.
SocksPort 0

## Logs go to stdout at level "notice" unless redirected by something
## else, like one of the below lines. You can have as many Log lines as
## you want.
##
## We advise using "notice" in most cases, since anything more verbose
## may provide sensitive information to an attacker who obtains the logs.
##
## Send all messages of level 'notice' or higher to /var/log/tor/notices.log
#Log notice file /var/log/tor/notices.log
## Send every possible message to /var/log/tor/debug.log
#Log debug file /var/log/tor/debug.log
## Use the system log instead of Tor's logfiles
#Log notice syslog
## To send all messages to stderr:
#Log debug stderr

## Uncomment this to start the process in the background... or use
## --runasdaemon 1 on the command line.
RunAsDaemon 1

################ This section is just for relays #####################
#
## See https://www.torproject.org/docs/tor-doc-relay for details.

## Required: what port to advertise for incoming Tor connections.
ORPort ${ORPort}

## A handle for your relay, so people don't have to refer to it by key.
Nickname ${Nickname}

## Define these to limit how much relayed traffic you will allow. Your
## own traffic is still unthrottled. Note that RelayBandwidthRate must
## be at least 20 KB.
## Note that units for these config options are bytes per second, not bits
## per second, and that prefixes are binary prefixes, i.e. 2^10, 2^20, etc.
#RelayBandwidthRate 100 KB  # Throttle traffic to 100KB/s (800Kbps)
#RelayBandwidthBurst 200 KB # But allow bursts up to 200KB/s (1600Kbps)
${RelayBandwidthRate}
${RelayBandwidthBurst}

## Use these to restrict the maximum traffic per day, week, or month.
## Note that this threshold applies separately to sent and received bytes,
## not to their sum: setting "4 GB" may allow up to 8 GB total before
## hibernating.
##
## Set a maximum of 4 gigabytes each way per period.
${AccountingMax}
## Each period starts daily at midnight (AccountingMax is per day)
#AccountingStart day 00:00
## Each period starts on the 3rd of the month at 15:00 (AccountingMax
## is per month)
#AccountingStart month 3 15:00
${AccountingStart}

## Administrative contact information for this relay or bridge. This line
## can be used to contact you if your relay or bridge is misconfigured or
## something else goes wrong.
ContactInfo ${ContactInfo}

## The port on which Tor will listen for local connections from Tor
## controller applications, as documented in control-spec.txt.
${ControlPort}
## If you enable the controlport, be sure to enable one of these
## authentication methods, to prevent attackers from accessing it.
${HashedControlPassword}
#CookieAuthentication 1

ExitRelay   0
EOL

# restart the service
printf "\n${yellow}[~] Restarting tor service ...${clear}\n"
systemctl restart tor@default

printf "\n${green}[*] Done${clear}\n\n"
