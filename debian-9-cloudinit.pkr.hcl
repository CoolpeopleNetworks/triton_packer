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
      "apt-get install -y python3-jsonschema python3-configobj python3-jinja2 python3-jsonpatch python3-oauthlib python3-yaml gdisk net-tools",
      "wget http://ftp.us.debian.org/debian/pool/main/c/cloud-init/cloud-init_20.4.1-2_all.deb -O /tmp/cloud-init_20.4.1-2_all.deb",
      "dpkg -i /tmp/cloud-init_20.4.1-2_all.deb",
      "systemctl enable cloud-init",
    ]
  }
}
