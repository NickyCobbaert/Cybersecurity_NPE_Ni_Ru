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

log "Welcome to the CWP Exploit Simulator for CVE-2022-44877 on Rocky 8!"

log "Changing keyboard layout to Azerty"

sudo localectl set-keymap be

log "installing epel-repo"

sudo dnf install -y epel-release

log "Installing needed packages"

sudo dnf install -y \
  wget \
  unzip \
  lighttpd\
  php\
  php-cgi\
  php-fpm \
  lighttpd-fastcgi

log "Restarting enp0s8 driver"

sudo nmcli device disconnect enp0s8 
sudo nmcli device connect enp0s8 

IP_enp0s8="$(ip -br -4 a show enp0s8 | awk '{print $3}' | cut -d/ -f1)"

log "Enabling lighthttpd port"

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

log "Disabling selinux" 

sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

log "Setting hostname to cwp-vulnerable"

sudo hostnamectl set-hostname cwp-vulnerable

log "Configuring PHP-FPM to listen on TCP 9000"
# Rocky 8 defaults to a unix socket. So we switch it to TCP so Lighttpd can connect on port 9000.
sudo sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php-fpm.d/www.conf

log "Configuring Lighttpd to run PHP"

sudo mkdir -p /etc/lighttpd/conf.d
cat << _EOF_ | sudo tee /etc/lighttpd/conf.d/php.conf
server.modules += ( "mod_fastcgi" )
fastcgi.server += ( ".php" =>
  ((
    "host" => "127.0.0.1",
    "port" => "9000",
    "broken-scriptfilename" => "enable"
  ))
)
_EOF_

if grep -qxF 'include "conf.d/php.conf"' /etc/lighttpd/lighttpd.conf  
  then 
    true
    # nothing because conf.d/php.conf is already included in /etc/lighttpd/lighttpd.conf
  else
    echo 'include "conf.d/php.conf"' | sudo tee -a /etc/lighttpd/lighttpd.conf
fi

log "Lighthttpd will now bind to IPv4"

# removing duplicate ip's server.bind = "0.0.0.0"/d
sudo sed -i '/server.bind = "0.0.0.0"/d' /etc/lighttpd/lighttpd.conf

# adding 1 bind for Lighthttpd with ip 0.0.0.0
echo 'server.bind = "0.0.0.0"' | sudo tee -a /etc/lighttpd/lighttpd.conf

log "Creating the vulnerable CWP-style endpoint"

# Here we recreate the logic flaw that made CVE-2022-44877 possible.
sudo mkdir -p /var/www/lighttpd/login
cat << 'EOF' | sudo tee /var/www/lighttpd/login/index.php &> /dev/null
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['login'];
    
    // Because double quotes are used around the parameter, an attacker can use
    // command substitution, e.g., $(whoami) or `id`
    $log_command = "echo \"Failed login attempt for user: " . $username . "\" >> /tmp/cwp_failed_log.txt";
    
    // Execute the command (this is where the RCE happens)
    system($log_command);
    
    echo "Login failed. Incorrect credentials.";
} else {
    echo "<h1>CWP Control Panel (Simulated)</h1>";
    echo "<form method='POST'>";
    echo "Username: <input type='text' name='login'><br>";
    echo "Password: <input type='password' name='password'><br>";
    echo "<input type='submit' value='Login'>";
    echo "</form>";
}
?>
EOF

log "Changing permissions for Lighthttpd"
sudo chown -R lighttpd:lighttpd /var/www/lighttpd/
sudo sudo chmod -R 755 /var/www/lighttpd/

log "Starting the webserver"

sudo systemctl start php-fpm
sudo systemctl enable php-fpm
sudo systemctl restart lighttpd
sudo systemctl enable lighttpd

log "CVE-2022-44877 Simulator installation finished! ------------------------"


echo ""
log "To exploit the virtual machine, please use following curl command:"
log "curl -v -X POST -d 'login=admin\" ; echo "You have been hacked!!!" ; echo \"' http://$IP_enp0s8/login/index.php"
echo ""
echo ""
log "Thanks for using the CVE-2022-44877 Simulator installation script"

exit 0
