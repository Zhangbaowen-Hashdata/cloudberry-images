#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Header indicating the script execution
echo "Executing system_add_gpadmin_ulimits.sh..."

# Create the limits configuration file for gpadmin
cat <<'EOF' | sudo tee /etc/security/limits.d/90-db-limits.conf
# /etc/security/limits.d/90-db-limits.conf

# Core dump file size limits for gpadmin
gpadmin soft core unlimited
gpadmin hard core unlimited

# Open file limits for gpadmin
gpadmin soft nofile 524288
gpadmin hard nofile 524288

# Process limits for gpadmin
gpadmin soft nproc 131072
gpadmin hard nproc 131072
EOF

# Set ownership and permissions for the limits configuration file
sudo chown root:root /etc/security/limits.d/90-db-limits.conf
sudo chmod 644 /etc/security/limits.d/90-db-limits.conf

# Footer indicating the script execution is complete
echo "system_add_gpadmin_ulimits.sh execution completed."
