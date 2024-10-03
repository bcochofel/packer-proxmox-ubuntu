# Ubuntu Jammy template
source "proxmox-iso" "jammy" {

  # Proxmox Connection Settings
  proxmox_url = "${var.proxmox_url}"
  username    = "${var.proxmox_username}"
  token       = "${var.proxmox_token}"

  insecure_skip_tls_verify = true

  # VM name
  vm_name              = "ubuntu-jammy-tmpl"
  template_description = "Ubuntu Jammy Server Image"

  # VM General Settings
  node = local.node

  # VM OS Settings
  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
    unmount  = true
  }

  # VM System Settings
  qemu_agent = local.qemu_agent

  # VM CPU/Memory Settings
  cpu_type = local.cpu_type
  memory   = local.memory
  sockets  = local.sockets
  cores    = local.cores

  # VM Hard Disk Settings
  scsi_controller = local.scsi_controller

  disks {
    type         = local.type
    disk_size    = local.disk_size
    format       = local.format
    storage_pool = local.storage_pool
  }

  # VM Network Settings
  network_adapters {
    bridge   = local.bridge
    firewall = local.firewall
  }

  # VM cloud-init Settings
  cloud_init              = local.ci
  cloud_init_storage_pool = local.ci_storage_pool

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
  http_directory = "${path.root}/http"
  http_interface = "eth0"

  # Packer SSH Settings
  ssh_username         = "bcochofel"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  # if ssh key has password use the agent
  #ssh_agent_auth = true

  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

# Ubuntu Noble template
source "proxmox-iso" "noble" {

  # Proxmox Connection Settings
  proxmox_url = "${var.proxmox_url}"
  username    = "${var.proxmox_username}"
  token       = "${var.proxmox_token}"

  insecure_skip_tls_verify = true

  # VM name
  vm_name              = "ubuntu-noble-tmpl"
  template_description = "Ubuntu Noble Server Image"

  # VM General Settings
  node = local.node

  # VM OS Settings
  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
    unmount  = true
  }

  # VM System Settings
  qemu_agent = local.qemu_agent

  # VM CPU/Memory Settings
  cpu_type = local.cpu_type
  memory   = local.memory
  sockets  = local.sockets
  cores    = local.cores

  # VM Hard Disk Settings
  scsi_controller = local.scsi_controller

  disks {
    type         = local.type
    disk_size    = local.disk_size
    format       = local.format
    storage_pool = local.storage_pool
  }

  # VM Network Settings
  network_adapters {
    bridge   = local.bridge
    firewall = local.firewall
  }

  # VM cloud-init Settings
  cloud_init              = local.ci
  cloud_init_storage_pool = local.ci_storage_pool

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
  http_directory = "${path.root}/http"
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
  sources = [
    "source.proxmox-iso.jammy",
    "source.proxmox-iso.noble"
  ]

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
    source      = "${path.root}/files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # cloud-init integration in Proxmox
  provisioner "shell" {
    inline = ["sudo install -m 644 -o root -g root /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # disable IPv6
  provisioner "shell" {
    script = "${path.root}/scripts/disable-ipv6.sh"
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
