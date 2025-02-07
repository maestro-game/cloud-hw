variable YC_TOKEN {}
variable YC_CLOUD_ID {}
variable YC_FOLDER_ID {}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone      = "ru-central1-a"
  token     = var.YC_TOKEN
  cloud_id  = var.YC_CLOUD_ID
  folder_id = var.YC_FOLDER_ID
}

resource "yandex_vpc_network" "network" {
  name = "task4-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name       = "task4-subnet"
  zone       = "ru-central1-a"
  network_id = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "tls_private_key" "key" {
  algorithm = "ED25519"
}

resource "local_file" "private_key" {
  content  = tls_private_key.key.private_key_openssh
  filename = "./task4_private_key"
  file_permission = "0600"
}

resource "yandex_compute_instance" "vm_instance" {
  name        = "task4_vm"
  platform_id = "standard-v3"
  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8bpal18cm4kprpjc2m"
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ipiris
          sudo: 'ALL=(ALL) NOPASSWD:ALL'
          groups: sudo
          ssh-authorized-keys:
            - ${tls_private_key.key.public_key_openssh}
      package_update: true
      packages:
        - docker.io
      runcmd:
        - [ systemctl, enable, docker ]
        - [ systemctl, start, docker ]
        - [ docker, run, -d, --restart=always, -p, 80:8080, jmix/jmix-bookstore ]
    EOF
  }
}

output "ssh_connection_string" {
  value = "ssh -i ${local_file.private_key.filename} ipiris@${yandex_compute_instance.vm_instance.network_interface.0.nat_ip_address}"
}

output "web_app_url" {
  value = "http://${yandex_compute_instance.vm_instance.network_interface.0.nat_ip_address}"
}
