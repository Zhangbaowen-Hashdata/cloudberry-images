
# Cloudberry Images

This repository contains the configurations and scripts used to create images for Cloudberry Database. The images are built using [Packer](https://www.packer.io/) and are intended to be used on [Amazon Web Services (AWS)](https://aws.amazon.com/).

## Purpose

The goal of this repository is to automate the creation of virtual machine images tailored for the deployment and operation of Cloudberry Database. By leveraging Packer, we ensure that the images are consistently built, tested, and ready for use in various environments, specifically on AWS.

## Key Components

- **Packer Configuration**: The core of this repository is the Packer configuration files that define how the images are built, including the installation of necessary packages, configuration of system settings, and preparation of the environment for Cloudberry Database.
- **Scripts**: A collection of scripts used during the image creation process to configure the operating system, install dependencies, and set up necessary services.
- **Tests**: Automated tests to validate the created images, ensuring they meet the required standards and are ready for production use.

## Directory Structure and Usage

The directory structure gives information on the images being created:

```
cloudberry-images
├── LICENSE
└── packer
    └── aws
        └── build
            └── rocky9
                ├── README.md
                ├── main.pkr.hcl
                ├── scripts
                │   ├── gpadmin-configure-environment.sh
                │   ├── packer-build-and-test.sh
                │   ├── run-tests.sh
                │   ├── system_add_cbdb_build_rpm_dependencies.sh
                │   ├── system_add_gpadmin_ulimits.sh
                │   ├── system_add_kernel_configs.sh
                │   ├── system_adduser_gpadmin.sh
                │   └── system_disable_SELinux.sh
                └── tests
                    ├── requirements.txt
                    └── testinfra
                        └── test_vm.py
```

- **packer**: Indicates the use of Packer as the tool to build the image.
  - **aws**: Specifies that the images are intended for Amazon Web Services.
    - **build**: Indicates that the image is designed for building Cloudberry Database.
      - **rocky9**: Represents the OS version being used, in this case, Rocky Linux 9.

Over time, this structure will be expanded to provide other image types. For example, runtime testing images that do not require all build-time dependencies, and support for additional platforms.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
