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

log "Welcome to the Apache 2.4.49 installer!"

log "updating the apt cache"

apt update -y 

#deleting gnome and installing the lighter lxqt

log "uninstalling gnome desktop"

apt -y purge task-gnome-desktop gnome gnome-core
apt -y purge gdm3
apt -y autoremove --purge

log "installing lxqt desktop"

apt install -y task-lxqt-desktop 


#installing compilation tools

log "installing compilation tools"

apt install -y build-essential libpcre3 libpcre3-dev libssl-dev libexpat1-dev wget libapr1-dev libaprutil1-dev

#downloading Apache 2.4.49 from source

log "Downloading the Apache 2.4.49 source code from the Apache archive"

wget -S -O /opt/httpd-2.4.49.tar.gz  https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.gz

#extraction

log "extracting the httpd-2.4.49.tar.gz tarball"

rm -rf /opt/httpd-2.4.49

tar -xzvf /opt/httpd-2.4.49.tar.gz -C /opt/

rm /opt/httpd-2.4.49.tar.gz

#configuration

log "Configuration the install location of Apache"

cd /opt/httpd-2.4.49

./configure --prefix=/usr/local/apache2 --enable-so --enable-ssl

#compilation using gnu make

log "Compiling the source code using Gnu Make"

log ""
log ""
log "This can take a while;"
log "Consider drinking coffee while listening to smooth jazz"
log ""

make 

log "Make has finished!"

#installation

log "Installation of the source code using Gnu Make"

make install

#startup

log "Starting Apache 2.4.49"

/usr/local/apache2/bin/apachectl start

log ""
log "Apache 2.4.49 is up and running!"
