#!/bin/bash
## ======================================================================
## Container Initialization Script
## ======================================================================
## This script sets up the environment inside the Docker container for
## the Cloudberry Database Build Environment. It performs the following
## tasks:
##
## 1. Verifies that the container is running with the expected hostname.
## 2. Starts the SSH daemon to allow SSH access to the container.
## 3. Configures passwordless SSH access for the 'gpadmin' user.
## 4. Displays a welcome banner and system information.
## 5. Starts an interactive bash shell.
##
## This script is intended to be used as an entrypoint or initialization
## script for the Docker container.
## ======================================================================

# ----------------------------------------------------------------------
# Check if the hostname is 'cdw'
# ----------------------------------------------------------------------
# The script checks if the container's hostname is set to 'cdw'. This is
# a requirement for this environment, and if the hostname does not match,
# the script will exit with an error message. This ensures consistency
# across different environments.
# ----------------------------------------------------------------------
if [ "$(hostname)" != "cdw" ]; then
    echo "Error: This container must be run with the hostname 'cdw'."
    echo "Use the following command: docker run -h cdw ..."
    exit 1
fi

# ----------------------------------------------------------------------
# Start SSH daemon and setup for SSH access
# ----------------------------------------------------------------------
# The SSH daemon is started to allow remote access to the container via
# SSH. This is useful for development and debugging purposes. If the SSH
# daemon fails to start, the script exits with an error.
# ----------------------------------------------------------------------
if ! sudo /usr/sbin/sshd; then
    echo "Failed to start SSH daemon" >&2
    exit 1
fi

# ----------------------------------------------------------------------
# Remove /run/nologin to allow logins
# ----------------------------------------------------------------------
# The /run/nologin file, if present, prevents users from logging into
# the system. This file is removed to ensure that users can log in via SSH.
# ----------------------------------------------------------------------
sudo rm -rf /run/nologin

# ----------------------------------------------------------------------
# Configure passwordless SSH access for 'gpadmin' user
# ----------------------------------------------------------------------
# The script sets up SSH key-based authentication for the 'gpadmin' user,
# allowing passwordless SSH access. It generates a new SSH key pair if one
# does not already exist, and configures the necessary permissions.
# ----------------------------------------------------------------------
mkdir -p /home/gpadmin/.ssh
chmod 700 /home/gpadmin/.ssh

if [ ! -f /home/gpadmin/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C gpadmin -f /home/gpadmin/.ssh/id_rsa -P "" > /dev/null 2>&1
fi

cat /home/gpadmin/.ssh/id_rsa.pub >> /home/gpadmin/.ssh/authorized_keys
chmod 600 /home/gpadmin/.ssh/authorized_keys

# Add the container's hostname to the known_hosts file to avoid SSH warnings
ssh-keyscan -t rsa cdw > /home/gpadmin/.ssh/known_hosts 2>/dev/null

# Change to the home directory of the current user
cd $HOME

# ----------------------------------------------------------------------
# Display a Welcome Banner
# ----------------------------------------------------------------------
# The following ASCII art and welcome message are displayed when the
# container starts. This banner provides a visual indication that the
# container is running in the Cloudberry Database Build Environment.
# ----------------------------------------------------------------------
cat <<-'EOF'

======================================================================

                          ++++++++++       ++++++
                        ++++++++++++++   +++++++
                       ++++        +++++ ++++
                      ++++          +++++++++
                   =+====         =============+
                 ========       =====+      =====
                ====  ====     ====           ====
               ====    ===     ===             ====
               ====            === ===         ====
               ====            ===  ==--       ===
                =====          ===== --       ====
                 =====================     ======
                   ============================
                                     =-----=
     ____  _                    _  _
    / ___|| |  ___   _   _   __| || |__    ___  _ __  _ __  _   _
   | |    | | / _ \ | | | | / _` || '_ \  / _ \| '__|| '__|| | | |
   | |___ | || (_) || |_| || (_| || |_) ||  __/| |   | |   | |_| |
    _____||_| \____  \__,_| \__,_||_.__/  \___||_|   |_|    \__, |
   |  _ \   __ _ | |_  __ _ | |__    __ _  ___   ___        |___/
   | | | | / _` || __|/ _` || '_ \  / _` |/ __| / _ \
   | |_| || (_| || |_| (_| || |_) || (_| |\__ \|  __/
   |____/  \__,_| \__|\__,_||_.__/  \__,_||___/ \___|

----------------------------------------------------------------------

EOF

# ----------------------------------------------------------------------
# Display System Information
# ----------------------------------------------------------------------
# The script sources the /etc/os-release file to retrieve the operating
# system name and version. It then displays the following information:
# - OS name and version
# - Current user
# - Container hostname
# - IP address
# - CPU model name and number of cores
# - Total memory available
# This information is useful for users to understand the environment they
# are working in.
# ----------------------------------------------------------------------
source /etc/os-release

cat <<-EOF
Welcome to the Cloudberry Database Build Environment!

Container OS ........ : $NAME $VERSION
User ................ : $(whoami)
Container hostname .. : $(hostname)
IP Address .......... : $(hostname -I | awk '{print $1}')
CPU Info ............ : $(lscpu | grep 'Model name:' | awk '{print substr($0, index($0,$3))}')
CPU(s) .............. : $(nproc)
Memory .............. : $(free -h | grep Mem: | awk '{print $2}') total
======================================================================

EOF

# ----------------------------------------------------------------------
# Start an interactive bash shell
# ----------------------------------------------------------------------
# Finally, the script starts an interactive bash shell to keep the
# container running and allow the user to interact with the environment.
# ----------------------------------------------------------------------
/bin/bash
