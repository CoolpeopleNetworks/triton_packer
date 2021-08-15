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

packer {
  required_plugins {
    triton = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/triton"
    }
  }
}

source "triton" "postgresql12-patroni" {
  image_name    = "postgresql12-patroni"
  image_version = "${var.image_version}"
  source_machine_image_filter {
    most_recent = "true"
    name        = "base-64-lts"
    type        = "zone-dataset"
  }
  source_machine_name    = "image_builder_base64"
  source_machine_package = "k1-highcpu-512m"
  ssh_username           = "root"

  triton_url = var.triton_url
  triton_account = var.triton_account
  triton_key_id = var.triton_key_id
}

build {
  sources = ["source.triton.postgresql12-patroni"]

  provisioner "file" {
    source = "${path.root}/postgresql12-patroni/patroni.xml"
    destination = "/opt/patroni.xml"
  }

  provisioner "shell" {
    inline = [
      "pkgin -y update",
      "pkgin -y install postgresql12-server",

      # GCC 9 (required for Patroni)
      "pkgin -y install gcc9",

      # Psycopg2
      "pkgin -y install py38-psycopg2",

      # PIP
      "python3.8 -m ensurepip --upgrade",
      "python3.8 -m pip install --upgrade pip",

      # Patroni
      "pip3 install patroni",

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
      "svccfg import /opt/patroni.xml"
    ]
  }

  provisioner "file" {
    source = "${path.root}/postgresql12-patroni/patroni.yml"
    destination = "/var/pgsql/patroni.xml"
  }

}
