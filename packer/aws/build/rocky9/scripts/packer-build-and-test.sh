#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Header indicating the script execution
echo "Executing packer-build-and-test.sh..."

# Function to check if a command is available
command_exists() {
  command -v "$1" &> /dev/null
}

# Check for required commands
for cmd in pytest packer aws jq nc curl; do
  if ! command_exists "$cmd"; then
    echo "$cmd could not be found. Please install $cmd to proceed."
    exit 1
  fi
done

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VM_TYPE=$(basename "$(dirname "$PROJECT_ROOT")")
OS_NAME="$(basename "$PROJECT_ROOT")"
REGION="us-west-1"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Variables
KEY_NAME="key-${VM_TYPE}-${OS_NAME}-${TIMESTAMP}"
PRIVATE_KEY_FILE="${SCRIPT_DIR}/${KEY_NAME}.pem"
SECURITY_GROUP_NAME="${VM_TYPE}-${OS_NAME}-${TIMESTAMP}-sg"
SECURITY_GROUP_ID=""
INSTANCE_ID=""
AMI_ID=""
HOSTNAME=""
AMI_NAME=""
CLEANED_UP=false
BLOCK_PUBLIC_ACCESS_WAS_ENABLED=false

# Function to rename AMI based on the test result
rename_ami() {
  local result=$1
  if [ -n "${AMI_ID}" ]; then
    NEW_NAME="${AMI_NAME}-${result}"
    echo "Renaming AMI to indicate ${result}: ${NEW_NAME}"
    # Update the tag of the AMI
    aws ec2 create-tags --resources ${AMI_ID} --tags Key=Name,Value=${NEW_NAME} --region ${REGION}
  fi
}

# Function to check if block public access is enabled
check_block_public_access() {
  echo "Checking if block public access for AMIs is enabled..."
  BLOCK_PUBLIC_ACCESS_STATE=$(aws ec2 get-image-block-public-access-state --region ${REGION} --output text)
  if [ "$BLOCK_PUBLIC_ACCESS_STATE" == "block-new-sharing" ]; then
    echo "Block public access for AMIs is enabled."
    BLOCK_PUBLIC_ACCESS_WAS_ENABLED=true
  else
    echo "Block public access for AMIs is not enabled."
    BLOCK_PUBLIC_ACCESS_WAS_ENABLED=false
  fi
}

# Function to disable image block public access
disable_image_block_public_access() {
  if [ "$BLOCK_PUBLIC_ACCESS_WAS_ENABLED" == "true" ]; then
    echo "Disabling block public access for AMIs..."
    aws ec2 disable-image-block-public-access --region ${REGION}
    echo "Block public access for AMIs disabled."
  fi
}

# Function to re-enable image block public access
enable_image_block_public_access() {
  if [ "$BLOCK_PUBLIC_ACCESS_WAS_ENABLED" == "true" ]; then
    echo "Re-enabling block public access for AMIs..."
    aws ec2 enable-image-block-public-access --region ${REGION} --image-block-public-access-state block-new-sharing
    echo "Block public access for AMIs re-enabled."
  fi
}

# Function to make the AMI public
make_ami_public() {
  if [ -n "${AMI_ID}" ]; then
    echo "Making AMI public: ${AMI_ID}"
    aws ec2 modify-image-attribute --image-id ${AMI_ID} --launch-permission "Add=[{Group=all}]" --region ${REGION}
  fi
}

# Function to verify the AMI launch permissions
verify_launch_permissions() {
  if [ -n "${AMI_ID}" ]; then
    echo "Verifying launch permissions for AMI: ${AMI_ID}"
    aws ec2 describe-image-attribute --image-id ${AMI_ID} --attribute launchPermission --region ${REGION}
  fi
}

# Function to clean up resources
cleanup() {
  if [ "$CLEANED_UP" = true ]; then
    return
  fi
  echo "Cleaning up..."
  if [ -n "${INSTANCE_ID}" ]; then
    echo "Terminating the EC2 instance..."
    aws ec2 terminate-instances --instance-ids ${INSTANCE_ID} --region ${REGION}
    aws ec2 wait instance-terminated --instance-ids ${INSTANCE_ID} --region ${REGION}
    echo "EC2 instance ${INSTANCE_ID} terminated successfully."
  fi
  if [ -f "${PRIVATE_KEY_FILE}" ]; then
    echo "Removing key file ${PRIVATE_KEY_FILE}"
    rm -f ${PRIVATE_KEY_FILE}
  fi
  if aws ec2 describe-key-pairs --key-name ${KEY_NAME} --region ${REGION} > /dev/null 2>&1; then
    echo "Deleting key pair ${KEY_NAME}"
    aws ec2 delete-key-pair --key-name ${KEY_NAME} --region ${REGION} || true
  fi
  if [ -n "${SECURITY_GROUP_ID}" ]; then
    echo "Deleting security group ${SECURITY_GROUP_ID}"
    aws ec2 delete-security-group --group-id ${SECURITY_GROUP_ID} --region ${REGION} || true
  fi
  CLEANED_UP=true
  echo "Cleanup completed."
}

# Function to handle errors
error_handler() {
  echo "An error occurred. Running cleanup and renaming AMI if necessary."
  rename_ami "FAILED"
  cleanup
  exit 1
}

# Set trap to clean up on EXIT and ERR signals
trap cleanup EXIT
trap error_handler ERR

# Validate the Packer template
echo "Validating Packer template..."
if ! packer validate -var "vm_type=${VM_TYPE}" -var "os_name=${OS_NAME}" "${PROJECT_ROOT}/main.pkr.hcl"; then
  echo "Packer template validation failed. Aborting."
  exit 1
fi

# Create a new key pair
echo "Creating new key pair..."
aws ec2 create-key-pair --key-name ${KEY_NAME} --query 'KeyMaterial' --output text --region ${REGION} > ${PRIVATE_KEY_FILE}
chmod 400 ${PRIVATE_KEY_FILE}

echo "Created key pair ${KEY_NAME} and saved to ${PRIVATE_KEY_FILE}"

# Build the Packer template
echo "Building the Packer template..."
packer build -var vm_type=${VM_TYPE} -var os_name=${OS_NAME} -var key_name=${KEY_NAME} -var private_key_file=${PRIVATE_KEY_FILE} "${PROJECT_ROOT}/main.pkr.hcl"

# Parse the AMI ID from the manifest file
echo "Parsing the AMI ID from packer-manifest.json..."
AMI_ID=$(jq -r '.builds[-1].artifact_id' packer-manifest.json | cut -d':' -f2)

# Retrieve the AMI name
AMI_NAME=$(aws ec2 describe-images --image-ids ${AMI_ID} --query "Images[*].Name" --output text --region ${REGION})

# Retrieve local IP address to restrict SSH access to the current machine
LOCAL_IP=$(curl -s http://checkip.amazonaws.com)/32

# Create a new security group
echo "Creating new security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "${SECURITY_GROUP_NAME}" --description "Security group for ${OS_NAME} ${VM_TYPE}" --region ${REGION} --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr ${LOCAL_IP} --region ${REGION}

echo "Created security group ${SECURITY_GROUP_ID} with SSH access for IP ${LOCAL_IP}"

# Start a new EC2 instance using the created AMI
echo "Starting a new EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances --image-id ${AMI_ID} --instance-type t3.medium --key-name ${KEY_NAME} --security-group-ids ${SECURITY_GROUP_ID} --query "Instances[0].InstanceId" --output text --region ${REGION})

# Wait until the instance is running
echo "Waiting for the instance to be in running state..."
aws ec2 wait instance-running --instance-ids ${INSTANCE_ID} --region ${REGION}

# Retrieve the public DNS name of the instance
HOSTNAME=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].PublicDnsName" --output text --region ${REGION})

# Loop until SSH access is available
echo "Waiting for SSH to become available on ${HOSTNAME}..."
for ((i=1; i<=30; i++)); do
  if nc -zv ${HOSTNAME} 22 2>&1 | grep -q 'succeeded'; then
    echo "SSH is available on ${HOSTNAME}"
    break
  else
    echo "SSH is not available yet. Retry $i/30..."
    sleep 10
  fi

  if [ $i -eq 30 ]; then
    echo "SSH is still not available after 30 attempts. Exiting."
    rename_ami "FAILED"
    cleanup
    exit 1
  fi
done

# Run Testinfra tests with warnings suppressed
echo "Running Testinfra tests..."
pytest -p no:warnings --hosts=rocky@${HOSTNAME} --ssh-identity-file=${PRIVATE_KEY_FILE} "${PROJECT_ROOT}/tests/testinfra/"

# Rename the AMI to indicate tests have passed
rename_ami "PASSED"

# Check and potentially disable block public access for AMIs
check_block_public_access
disable_image_block_public_access

# Make the AMI public
make_ami_public

# Verify the launch permissions of the AMI
verify_launch_permissions

# Re-enable block public access for AMIs if it was originally enabled
enable_image_block_public_access

# Print completion message
echo "packer-build-and-test.sh execution completed."
