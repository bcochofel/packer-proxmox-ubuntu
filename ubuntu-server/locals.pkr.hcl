locals {
  # VM settings
  node       = "pve"
  qemu_agent = true
  cpu_type   = "host"
  memory     = 2048
  sockets    = 1
  cores      = 2

  # disks settings
  scsi_controller = "virtio-scsi-single"
  type            = "scsi"
  disk_size       = "32G"
  format          = "raw"
  storage_pool    = "local-lvm"

  # network settings
  bridge   = "vmbr0"
  firewall = true

  # cloud-init settings
  ci              = true
  ci_storage_pool = "local-lvm"
}
