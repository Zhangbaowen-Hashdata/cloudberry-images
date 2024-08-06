#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Header indicating the script execution
echo "Executing system_adduser_gpadmin.sh..."

# Create a group and user for gpadmin with sudo privileges
sudo groupadd gpadmin
sudo useradd -m -g gpadmin gpadmin

# Grant sudo privileges to gpadmin user without requiring a password
echo 'gpadmin ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/90-gpadmin

# Footer indicating the script execution is complete
echo "system_adduser_gpadmin.sh execution completed."
