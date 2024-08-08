#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Header indicating the script execution
echo "Executing system_add_action_runner.sh..."

# Install necessary packages
# -d0 suppresses output, -y automatically answers yes to prompts
sudo dnf install -d0 -y wget curl jq git docker

# Install Amazon CloudWatch Agent
sudo dnf install -y https://amazoncloudwatch-agent.s3.amazonaws.com/centos/amd64/latest/amazon-cloudwatch-agent.rpm

# Download CloudWatch Agent configuration
sudo wget -nv -q https://gist.githubusercontent.com/csereno/deac72776418173c4f3169b3f34c1246/raw/a21ea0f5c5fe2b5729e81abc411c4379b759196d/CloudWatchAgentConfig.json -O /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Restart and enable Amazon CloudWatch Agent
sudo systemctl restart amazon-cloudwatch-agent
sudo systemctl status amazon-cloudwatch-agent
sudo systemctl enable amazon-cloudwatch-agent

# Install Amazon SSM Agent
sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

# Start and enable Amazon SSM Agent
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

# Footer indicating the script execution is complete
echo "system_add_action_runner.sh execution completed."
