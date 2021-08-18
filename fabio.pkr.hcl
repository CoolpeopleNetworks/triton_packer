variable "triton_url" {
    type = string
}

variable "triton_account" {
    type = string
}

variable "triton_key_id" {
    type = string
}

variable "image_version" {
    type = string
}

locals {
    consul_version="1.10.1"
}

packer {
    required_plugins {
        triton = {
            version = ">= 1.0.0"
            source  = "github.com/hashicorp/triton"
        }
    }
}

source "triton" "fabio" {
    image_name    = "fabio"
    image_version = "${var.image_version}"
    source_machine_image_filter {
        most_recent = "true"
        name        = "base-64-lts"
        type        = "zone-dataset"
    }

  source_machine_name    = "image_builder_${uuidv4()}"
    source_machine_package = "k1-highcpu-512m"
    ssh_username           = "root"

    triton_url = var.triton_url
    triton_account = var.triton_account
    triton_key_id = var.triton_key_id
}

build {
    sources = ["source.triton.fabio"]

    provisioner "file" {
        source = "${path.root}/smf_manifests/fabio.xml"
        destination = "/opt/fabio.xml"
    }

    provisioner "file" {
        source = "${path.root}/smf_manifests/consul.xml"
        destination = "/opt/consul.xml"
    }

    provisioner "shell" {
        inline = [
            "pkgin -y update",
            "pkgin -y install go116 git",

            # Install (but don't enable") consul.  
            "mkdir -p /opt/local/etc/consul.d/certificates",
            "mkdir -p /opt/local/consul",
            "useradd -d /opt/local/consul consul",
            "groupadd consul",
            "chown consul /opt/local/consul",
            "chgrp consul /opt/local/consul",

            "pkgin -y in wget unzip",
            "cd /tmp ; wget --no-check-certificate https://releases.hashicorp.com/consul/${local.consul_version}/consul_${local.consul_version}_solaris_amd64.zip",
            "cd /tmp ; unzip consul_${local.consul_version}_solaris_amd64.zip",
            "cd /tmp ; rm consul_${local.consul_version}_solaris_amd64.zip",

            "mv /tmp/consul /opt/local/bin/consul",

            "svccfg import /opt/consul.xml",

            # Install Fabio
            "go get github.com/fabiolb/fabio@v${var.image_version}",
            "cp /root/go/bin/fabio /opt/local/bin",
            "pkgin -y remove go116 git",
            "rm -rf /root/go",

            # Create fabio user
            "mkdir -p /opt/local/fabio",
            "useradd -d /opt/local/fabio fabio",
            "groupadd fabio",
            "chown fabio /opt/local/fabio",
            "chgrp fabio /opt/local/fabio",

            # Install the fabio service xml
            "svccfg import /opt/fabio.xml"
        ]
    }
}
