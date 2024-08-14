#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Function to display usage information
usage() {
  echo "Usage: $0 -a <ami-id> [-r <region>] [-k <key-name>] [-s <instance-size>] [-t <tests>] [-n]"
  echo "  -a <ami-id>           AMI ID to use for the instance."
  echo "  -r <region>]          AWS region to use (default: us-west-1)."
  echo "  -k <key-name>]        Name of the SSH key pair (default: auto-generated)."
  echo "  -s <instance-size>]   Size of the instance to launch (default: t3.medium)."
  echo "  -t <tests>]           Path to the Testinfra tests (default: tests/testinfra/test_vm.py)."
  echo "  -n                    Retain infrastructure on error (default: cleanup on error)."
  exit 1
}

# Check if required commands are installed
for cmd in aws curl nc pytest; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed." >&2
    exit 1
  fi
done

# Default values for optional parameters
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REGION="us-west-1"
INSTANCE_SIZE="t3.medium"
TESTS_PATH="tests/testinfra/test_vm.py"
CLEANUP_ON_ERROR=true

# Parse options
while getopts ":a:r:k:s:t:n" opt; do
  case ${opt} in
    a)
      AMI_ID=${OPTARG}
      ;;
    r)
      REGION=${OPTARG}
      ;;
    k)
      KEY_NAME=${OPTARG}
      ;;
    s)
      INSTANCE_SIZE=${OPTARG}
      ;;
    t)
      TESTS_PATH=${OPTARG}
      ;;
    n)
      CLEANUP_ON_ERROR=false
      ;;
    *)
      usage
      ;;
  esac
done

# Check for required parameters
if [ -z "${AMI_ID:-}" ]; then
  usage
fi

# Validate AMI ID
if ! aws ec2 describe-images --image-ids "${AMI_ID}" --region "${REGION}" > /dev/null 2>&1; then
  echo "Error: Invalid AMI ID ${AMI_ID}" >&2
  exit 1
fi

# Generate a unique key pair name if not provided
if [ -z "${KEY_NAME:-}" ]; then
  TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
  KEY_NAME="key-run-tests-${TIMESTAMP}"
fi

# Variables
PRIVATE_KEY_FILE="${KEY_NAME}.pem"
INSTANCE_ID=""
HOSTNAME=""
SECURITY_GROUP_NAME="run-tests-sg-${TIMESTAMP}"
SECURITY_GROUP_ID=""

# Function to clean up resources
cleanup() {
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
  echo "Cleanup completed."
}

# Set trap to clean up on EXIT and ERR signals
if $CLEANUP_ON_ERROR; then
  trap cleanup EXIT ERR
fi

# Create a new key pair
echo "Creating new key pair..."
aws ec2 create-key-pair --key-name ${KEY_NAME} --query 'KeyMaterial' --output text --region ${REGION} > ${PRIVATE_KEY_FILE}
chmod 400 ${PRIVATE_KEY_FILE}

echo "Created key pair ${KEY_NAME} and saved to ${PRIVATE_KEY_FILE}"

# Retrieve local IP address to restrict SSH access to the current machine
LOCAL_IP=$(curl -s http://checkip.amazonaws.com)/32

# Create a new security group
echo "Creating new security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "${SECURITY_GROUP_NAME}" --description "Security group for testing AMI ${AMI_ID}" --region ${REGION} --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr ${LOCAL_IP} --region ${REGION}

echo "Created security group ${SECURITY_GROUP_ID} with SSH access for IP ${LOCAL_IP}"

# Start a new EC2 instance using the provided AMI
echo "Starting a new EC2 instance..."
INSTANCE_NAME="run-tests-instance-${TIMESTAMP}"
INSTANCE_ID=$(aws ec2 run-instances --image-id ${AMI_ID} --instance-type ${INSTANCE_SIZE} --key-name ${KEY_NAME} --security-group-ids ${SECURITY_GROUP_ID} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" --query "Instances[0].InstanceId" --output text --region ${REGION})

# Wait until the instance is running
echo "Waiting for the instance to be in running state..."
aws ec2 wait instance-running --instance-ids ${INSTANCE_ID} --region ${REGION}

# Retrieve the public DNS name of the instance
HOSTNAME=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].PublicDnsName" --output text --region ${REGION})

# Display the SSH command to connect to the instance
echo -e "\nTo connect to the instance, run:"
echo "ssh -i ${PRIVATE_KEY_FILE} rocky@${HOSTNAME}"

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
    exit 1
  fi
done

# Run Testinfra tests with warnings suppressed
echo "Running Testinfra tests with warnings suppressed..."
pytest -p no:warnings --hosts=rocky@${HOSTNAME} --ssh-identity-file=${PRIVATE_KEY_FILE} "${PROJECT_ROOT}/tests/testinfra/"

# Cleanup resources if CLEANUP_ON_ERROR is false
if ! $CLEANUP_ON_ERROR; then
  echo "Cleanup is disabled due to the -n option."
else
  cleanup
fi

# Print completion message
echo "Test run and cleanup completed successfully."
