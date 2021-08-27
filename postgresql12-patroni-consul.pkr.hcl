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

source "triton" "postgresql12-patroni-consul" {
  image_name    = "postgresql12-patroni-consul"
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
  sources = ["source.triton.postgresql12-patroni-consul"]

  provisioner "file" {
    source = "${path.root}/smf_manifests/consul.xml"
    destination = "/opt/consul.xml"
  }

  provisioner "file" {
    source = "${path.root}/smf_manifests/patroni.xml"
    destination = "/opt/patroni.xml"
  }

  provisioner "shell" {
    inline = [
      "pkgin -y update",
      "pkgin -y install postgresql12-server",

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

      # GCC 9 (required for Patroni)
      "pkgin -y install gcc9",

      # Psycopg2
      "pkgin -y install py38-psycopg2",

      # PIP
      "python3.8 -m ensurepip --upgrade",
      "python3.8 -m pip install --upgrade pip",

      # Patroni
      "pip3 install patroni[consul]",

      # Postgresql sets up its own database - we delete it here so patroni has full control
      "rm -rf /var/pgsql/data/*",

      # Build postgresql by hand and install it over the top of the package version.
      # This is done because the packaged version builds with Kerberos support which
      # core dumps when running under Patroni.
      "pkgin -y install gmake",
      "wget https://ftp.postgresql.org/pub/source/v12.8/postgresql-12.8.tar.bz2 -O /tmp/postgresql-12.8.tar.bz2",
      "tar xjvf /tmp/postgresql-12.8.tar.bz2 -C /root",
      "mkdir -p /tmp/pgsql",
      "cd /tmp/pgsql ; /root/postgresql-12.8/configure --prefix=/opt/local/",
      "gmake -C /tmp/pgsql install",

      "rm -rf /root/postgresql-12.8",

      # Install the patroni service xml
      "svccfg import /opt/patroni.xml",

      # Build and install pgbackrest
      "pkgin -y install git",
      "pkgin -y install pkg-config",
      "pkgin -y install libyaml",
      "git clone https://github.com/CoolpeopleNetworks/pgbackrest.git /tmp/pgbackrest -b illumos_fixes",
      "cd /tmp/pgbackrest/src && LIBS=-lsocket ./configure --prefix=/opt/local",
      "cd /tmp/pgbackrest/src && LIBS=-lsocket make install",
    ]
  }

  provisioner "file" {
    source = "${path.root}/postgresql12-patroni/patroni.yml"
    destination = "/var/pgsql/patroni.yml"
  }
}
