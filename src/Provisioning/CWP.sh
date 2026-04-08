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

log "Welcome to the CWP installer for CVE-2022-44877 on AlmaLinux 9!"

log "updating the apt cache"
sudo dnf update -yq

log "Setting hostname..."
sudo hostnamectl set-hostname cwp-vulnerable

log "Installing CWP (EL9 version)..."
cd /usr/local/src
wget http://centos-webpanel.com/cwp-el9-latest -O cwp-installer
chmod +x cwp-installer

log "Starting CWP installer (dit kan 10-20 minuten duren)..."
sudo ./cwp-installer

log "CWP installation finished!"
