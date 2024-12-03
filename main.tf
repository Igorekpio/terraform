terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable "yandex_cloud_token" {
  type = string
  description = "Данная переменная потребует ввести секретный токен в консоли при запуске terraform plan/apply"
}

  provider "yandex" {
  token     = var.yandex_cloud_token
  cloud_id  = "cloud-vnponomareva140156"  # Замените на ваш Cloud ID
  folder_id = "b1gejcduilmppmanlg9u"  # Замените на ваш Folder ID
  zone      = "ru-central1-b"
}

data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# locals {
#   ssh-keys = file("~/.ssh/id_ed25519.pub")
#   ssh-private-keys = file("~/.ssh/id_ed25519")
#  }

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"
  hostname = "terraform1"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  
  metadata = {
    "user-data" = <<-EOF
      #cloud-config
      datasource:
        Ec2:
          strict_id: false
      ssh_pwauth: no
      users:
        - name: igorek
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
            - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII5IaOPt8mvBtt6KIKEvtu++Z3PaxNxJnSnCNxiibBIP igorek@ubuntovirtualmachine
    EOF
  serial-port-enable = 1  
  }
#  metadata = {
#    "ssh-keys" = "ubuntu:${file("/home/igorek/.ssh/id_ed25519.pub")}"
#    user-data = file("./meta.txt")
#    serial-port-enable = 1
#  }
}
   
  


output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}
output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}