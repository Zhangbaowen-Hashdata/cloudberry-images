#!/bin/bash

# Note: If the Go version is updated, remember to update the corresponding testinfra test
# script (test_golang_install.py) to verify the correct version.

# Enable strict mode for better error handling
set -euo pipefail

# Header indicating the script execution
echo "Executing system_add_golang.sh..."

# Official GO Download page - https://go.dev/dl/
# Hardcoded Go version and SHA256 checksum
GO_VERSION="go1.22.6"
GO_SHA256="999805bed7d9039ec3da1a53bfbcafc13e367da52aa823cb60b68ba22d44c616"
GO_URL="https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"

echo "GO_VERSION=${GO_VERSION}"

# Download Go tarball
wget -nv "${GO_URL}"

# Verify the checksum
echo "${GO_SHA256}  ${GO_VERSION}.linux-amd64.tar.gz" | sha256sum -c -

# Extract and move Go
tar xf "${GO_VERSION}.linux-amd64.tar.gz"
sudo mv go "/usr/local/${GO_VERSION}"
rm -f "${GO_VERSION}.linux-amd64.tar.gz"

# Update the symbolic link
sudo rm -rf /usr/local/go
sudo ln -s "/usr/local/${GO_VERSION}" /usr/local/go

# Ensure /usr/local/go/bin is in the PATH for all users
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile.d/go.sh > /dev/null

# Apply the new PATH to the current session
export PATH=$PATH:/usr/local/go/bin

# Verify installation
/usr/local/go/bin/go version

# Footer indicating the script execution is complete
echo "system_add_golang.sh execution completed."
