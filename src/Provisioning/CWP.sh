#!/usr/bin/env bash


#------------------------------------------------------------------------------
# Bash settings
#------------------------------------------------------------------------------
set -o errexit 
set -o nounset 
set -o pipefail  

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

# Set to 'yes' if debug messages should be printed.
readonly debug_output='yes'


#------------------------------------------------------------------------------
# Helper functions
#------------------------------------------------------------------------------
# Three levels of logging are provided: log (for messages you always want to
# see), debug (for debug output that you only want to see if specified), and
# error (obviously, for error messages).

# Usage: log [ARG]...
# Prints all arguments on the standard error stream
log() {
  printf '\e[0;33m[LOG]  %s\e[0m\n' "${*}"
}

# Usage: debug [ARG]...
# Prints all arguments on the standard error stream
debug() {
  if [ "${debug_output}" = 'yes' ]; then
    printf '\e[0;36m[DBG] %s\e[0m\n' "${*}"
  fi
}

# Usage: error [ARG]...
# Prints all arguments on the standard error stream
error() {
  printf '\e[0;31m[ERR] %s\e[0m\n' "${*}" 1>&2
}


#------------------------------------------------------------------------------
# SETUP
#------------------------------------------------------------------------------

log "Welcome to the CWP installer for CVE-2022-44877 on Rocky 8!"

log "Changing keyboard layout to Azerty"

sudo localectl set-keymap be

log "installing epel-repo"

sudo dnf install -y epel-release

log "Installing needed packages"

sudo dnf install -y \
  wget \
  unzip

log "disabling selinux" 

sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config


log "Setting hostname..."

sudo hostnamectl set-hostname cwp-vulnerable

log "Installing CWP (CentOS 8 version)..."

cd /usr/local/src

log "Downloading the installation script for cwp" 

sudo wget http://centos-webpanel.com/cwp-el8-latest -O cwp-el8-latest

log "Downloading an exploitable version of cwp"

sudo wget http://static.cdn-cwp.com/files/cwp/el7/cwp-el7-0.9.8.1146.zip -O cwp-1146.zip

sudo unzip -o -q cwp-1146.zip
sudo rm -f cwp-1146.zip

# starting installer
log "Starting CWP installer (dit kan 10-20 minuten duren)..."

sudo sh ./cwp-el8-latest


log "Changing the installation script to use the older exploitable files"

# Replace the vulnerable files (this is what makes it exploitable)
sudo cp -rf cwp-el7-0.9.8.1146/public_html/* /usr/local/cwpsrv/htdocs/resources/admin/ 
sudo cp -rf cwp-el7-0.9.8.1146/public_html/* /usr/local/cwpsrv/htdocs/resources/client/

# Fix permissions
sudo chown -R cwpsrv:cwpsrv /usr/local/cwpsrv/htdocs/resources/admin
sudo chown -R cwpsrv:cwpsrv /usr/local/cwpsrv/htdocs/resources/client

log "Blocking all updates for CWP"

sed -i '/update.centos-webpanel.com/d' /etc/hosts 
sed -i '/static.cdn-cwp.com/d' /etc/hosts 
sed -i '/dl1.centos-webpanel.com/d' /etc/hosts 

cat >> /etc/hosts << EOF

# === BLOCK CWP AUTO UPDATES ===
0.0.0.0 update.centos-webpanel.com
0.0.0.0 static.cdn-cwp.com
0.0.0.0 dl1.centos-webpanel.com
0.0.0.0 dl2.centos-webpanel.com
0.0.0.0 centos-webpanel.com
EOF

# Restart services
log "Restart services"

sudo systemctl restart cwpsrv
sudo systemctl restart httpd

log "CWP installation finished!"

log "Please reboot the VM"
exit 0
