terraform {
  required_version = ">= 0.13"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }

  backend "s3" {
    endpoints = { s3 = "https://storage.yandexcloud.net" }
    bucket    = "devops-diplom-yandexcloud-bucket-mrg"
    region    = "ru-central1"
    key       = "terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = "b1gphk6fe2qpbmph96u5"
  folder_id = "b1g2pak2mr3h8bt5nfam"
  zone      = "ru-central1-a"
}

# Data source for client config
data "yandex_client_config" "client" {}

# VPC Network
resource "yandex_vpc_network" "net" {
  name = "devops-diplom-yandexcloud-net"
}

# Subnets in different zones
resource "yandex_vpc_subnet" "central1-a" {
  name           = "devops-diplom-yandexcloud-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "central1-b" {
  name           = "devops-diplom-yandexcloud-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

resource "yandex_vpc_subnet" "central1-d" {
  name           = "devops-diplom-yandexcloud-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Security Group for Kubernetes
resource "yandex_vpc_security_group" "k8s-sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH"
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  ingress {
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "HTTP"
  }

  ingress {
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Grafana"
  }

  ingress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Prometheus"
  }

  ingress {
    protocol       = "TCP"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "NodePort services"
  }

  ingress {
    protocol       = "TCP"
    port           = 10250
    v4_cidr_blocks = ["10.0.0.0/8"]
    description    = "Kubelet API"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Outbound traffic"
  }
}

# Yandex Container Registry for application images
resource "yandex_container_registry" "app_registry" {
  name      = "devops-diplom-registry"
  folder_id = "b1g2pak2mr3h8bt5nfam"
}

# Managed Kubernetes Cluster with zonal master (simpler and faster)
resource "yandex_kubernetes_cluster" "devops-diplom" {
  name        = "devops-diplom-yandexcloud-k8s"
  description = "Kubernetes cluster for devops-diplom-yandexcloud project"
  network_id  = yandex_vpc_network.net.id
  folder_id   = "b1g2pak2mr3h8bt5nfam"

  master {
    version   = "1.30"
    public_ip = true

    # Zonal master configuration (simpler and faster to create)
    zonal {
      zone      = yandex_vpc_subnet.central1-a.zone
      subnet_id = yandex_vpc_subnet.central1-a.id
    }

    # Security settings
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
  }

  service_account_id      = "ajer93efebn650j9q2ta"
  node_service_account_id = "ajer93efebn650j9q2ta"

  release_channel = "REGULAR"
  network_policy_provider = "CALICO"

  depends_on = [
    yandex_vpc_security_group.k8s-sg
  ]
}

# Single Node Group for both control plane and workers
resource "yandex_kubernetes_node_group" "cluster_nodes" {
  cluster_id = yandex_kubernetes_cluster.devops-diplom.id
  name       = "devops-diplom-yandexcloud-nodes"

  instance_template {
    platform_id = "standard-v2"

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    network_interface {
      nat        = true
      subnet_ids = [
        yandex_vpc_subnet.central1-a.id,
        yandex_vpc_subnet.central1-b.id,
        yandex_vpc_subnet.central1-d.id
      ]
      security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
    }

    scheduling_policy {
      preemptible = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3  # 3 worker nodes distributed across zones
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    location {
      zone = "ru-central1-b"
    }
    location {
      zone = "ru-central1-d"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }

  depends_on = [
    yandex_kubernetes_cluster.devops-diplom
  ]
}

# Outputs to see the cluster information
output "kubernetes_cluster_id" {
  value = yandex_kubernetes_cluster.devops-diplom.id
}

output "kubernetes_cluster_external_endpoint" {
  value = yandex_kubernetes_cluster.devops-diplom.master[0].external_v4_endpoint
}

output "node_group_id" {
  value = yandex_kubernetes_node_group.cluster_nodes.id
}

output "container_registry_id" {
  value = yandex_container_registry.app_registry.id
}

output "container_registry_url" {
  value = "cr.yandex/${yandex_container_registry.app_registry.id}"
}
