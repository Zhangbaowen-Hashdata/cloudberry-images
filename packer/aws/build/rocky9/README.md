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
│               ├── configs
│               │   ├── 90-db-limits.conf
│               │   └── 90-db-sysctl.conf
│               ├── main.pkr.hcl
│               ├── scripts
│               │   ├── gpadmin-setup.sh
│               │   ├── install-packages.sh
│               │   ├── post-build.sh
│               │   └── pre-build.sh
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

1. **Run pre-build script**

   This script generates a new SSH key pair, validates the Packer template, and initiates the Packer build process.

   ```bash
   ./scripts/pre-build.sh
   ```

2. **Run post-build script (if needed)**

   This script performs any necessary cleanup or additional steps after the Packer build is complete.

   ```bash
   ./scripts/post-build.sh
   ```

## Testing

Testinfra is used to perform validation tests on the launched EC2 instance. The tests are defined in `tests/testinfra/test_vm.py`.

1. **Run the tests**

   The tests are executed automatically by the `pre-build.sh` script after launching the EC2 instance. However, you can run them manually if needed:

   ```bash
   pytest --hosts=<hostname> tests/testinfra/test_vm.py
   ```

## Cleaning Up

The `pre-build.sh` script includes a cleanup function that terminates the EC2 instance and deletes the temporary key pair used during the build process.

## Contributing

Feel free to open issues or submit pull requests with improvements.

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](https://www.apache.org/licenses/LICENSE-2.0) file for details.
```

## Last Updated

2024-08-07
