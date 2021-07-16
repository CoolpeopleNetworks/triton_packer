variable "triton_url" {
  type = string
}

variable "triton_account" {
  type = string
}

variable "triton_key_id" {
  type = string
}

packer {
  required_plugins {
    triton = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/triton"
    }
  }
}

source "triton" "debian-9-cloudinit" {
  image_name    = "debian-9-cloudinit"
  image_version = "1.0.0"
  source_machine_image_filter {
    most_recent = "true"
    name        = "debian-9"
    type        = "lx-dataset"
  }
  source_machine_name    = "image_builder"
  source_machine_package = "k1-highcpu-512m"
  ssh_username           = "root"

  triton_url = var.triton_url
  triton_account = var.triton_account
  triton_key_id = var.triton_key_id
}

build {
  sources = ["source.triton.debian-9-cloudinit"]

  provisioner "shell" {
    inline = [
      "apt-get update -y",
      "apt-get install -y ssh-import-id",
      "apt-get install -y cloud-init",
      "systemctl enable cloud-init",
    ]
  }
}
