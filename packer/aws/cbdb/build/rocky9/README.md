
# cloudberry-images

## Overview

This project uses Packer to build an Amazon Machine Image (AMI) for Rocky Linux 9. The AMI is built using the `main.pkr.hcl` template and includes a set of provisioning scripts and configurations. After the AMI is created, an EC2 instance is launched from the AMI and tested using Testinfra.

## Directory Structure

```
cloudberry-images
├── packer
│   └── aws
│       └── build
│           └── rocky9
│               ├── README.md
│               ├── main.pkr.hcl
│               ├── scripts
│               │   ├── gpadmin-configure-environment.sh
│               │   ├── packer-build-and-test.sh
│               │   ├── run-tests.sh
│               │   ├── system_add_cbdb_build_rpm_dependencies.sh
│               │   ├── system_add_gpadmin_ulimits.sh
│               │   ├── system_add_kernel_configs.sh
│               │   ├── system_adduser_gpadmin.sh
│               │   ├── system_disable_SELinux.sh
│               │   └── system_disable_SELinux.sh
│               └── tests
│                   ├── requirements.txt
│                   └── testinfra
│                       └── test_vm.py
```

## Pre-requisites

- [Packer](https://www.packer.io/downloads)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Python 3](https://www.python.org/downloads/)
- [pip](https://pip.pypa.io/en/stable/installation/)

## Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-repo/cloudberry-images.git
   cd cloudberry-images/packer/aws/build/rocky9
   ```

2. **Install Python dependencies**

   ```bash
   pip install -r tests/requirements.txt
   ```

3. **Configure AWS CLI**

   Ensure you have configured your AWS CLI with the necessary credentials and region:

   ```bash
   aws configure
   ```

## Usage

1. **Run packer-build-and-test.sh script**

   This script generates a new SSH key pair, validates the Packer template, and initiates the Packer build process.

   ```bash
   ./scripts/packer-build-and-test.sh
   ```

   ### Additional Notes:
   - The script checks for the availability of required commands (`pytest`, `packer`, `aws`, `jq`, `nc`, `curl`).
   - It creates a new key pair and security group, and cleans up these resources after the build and test process.
   - The AMI is renamed based on the test result (e.g., "PASSED" or "FAILED").
   - Detailed logging is provided throughout the script to aid in troubleshooting.

2. **Run run-tests.sh script**

   This script launches an EC2 instance from a specified AMI, runs Testinfra tests against it, and then cleans up the resources.

   ```bash
   ./scripts/run-tests.sh -a <ami-id> [-r <region>] [-k <key-name>] [-s <instance-size>] [-t <tests>] [-n]
   ```

   ### Additional Notes:
   - The script validates the provided AMI ID and ensures all necessary commands are available (`aws`, `curl`, `nc`, `pytest`).
   - It creates a new key pair and security group, and cleans up these resources after the tests are run, unless the `-n` option is specified to retain infrastructure on error.
   - The script waits for SSH to become available on the instance before running the Testinfra tests.
   - The `-t` option allows specifying a custom path to the Testinfra tests (default: `tests/testinfra/test_vm.py`).

3. **Review and customize configuration files**

   Before running the build, review and, if necessary, customize the configuration files and scripts to match your specific requirements. This includes adjusting system settings, adding or removing packages, and modifying test scripts.

## Troubleshooting

If you encounter issues during the build process, check the following:

- Ensure all pre-requisites are installed and properly configured.
- Review the Packer and AWS CLI logs for detailed error messages.
- Verify network connectivity and AWS service availability.

## Contributing

Feel free to open issues or submit pull requests with improvements.

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](https://www.apache.org/licenses/LICENSE-2.0) file for details.
