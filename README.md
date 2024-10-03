# Packer Images for Ubuntu
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![GitHub license](https://img.shields.io/github/license/bcochofel/packer-proxmox-ubuntu.svg)](https://github.com/bcochofel/packer-proxmox-ubuntu/blob/master/LICENSE)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/bcochofel/packer-proxmox-ubuntu)](https://github.com/bcochofel/packer-proxmox-ubuntu/tags)
[![GitHub issues](https://img.shields.io/github/issues/bcochofel/packer-proxmox-ubuntu.svg)](https://github.com/bcochofel/packer-proxmox-ubuntu/issues/)
[![GitHub forks](https://img.shields.io/github/forks/bcochofel/packer-proxmox-ubuntu.svg?style=social&label=Fork&maxAge=2592000)](https://github.com/bcochofel/packer-proxmox-ubuntu/network/)
[![GitHub stars](https://img.shields.io/github/stars/bcochofel/packer-proxmox-ubuntu.svg?style=social&label=Star&maxAge=2592000)](https://github.com/bcochofel/packer-proxmox-ubuntu/stargazers/)

Build Ubuntu Images for Proxmox using Packer

## Proxmox Setup

### Create Packer User

* login to your proxmox web GUI as root
* add packer user (ve)
* create group Packer
* add Group Permissions (PVEAdmin) to group Packer
* add user packer to group Packer

### Create API Token

* login to your proxmox web GUI as root
* Use new packer user, API Token, no expiry, copy secret.
* ensure Privilege Separation is not checked, otherwise this token doesn't get the packer users group permissions.

## Build

Create the ```secrets.pkrvars.hcl``` file with values from previous steps

```hcl
proxmox_url = "<your proxmox api url>"
proxmox_username = "<your proxmox user>"
proxmox_token = "<proxmox user api token>"
```

To build proxmox images for Ubuntu Server run (it will build all the sources defined in the folder)

```bash
packer build --var-file=secrets.pkrvars.hcl ubuntu-server/
```

## Running Packer from WSL2

To be able to run packer from WSL2 you need to change the network mode by creating a ```.wslconfig``` file

```init
# Settings apply across all Linux distros running on WSL 2
[wsl2]

# If the value is mirrored then this turns on mirrored networking mode. Default or unrecognized strings result in NAT networking.
networkingMode=mirrored

# Changes how DNS requests are proxied from WSL to Windows
dnsTunneling=true

# Enforces WSL to use Windows’ HTTP proxy information
autoProxy=true
```

To confirm if the mode is mirrored you can run the following command from WSL

```bash
wslinfo --networking-mode
```

and them create Firewall rules from a powershell terminal (admin)

The following sequence creates a Firewall Rule to allow TCP Inbound traffic through ports 8000-9000 (the default ports packer uses for the webserver)

```shell
wsl --version
Get-NetFirewallHyperVVMCreator
Get-NetFirewallHyperVVMSetting -PolicyStore ActiveStore -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
New-NetFirewallHyperVRule -Name Packer-Inbound -DisplayName "Packer Inbound range" -Direction Inbound -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -Protocol TCP -LocalPorts 8000-9000
Get-NetFirewallHyperVRule -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
```

Check references for more information

## References

- [Accessing Network Applications with WSL](https://learn.microsoft.com/en-us/windows/wsl/networking)
- [Configure Hyper-V firewall](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/hyper-v-firewall)
- [Packer Proxmox](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox)
- [Proxmox: Create a cloud-init Template VM with Packer](https://ronamosa.io/docs/engineer/LAB/proxmox-packer-vm/)
- [Ubuntu autoinstall](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)
