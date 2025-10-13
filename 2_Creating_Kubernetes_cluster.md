### 2. Создание Kubernetes кластера

Для создание k8s-кластера нам потребуются создать по 3-и master и worker ноды размещенные в разных расположениях в соответсвии со схемой.

используем манифесты `./terraform/k8s-masters.tf` и `./terraform/k8s-workers.tf` `./terraform/ansible.tf`. Которые поднимут ВМ и через kubespray развернут кластер.

Установим kubespray, он будет находится в `./ansible/kubespray`

```shell
cd ~/devops-diplom-yandexcloud/ansible
wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.21.0.tar.gz
tar -xvzf v2.21.0.tar.gz
mv kubespray-2.21.0 kubespray
python3 -m venv venv
source venv/bin/activate
pip3 install -r kubespray/requirements.txt
```

или же 

```
sduo apt install ansible-core
```

Процесс установки выглядит так

> При запуске пришлось повозиться с памятью на диске. поэтому данные немного будут разниться с прошлой части. Проблема в создании регионального кластера с 3 мастер-нодами - это занимает очень много времени и превышает таймаут.

<details>
    <summary>main.tf</summary>

```
terraform {
  required_version = ">= 0.13"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89"
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
```
</details>

<details>
    <summary> подробнее terraform apply --auto-approve </summary>

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply --auto-approve
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_security_group.k8s-sg: Refreshing state... [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Refreshing state... [id=catolupegjo8fu6470am]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the last "terraform apply" which may have
affected this plan:

  # yandex_kubernetes_cluster.devops-diplom has changed
  ~ resource "yandex_kubernetes_cluster" "devops-diplom" {
        id                       = "catolupegjo8fu6470am"
        name                     = "devops-diplom-yandexcloud-k8s"
        # (8 unchanged attributes hidden)

      ~ master {
          + external_v4_endpoint   = "https://158.160.204.36"
            # (11 unchanged attributes hidden)

            # (1 unchanged block hidden)
        }
    }


Unless you have made equivalent changes to your configuration, or ignored the relevant attributes using ignore_changes,
the following plan may include actions to undo or respond to these changes.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create
  ~ update in-place
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # yandex_kubernetes_cluster.devops-diplom is tainted, so must be replaced
-/+ resource "yandex_kubernetes_cluster" "devops-diplom" {
      ~ cluster_ipv4_range       = "10.112.0.0/16" -> (known after apply)
      + cluster_ipv6_range       = (known after apply)
      ~ created_at               = "2025-10-13T17:45:27Z" -> (known after apply)
      ~ health                   = "unhealthy" -> (known after apply)
      ~ id                       = "catolupegjo8fu6470am" -> (known after apply)
      ~ labels                   = {} -> (known after apply)
      + log_group_id             = (known after apply)
        name                     = "devops-diplom-yandexcloud-k8s"
      ~ service_ipv4_range       = "10.96.0.0/16" -> (known after apply)
      + service_ipv6_range       = (known after apply)
      ~ status                   = "provisioning" -> (known after apply)
        # (8 unchanged attributes hidden)

      ~ master {
          ~ cluster_ca_certificate = <<-EOT
                -----BEGIN CERTIFICATE-----
                MIIC5zCCAc+gAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
                cm5ldGVzMB4XDTI1MTAxMzE3NDUyOVoXDTM1MTAxMTE3NDUyOVowFTETMBEGA1UE
                AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMid
                FTxjmlmlDdlEhsNFysh+jpqKIics2I2jpq/GovR7BIJUxTQs6ZU4BKm6422BbS1H
                bQRwOV6LMgu6dYMtwORNuToehLXdfR96YsfpH0XVFueLr4kCbSFL0IDmMvwzDvKP
                rgt+kK+9K4D91BK7C9YD7Xq123eHzu5xdTtOzRFtSzdBmg82daPx3TTMWrAdg7Ki
                r9KaoH6ef6vDxr6WzHpjevtHQwVMm9CL3+DsmECoEEbRRda5HAHZR9Qnp/68YmNJ
                HxfPhpOIXYYsVE2Af61YfCYSvq0aXgx5jIePyCiV0qK1RGAZ7FcGzL2H13Rhui39
                sprGnU/epuIg8yuucZsCAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
                /wQFMAMBAf8wHQYDVR0OBBYEFFsRelvaPfv1l4P3zP7F/zIanXNzMA0GCSqGSIb3
                DQEBCwUAA4IBAQAA3EMz9Z1ITGl2YffOMzUaSflEYKCbZD1p1vaiMsT4FkXPB/1l
                ML+Qw0tZMArgdb+uinKGZ7b1gGLGCvF6YvVyvUiGWZFxnjaKGudkH+FXv2GyKO6h
                aRuwAxZKZOG54WIfZY1gpq5VfhImxzFUf/F5Cf/RFAthW178rwaJ1oVnrai0fVoX
                EJPfKPj5YMseaMPd9XmwtUrYVCtk3eG+pXvYXQZge9Z5AXrqw+573BvBI66WWfKV
                czOr41EfdrsScsd2/PLBffv5z8wEimg9bfaHLlYSYzB897DuwnVb479/Zwys1UXY
                JmOvqJFSuslqCSu3zVn4DZ/5gJQKwT+crIM5
                -----END CERTIFICATE-----
            EOT -> (known after apply)
          ~ etcd_cluster_size      = 3 -> (known after apply)
          ~ external_v4_address    = "158.160.204.36" -> (known after apply)
          ~ external_v4_endpoint   = "https://158.160.204.36" -> (known after apply)
          + external_v6_endpoint   = (known after apply)
          ~ internal_v4_address    = "10.0.1.10" -> (known after apply)
          ~ internal_v4_endpoint   = "https://10.0.1.10" -> (known after apply)
          ~ version_info           = [
              - {
                  - current_version        = "1.30"
                  - new_revision_available = false
                  - version_deprecated     = false
                    # (1 unchanged attribute hidden)
                },
            ] -> (known after apply)
            # (4 unchanged attributes hidden)

          ~ maintenance_policy (known after apply)
          - maintenance_policy {
              - auto_upgrade = true -> null
            }

          ~ master_location (known after apply)
          - master_location {
              - subnet_id = "e9bvamfk1tg5onjejbuu" -> null
              - zone      = "ru-central1-a" -> null
            }
          - master_location {
              - subnet_id = "e2l2pe3a9tbhubgasu7g" -> null
              - zone      = "ru-central1-b" -> null
            }
          - master_location {
              - subnet_id = "fl8j7vd5kl32pi4phvmf" -> null
              - zone      = "ru-central1-d" -> null
            }

          ~ regional (known after apply)
          - regional {
              - region = "ru-central1" -> null

              - location {
                  - subnet_id = "e9bvamfk1tg5onjejbuu" -> null
                  - zone      = "ru-central1-a" -> null
                }
              - location {
                  - subnet_id = "e2l2pe3a9tbhubgasu7g" -> null
                  - zone      = "ru-central1-b" -> null
                }
              - location {
                  - subnet_id = "fl8j7vd5kl32pi4phvmf" -> null
                  - zone      = "ru-central1-d" -> null
                }
            }

          ~ scale_policy (known after apply)
          - scale_policy {
              - auto_scale {
                  - min_resource_preset_id = "s-c2-m8" -> null
                }
            }

          + zonal {
              + subnet_id = "e9bvamfk1tg5onjejbuu"
              + zone      = "ru-central1-a"
            }
        }
    }

  # yandex_kubernetes_node_group.cluster_nodes will be created
  + resource "yandex_kubernetes_node_group" "cluster_nodes" {
      + cluster_id        = (known after apply)
      + created_at        = (known after apply)
      + description       = (known after apply)
      + id                = (known after apply)
      + instance_group_id = (known after apply)
      + labels            = (known after apply)
      + name              = "devops-diplom-yandexcloud-nodes"
      + status            = (known after apply)
      + version           = (known after apply)
      + version_info      = (known after apply)

      + allocation_policy {
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-a"
            }
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-b"
            }
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-d"
            }
        }

      + deploy_policy (known after apply)

      + instance_template {
          + metadata                  = {
              + "ssh-keys" = <<-EOT
                    ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTpQSISAT/5DpL6RWkbipLhDKgj+lzcMpjchiGiVfdaXCVCCGFN4XDzcxCeJ6ioGRtyvSSyfCLoBS1zgY2P0LBSQLuXs/TuhioKqVkBWwFYrYY1NkvE4si5ciuVKUSUUeoCEwdIi0xdwp/0ukmRrviTXJ354sLtpTt2gCjQfYN6NVy9KKuQpa3DfA+MECG05FhLmQ2htCGM5MvInRTO9qYEcmO5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            }
          + nat                       = (known after apply)
          + network_acceleration_type = (known after apply)
          + platform_id               = "standard-v2"

          + boot_disk {
              + size = 32
              + type = "network-hdd"
            }

          + container_network (known after apply)

          + container_runtime (known after apply)

          + gpu_settings (known after apply)

          + network_interface {
              + ipv4               = true
              + ipv6               = (known after apply)
              + nat                = true
              + security_group_ids = [
                  + "enpa3pvoodtt6im48d7l",
                ]
              + subnet_ids         = [
                  + "e2l2pe3a9tbhubgasu7g",
                  + "e9bvamfk1tg5onjejbuu",
                  + "fl8j7vd5kl32pi4phvmf",
                ]
            }

          + resources {
              + core_fraction = (known after apply)
              + cores         = 2
              + gpus          = 0
              + memory        = 2
            }

          + scheduling_policy {
              + preemptible = true
            }
        }

      + maintenance_policy {
          + auto_repair  = true
          + auto_upgrade = true
        }

      + scale_policy {
          + fixed_scale {
              + size = 3
            }
        }
    }

  # yandex_vpc_security_group.k8s-sg will be updated in-place
  ~ resource "yandex_vpc_security_group" "k8s-sg" {
        id          = "enpa3pvoodtt6im48d7l"
        name        = "k8s-security-group"
        # (6 unchanged attributes hidden)

      - ingress {
          - description       = "HTTP" -> null
          - from_port         = -1 -> null
          - id                = "enp47plc1t7d0tcj4db9" -> null
          - labels            = {} -> null
          - port              = 80 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Kubelet API" -> null
          - from_port         = -1 -> null
          - id                = "enp984rh3pffuff9d3jq" -> null
          - labels            = {} -> null
          - port              = 10250 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "10.0.0.0/8",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Kubernetes API" -> null
          - from_port         = -1 -> null
          - id                = "enpmklqm0rvjm6rbcbe4" -> null
          - labels            = {} -> null
          - port              = 443 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Kubernetes API" -> null
          - from_port         = -1 -> null
          - id                = "enpouqe3ocekq992ts2i" -> null
          - labels            = {} -> null
          - port              = 6443 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "NodePort services" -> null
          - from_port         = 30000 -> null
          - id                = "enp1gt8usneni2m6mbdq" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "TCP" -> null
          - to_port           = 32767 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "SSH" -> null
          - from_port         = -1 -> null
          - id                = "enpt95rs2938en321mva" -> null
          - labels            = {} -> null
          - port              = 22 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "etcd peer" -> null
          - from_port         = -1 -> null
          - id                = "enpppsa2ef4v52llctdh" -> null
          - labels            = {} -> null
          - port              = 2380 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "10.0.0.0/8",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "etcd" -> null
          - from_port         = -1 -> null
          - id                = "enp4qt2il9cqbmklbp2i" -> null
          - labels            = {} -> null
          - port              = 2379 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "10.0.0.0/8",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description    = "HTTP"
          + from_port      = -1
          + id             = "enp47plc1t7d0tcj4db9"
          + labels         = {}
          + port           = 80
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "Kubelet API"
          + from_port      = -1
          + id             = "enp984rh3pffuff9d3jq"
          + labels         = {}
          + port           = 10250
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "10.0.0.0/8",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "Kubernetes API"
          + from_port      = -1
          + id             = "enpmklqm0rvjm6rbcbe4"
          + labels         = {}
          + port           = 443
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "Kubernetes API"
          + from_port      = -1
          + id             = "enpouqe3ocekq992ts2i"
          + labels         = {}
          + port           = 6443
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "NodePort services"
          + from_port      = 30000
          + id             = "enp1gt8usneni2m6mbdq"
          + labels         = {}
          + port           = -1
          + protocol       = "TCP"
          + to_port        = 32767
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "SSH"
          + from_port      = -1
          + id             = "enpt95rs2938en321mva"
          + labels         = {}
          + port           = 22
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }

        # (1 unchanged block hidden)
    }

Plan: 2 to add, 1 to change, 1 to destroy.

Changes to Outputs:
  + kubernetes_cluster_external_endpoint = (known after apply)
  + kubernetes_cluster_id                = (known after apply)
  + node_group_id                        = (known after apply)
yandex_kubernetes_cluster.devops-diplom: Destroying... [id=catolupegjo8fu6470am]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Destruction complete after 1m41s
yandex_vpc_security_group.k8s-sg: Modifying... [id=enpa3pvoodtt6im48d7l]
yandex_vpc_security_group.k8s-sg: Modifications complete after 2s [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Creating...
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [07m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [07m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [07m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Creation complete after 7m25s [id=cataclo3jasi4sdlfq89]
yandex_kubernetes_node_group.cluster_nodes: Creating...
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m10s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m20s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m30s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m40s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m50s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m00s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m10s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m20s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m30s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m40s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Creation complete after 1m41s [id=cat9nhjl3jsrefkdgpcu]

Apply complete! Resources: 2 added, 1 changed, 1 destroyed.

Outputs:

kubernetes_cluster_external_endpoint = "https://89.169.131.228"
kubernetes_cluster_id = "cataclo3jasi4sdlfq89"
node_group_id = "cat9nhjl3jsrefkdgpcu"
```

</details>

<img width="2473" height="457" alt="image" src="https://github.com/user-attachments/assets/439273a1-bf53-475c-aa01-29e2ccb05c47" />

Таблица конфигурации инфраструктуры Kubernetes

| Компонент | Тип | Название | Конфигурация | Назначение |
|-----------|-----|----------|--------------|------------|
| **Terraform** | Backend | S3 | `devops-diplom-yandexcloud-bucket-mrg` | Хранение состояния Terraform |
| **Provider** | Yandex Cloud | - | Cloud: `b1gphk6fe2qpbmph96u5`<br>Folder: `b1g2pak2mr3h8bt5nfam`<br>Zone: `ru-central1-a` | Подключение к Yandex Cloud |
| **VPC Network** | Сеть | `devops-diplom-yandexcloud-net` | - | Основная сеть кластера |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-a` | Zone: `ru-central1-a`<br>CIDR: `10.0.1.0/24` | Подсеть в зоне A |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-b` | Zone: `ru-central1-b`<br>CIDR: `10.0.2.0/24` | Подсеть в зоне B |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-d` | Zone: `ru-central1-d`<br>CIDR: `10.0.3.0/24` | Подсеть в зоне D |
| **Security Group** | Группа безопасности | `k8s-security-group` | Порты: 22, 80, 443, 6443, 10250, 30000-32767 | Управление доступом к кластеру |
| **Kubernetes Cluster** | Кластер | `devops-diplom-yandexcloud-k8s` | Версия: 1.30<br>Канал: REGULAR<br>Network Policy: CALICO | Управляемый Kubernetes кластер |
| **Master Node** | Control Plane | - | Zone: `ru-central1-a`<br>Public IP: true<br>Security Group: включена | Управляющая нода кластера |
| **Node Group** | Группа нод | `devops-diplom-yandexcloud-nodes` | Размер: 3 ноды<br>Зоны: A, B, D | Worker ноды приложений |
| **Instance Template** | Шаблон ВМ | - | Platform: `standard-v2`<br>CPU: 2 ядра<br>RAM: 2 GB<br>Disk: 32 GB HDD | Конфигурация worker нод |
| **Networking** | Сетевые настройки | - | NAT: включен<br>Subnets: все 3 зоны<br>Security Groups: включены | Сетевая конфигурация нод |
| **Scheduling** | Политика планирования | - | Preemptible: true | Использование прерываемых инстансов |

Детализация Security Group Rules

| Направление | Протокол | Порт | CIDR | Описание |
|-------------|----------|------|------|-----------|
| Ingress | TCP | 22 | 0.0.0.0/0 | SSH доступ |
| Ingress | TCP | 80 | 0.0.0.0/0 | HTTP трафик |
| Ingress | TCP | 443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 6443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 10250 | 10.0.0.0/8 | Kubelet API (внутренний) |
| Ingress | TCP | 30000-32767 | 0.0.0.0/0 | NodePort сервисы |
| Egress | ANY | ALL | 0.0.0.0/0 | Исходящий трафик |

Распределение ресурсов по зонам

| Зона | Подсеть | Ноды | Роль |
|------|---------|------|------|
| ru-central1-a | 10.0.1.0/24 | Master + 1 Worker | Control Plane + Worker |
| ru-central1-b | 10.0.2.0/24 | 1 Worker | Worker |
| ru-central1-d | 10.0.3.0/24 | 1 Worker | Worker |

Спецификации нод

| Параметр | Master | Worker |
|----------|---------|---------|
| **Управление** | Yandex Managed | Terraform Managed |
| **Количество** | 1 (auto-managed) | 3 |
| **CPU** | - | 2 ядра |
| **RAM** | - | 2 GB |
| **Disk** | - | 32 GB HDD |
| **Тип диска** | - | Network HDD |
| **Preemptible** | - | Да |
| **NAT** | Нет | Да |
| **Public IP** | Да | Нет (через NAT) |

Service Accounts

| Назначение | ID |
|------------|----|
| Cluster Service Account | `ajer93efebn650j9q2ta` |
| Node Service Account | `ajer93efebn650j9q2ta` |

Выходные данные (Outputs)

| Output | Описание |
|--------|-----------|
| `kubernetes_cluster_id` | ID кластера Kubernetes |
| `kubernetes_cluster_external_endpoint` | Внешний endpoint API |
| `node_group_id` | ID группы нод |


Вручная обновка конфигурации

```
yc managed-kubernetes cluster get-credentials devops-diplom-yandexcloud-k8s --external --kubeconfig ./new-kubeconfig.yaml
export KUBECONFIG=./new-kubeconfig.yaml
kubectl get nodes
```

Результат 

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get nodes -A -owide
NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl1s0g5l6bcohghv6dje-avib   Ready    <none>   10m   v1.30.1   10.0.1.18     158.160.56.167   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-idys   Ready    <none>   10m   v1.30.1   10.0.2.34     84.201.152.99    Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-ivac   Ready    <none>   10m   v1.30.1   10.0.3.29     158.160.144.41   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -A -owide
NAMESPACE     NAME                                                  READY   STATUS             RESTARTS        AGE   IP             NODE                        NOMINATED NODE   READINESS GATES
kube-system   calico-node-6fnhg                                     0/1     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   calico-node-lz95d                                     1/1     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   calico-node-x4sxw                                     0/1     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   calico-typha-64fd6cf7d8-gtlnv                         1/1     Running            0               17m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   calico-typha-horizontal-autoscaler-5ccf4cb46b-hjzg2   1/1     Running            0               17m   10.112.128.3   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   calico-typha-vertical-autoscaler-7c8d49d7d6-885vv     0/1     CrashLoopBackOff   7 (4m43s ago)   17m   10.112.128.4   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   coredns-5b9d99c8f4-7xxdk                              1/1     Running            0               17m   10.112.129.2   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   coredns-5b9d99c8f4-p8xbm                              1/1     Running            0               15m   10.112.130.3   cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   ip-masq-agent-6mqrv                                   1/1     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   ip-masq-agent-h6s79                                   1/1     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   ip-masq-agent-zsb6h                                   1/1     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   kube-dns-autoscaler-6f89667998-pw5z4                  1/1     Running            0               17m   10.112.129.4   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   kube-proxy-f4p46                                      1/1     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   kube-proxy-kzd47                                      1/1     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   kube-proxy-vllx5                                      1/1     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   metrics-server-6568ff6f44-4vw5d                       1/1     Running            0               17m   10.112.128.5   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   metrics-server-6568ff6f44-rhppf                       1/1     Running            0               17m   10.112.129.5   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   npd-v0.8.0-7xf6n                                      1/1     Running            0               15m   10.112.129.3   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   npd-v0.8.0-lx5hn                                      1/1     Running            0               15m   10.112.128.2   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   npd-v0.8.0-x88cj                                      1/1     Running            0               15m   10.112.130.2   cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   yc-disk-csi-node-v2-4kfkw                             6/6     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   yc-disk-csi-node-v2-n7qcv                             6/6     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   yc-disk-csi-node-v2-r62c9                             6/6     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$
```
</details>

