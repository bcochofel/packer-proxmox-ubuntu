packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# variables
variable "proxmox_url" {
  type        = string
  description = "URL to the Proxmox API"
  default     = "<proxmox url>"
}

variable "proxmox_username" {
  type        = string
  description = "Username when authenticating to Proxmox, including the realm."
  default     = "<proxmox api token id>"
}

variable "proxmox_token" {
  type        = string
  description = "Token for authenticating API calls."
  sensitive   = true
  default     = "<proxmox api token secret>"
}

# Resource Definition for the VM Template
source "proxmox-iso" "ubuntu" {

  # Proxmox Connection Settings
  proxmox_url = "${var.proxmox_url}"
  username    = "${var.proxmox_username}"
  token       = "${var.proxmox_token}"

  insecure_skip_tls_verify = true

  # VM General Settings
  node                 = "pve"
  vm_name              = "ubuntu-jammy-tmpl"
  template_description = "Ubuntu Jammy Server Image"

  # VM OS Settings
  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
    unmount  = true
  }

  # VM System Settings
  qemu_agent = true

  # VM CPU/Memory Settings
  cpu_type = "host"
  memory   = 2048
  sockets  = 1
  cores    = 2

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-single"

  disks {
    type         = "scsi"
    disk_size    = "32G"
    format       = "raw"
    storage_pool = "local-lvm"
  }

  # VM Network Settings
  network_adapters {
    bridge   = "vmbr0"
    firewall = true
  }

  # VM cloud-init Settings
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # Packer Boot Commands
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot      = "c"
  boot_wait = "5s"

  # Packer Autoinstall Settings
  http_directory = "http"
  http_interface = "eth0"

  # Packer SSH Settings
  ssh_username         = "bcochofel"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  # if ssh key has password use the agent
  #ssh_agent_auth = true

  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

  name    = "ubuntu-server-jammy"
  sources = ["source.proxmox-iso.ubuntu"]

  # sealing virtual machine
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  # cloud-init integration in Proxmox
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # cloud-init integration in Proxmox
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # docker installation
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }
}
