#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Header indicating the script execution
echo "Executing gpadmin-configure-environment.sh..."

# Execute the following commands as the gpadmin user
sudo -u gpadmin bash <<'EOF'
# Download and set up configuration files for gpadmin user
wget -nv -q https://gist.githubusercontent.com/simonista/8703722/raw/d08f2b4dc10452b97d3ca15386e9eed457a53c61/.vimrc -O /home/gpadmin/.vimrc
wget -nv -q https://raw.githubusercontent.com/tony/tmux-config/master/.tmux.conf -O /home/gpadmin/.tmux.conf

# Install Oh My Bash for gpadmin user
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended

# Add Cloudberry entries to gpadmin's .bashrc
echo -e '\n# Add Cloudberry entries\nif [ -f /usr/local/cbdb/greenplum_path.sh ]; then\n  source /usr/local/cbdb/greenplum_path.sh\nfi' >> /home/gpadmin/.bashrc
echo -e 'if [ -f /opt/src/cloudberrydb/gpAux/gpdemo/gpdemo-env.sh ]; then\n  source /opt/src/cloudberrydb/gpAux/gpdemo/gpdemo-env.sh\nfi' >> /home/gpadmin/.bashrc

# Generate SSH key pair for gpadmin user if it doesn't already exist
if [ ! -f /home/gpadmin/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 2048 -f /home/gpadmin/.ssh/id_rsa -N ""
fi

# Ensure the .ssh directory exists
mkdir -p /home/gpadmin/.ssh

# Add the public key to authorized_keys to enable passwordless SSH access
cat /home/gpadmin/.ssh/id_rsa.pub >> /home/gpadmin/.ssh/authorized_keys

# Set appropriate permissions for the .ssh directory and authorized_keys file
chmod 700 /home/gpadmin/.ssh
chmod 600 /home/gpadmin/.ssh/authorized_keys

# Ensure the public key is accessible
chmod 644 /home/gpadmin/.ssh/id_rsa.pub

echo "Environment setup and passwordless SSH configuration for gpadmin completed successfully."
EOF

# Footer indicating the script execution is complete
echo "gpadmin-configure-environment.sh execution completed."
