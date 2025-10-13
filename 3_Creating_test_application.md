
### 3. Создание тестового приложения

Проверяем версию докера (который поставил ранее), и авторизиовывемся в dockerhub

```shell
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/testapp$ docker --version
Docker version 28.5.1, build e180ab8
```

main.tf

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
```

Таблица конфигурации инфраструктуры Kubernetes

| Компонент | Тип | Название | Конфигурация | Назначение |
|-----------|-----|----------|--------------|------------|
| **Terraform Backend** | S3 Storage | `devops-diplom-yandexcloud-bucket-mrg` | Region: `ru-central1`<br>Key: `terraform.tfstate` | Хранение состояния Terraform |
| **Provider** | Yandex Cloud | - | Cloud: `b1gphk6fe2qpbmph96u5`<br>Folder: `b1g2pak2mr3h8bt5nfam`<br>Zone: `ru-central1-a` | Подключение к Yandex Cloud |
| **VPC Network** | Сеть | `devops-diplom-yandexcloud-net` | - | Основная сеть кластера |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-a` | Zone: `ru-central1-a`<br>CIDR: `10.0.1.0/24` | Подсеть в зоне A |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-b` | Zone: `ru-central1-b`<br>CIDR: `10.0.2.0/24` | Подсеть в зоне B |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-d` | Zone: `ru-central1-d`<br>CIDR: `10.0.3.0/24` | Подсеть в зоне D |
| **Security Group** | Группа безопасности | `k8s-security-group` | 9 правил ingress<br>1 правило egress | Управление доступом к кластеру |
| **Container Registry** | Docker Registry | `devops-diplom-registry` | Folder: `b1g2pak2mr3h8bt5nfam` | Хранение Docker образов приложения |
| **Kubernetes Cluster** | Managed K8s | `devops-diplom-yandexcloud-k8s` | Версия: 1.30<br>Канал: REGULAR<br>Network Policy: CALICO | Управляемый Kubernetes кластер |
| **Master Node** | Control Plane | - | Zone: `ru-central1-a`<br>Public IP: true<br>Security Group: включена | Управляющая нода кластера |
| **Node Group** | Группа нод | `devops-diplom-yandexcloud-nodes` | Размер: 3 ноды<br>Зоны: A, B, D | Worker ноды приложений |
| **Instance Template** | Шаблон ВМ | - | Platform: `standard-v2`<br>CPU: 2 ядра<br>RAM: 2 GB<br>Disk: 32 GB HDD | Конфигурация worker нод |

Детализация Security Group Rules

| Направление | Протокол | Порт | CIDR | Описание |
|-------------|----------|------|------|-----------|
| Ingress | TCP | 22 | 0.0.0.0/0 | SSH доступ |
| Ingress | TCP | 80 | 0.0.0.0/0 | HTTP трафик |
| Ingress | TCP | 443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 6443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 3000 | 0.0.0.0/0 | Grafana |
| Ingress | TCP | 9090 | 0.0.0.0/0 | Prometheus |
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

| Назначение | ID | Имя |
|------------|----|-----|
| Cluster Service Account | `ajer93efebn650j9q2ta` | `devops-diplom-yandexcloud-sa` |
| Node Service Account | `ajer93efebn650j9q2ta` | `devops-diplom-yandexcloud-sa` |

Выходные данные (Outputs)

| Output | Описание | Пример значения |
|--------|-----------|-----------------|
| `kubernetes_cluster_id` | ID кластера Kubernetes | `cataclo3jasi4sdlfq89` |
| `kubernetes_cluster_external_endpoint` | Внешний endpoint API | `https://89.169.131.228` |
| `node_group_id` | ID группы нод | `cat9nhjl3jsrefkdgpcu` |
| `container_registry_id` | ID container registry | `crps1p5u048a00f4o97j` |
| `container_registry_url` | URL registry | `cr.yandex/crps1p5u048a00f4o97j` |

Сетевые диапазоны

| Назначение | CIDR диапазон |
|------------|---------------|
| Pod Network | 10.112.0.0/16 |
| Service Network | 10.96.0.0/16 |
| Node Network | 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 |

Текущее состояние развертывания

| Ресурс | Статус | Количество |
|--------|--------|------------|
| Kubernetes Cluster | RUNNING | 1 |
| Worker Nodes | Ready | 3 |
| Container Registry | Active | 1 |
| Test Application Pod | Running | 1 |
| Test Application Service | NodePort | 1 |
| Ingress | Created | 1 |


terraform apply -auto-approve

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply -auto-approve
yandex_iam_service_account_static_access_key.cicd_sa_key: Refreshing state... [id=aje32joh3e5ostb0q30r]
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
yandex_iam_service_account.cicd_sa: Refreshing state... [id=aje1kbha8ivn1l7n8dmr]
yandex_container_registry.app_registry: Refreshing state... [id=crps1p5u048a00f4o97j]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_security_group.k8s-sg: Refreshing state... [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Refreshing state... [id=cataclo3jasi4sdlfq89]
yandex_kubernetes_node_group.cluster_nodes: Refreshing state... [id=cat9nhjl3jsrefkdgpcu]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_iam_service_account.cicd_sa will be destroyed
  # (because yandex_iam_service_account.cicd_sa is not in configuration)
  - resource "yandex_iam_service_account" "cicd_sa" {
      - created_at         = "2025-10-13T19:18:50Z" -> null
      - description        = "Service account for CI/CD operations" -> null
      - folder_id          = "b1g2pak2mr3h8bt5nfam" -> null
      - id                 = "aje1kbha8ivn1l7n8dmr" -> null
      - name               = "cicd-service-account" -> null
      - service_account_id = "aje1kbha8ivn1l7n8dmr" -> null
    }

  # yandex_iam_service_account_static_access_key.cicd_sa_key will be destroyed
  # (because yandex_iam_service_account_static_access_key.cicd_sa_key is not in configuration)
  - resource "yandex_iam_service_account_static_access_key" "cicd_sa_key" {
      - access_key         = "YCAJEao0NfX9aW5sr37VMt4EW" -> null
      - created_at         = "2025-10-13T19:18:52Z" -> null
      - description        = "Static access key for CI/CD" -> null
      - id                 = "aje32joh3e5ostb0q30r" -> null
      - secret_key         = (sensitive value) -> null
      - service_account_id = "aje1kbha8ivn1l7n8dmr" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Changes to Outputs:
  - cicd_access_key_id                   = (sensitive value) -> null
  - cicd_secret_key                      = (sensitive value) -> null
  - cicd_service_account_id              = "aje1kbha8ivn1l7n8dmr" -> null
yandex_iam_service_account_static_access_key.cicd_sa_key: Destroying... [id=aje32joh3e5ostb0q30r]
yandex_iam_service_account_static_access_key.cicd_sa_key: Destruction complete after 0s
yandex_iam_service_account.cicd_sa: Destroying... [id=aje1kbha8ivn1l7n8dmr]
yandex_iam_service_account.cicd_sa: Destruction complete after 3s

Apply complete! Resources: 0 added, 0 changed, 2 destroyed.

Outputs:

container_registry_id = "crps1p5u048a00f4o97j"
container_registry_url = "cr.yandex/crps1p5u048a00f4o97j"
kubernetes_cluster_external_endpoint = "https://89.169.131.228"
kubernetes_cluster_id = "cataclo3jasi4sdlfq89"
node_group_id = "cat9nhjl3jsrefkdgpcu"
```

Создаем права для registry вручную

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc iam service-account list
+----------------------+------------------------------+--------+---------------------+-----------------------+
|          ID          |             NAME             | LABELS |     CREATED AT      | LAST AUTHENTICATED AT |
+----------------------+------------------------------+--------+---------------------+-----------------------+
| ajeaedtelvo4jbaqukek | vm-service-account           |        | 2025-10-12 18:12:49 |                       |
| ajena75o7bbk24o8rqi0 | tf-sa                        |        | 2025-10-12 18:27:23 | 2025-10-13 19:20:00   |
| ajer93efebn650j9q2ta | devops-diplom-yandexcloud-sa |        | 2025-10-12 17:38:26 | 2025-10-13 19:20:00   |
| ajevr3943agpiaa65qau | xcw55wtaa                    |        | 2025-03-24 17:59:54 | 2025-10-13 18:30:00   |
+----------------------+------------------------------+--------+---------------------+-----------------------+
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container registry add-access-binding crps1p5u048a00f4o97j \
  --role container-registry.images.puller \
  --service-account-name devops-diplom-yandexcloud-sa
done (4s)
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container registry add-access-binding crps1p5u048a00f4o97j \
  --role container-registry.images.pusher \
  --service-account-name devops-diplom-yandexcloud-sa
done (4s)
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container registry list-access-bindings crps1p5u048a00f4o97j
+----------------------------------+----------------+----------------------+
|             ROLE ID              |  SUBJECT TYPE  |      SUBJECT ID      |
+----------------------------------+----------------+----------------------+
| container-registry.images.puller | serviceAccount | ajer93efebn650j9q2ta |
| container-registry.images.pusher | serviceAccount | ajer93efebn650j9q2ta |
+----------------------------------+----------------+----------------------+

```

Теперь собираем и опубликуем Docker образ. Создаем файл build-and-push.sh в папке terraform

```
#!/bin/bash

# Variables
REGISTRY_ID="crps1p5u048a00f4o97j"
IMAGE_NAME="testapp"
VERSION="1.0.0"
APP_DIR="../testapp"

echo "Building Docker image..."
echo "Registry ID: $REGISTRY_ID"

cd $APP_DIR

# Login to Yandex Container Registry
yc container registry configure-docker

# Build Docker image
docker build -t cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION .

# Push to registry
docker push cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION

# Also tag as latest
docker tag cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION cr.yandex/$REGISTRY_ID/$IMAGE_NAME:latest
docker push cr.yandex/$REGISTRY_ID/$IMAGE_NAME:latest

echo "========================================="
echo "Image pushed successfully!"
echo "Image: cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION"
echo "Latest: cr.yandex/$REGISTRY_ID/$IMAGE_NAME:latest"
echo "========================================="
```

А теперь запускаем

```
chmod +x build-and-push.sh
./build-and-push.sh
```

Проверяем

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container image list --registry-name devops-diplom-registry
+----------------------+---------------------+------------------------------+---------------+-----------------+
|          ID          |       CREATED       |             NAME             |     TAGS      | COMPRESSED SIZE |
+----------------------+---------------------+------------------------------+---------------+-----------------+
| crpu1gb6ho1u3f1tjm6d | 2025-10-13 19:30:44 | crps1p5u048a00f4o97j/testapp | 1.0.0, latest | 19.5 MB         |
+----------------------+---------------------+------------------------------+---------------+-----------------+
```

Обновляем Kubernetes манифесты

В файлах в папке k8s/ image на: ```image: cr.yandex/crps1p5u048a00f4o97j/testapp:1.0.0```

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/k8s$ cat deployment-testapp.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: testapp
  labels:
    app: testapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: testapp
  template:
    metadata:
      labels:
        app: testapp
    spec:
      containers:
        - name: testapp
          image: cr.yandex/crps1p5u048a00f4o97j/testapp:1.0.0
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "128Mi"
              cpu: "1"
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc managed-kubernetes cluster get-credentials devops-diplom-yandexcloud-k8s --external --force

Context 'yc-devops-diplom-yandexcloud-k8s' was added as default to kubeconfig '/home/user/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/user/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'a21a21b9-2363-4940-b141-c00b6a9bf1dc'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl apply -f ../k8s/
deployment.apps/testapp configured
service/grafana-service unchanged
service/testapp-service unchanged
```

Проверка развертывания

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE                        NOMINATED NODE   READINESS GATES
testapp-86dffd4b4b-c6zlg   1/1     Running   0          32s   10.112.130.5   cl1s0g5l6bcohghv6dje-avib   <none>           <none>
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get services
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
grafana-service   NodePort    10.96.168.136   <none>        3000:30101/TCP   5m51s
kubernetes        ClusterIP   10.96.128.1     <none>        443/TCP          73m
testapp-service   NodePort    10.96.246.96    <none>        80:30102/TCP     5m51s
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get deployments
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
testapp   1/1     1            1           6m
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -k https://89.169.131.228/healthz
okuser@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ nc -zv 89.169.131.228 443
Connection to 89.169.131.228 443 port [tcp/https] succeeded!
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$
```

Настроим доступ 

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ nano ../k8s/ingress-testapp.yaml
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl apply -f ../k8s/ingress-testapp.yaml
ingress.networking.k8s.io/testapp-ingress created
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ cat ../k8s/ingress-testapp.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: testapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: testapp-service
            port:
              number: 80
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get nodes -o wide
NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl1s0g5l6bcohghv6dje-avib   Ready    <none>   78m   v1.30.1   10.0.1.18     158.160.56.167   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-idys   Ready    <none>   78m   v1.30.1   10.0.2.34     84.201.152.99    Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-ivac   Ready    <none>   78m   v1.30.1   10.0.3.29     158.160.144.41   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl http://158.160.56.167:30102
<!doctype html>
<html lang="ru">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Дипломный проект - Куликова А.В., NETOLOGY-SHVIRTD-17</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"
        integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <style>
        .hero-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 80px 0;
        }

        .card {
            border: none;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
        }

        .card:hover {
            transform: translateY(-5px);
        }

        .feature-icon {
            font-size: 2rem;
            margin-bottom: 1rem;
        }

        .system-info {
            background-color: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
        }
    </style>
</head>

<body>
    <!-- Hero Section -->
    <section class="hero-section">
        <div class="container">
            <div class="row text-center">
                <div class="col-12">
                    <h1 class="display-4 fw-bold mb-4">Дипломный проект</h1>
                    <p class="lead mb-3">Куликова Александра Владимировна</p>
                    <p class="mb-4">Группа: NETOLOGY-SHVIRTD-17</p>
                    <div class="d-flex justify-content-center gap-3 flex-wrap">
                        <span class="badge bg-light text-dark">Версия: v1.0.0</span>
                        <span class="badge bg-success">Статус: Production</span>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="py-5">
        <div class="container">
            <div class="row g-4">
                <div class="col-md-4">
                    <div class="card h-100 text-center p-4">
                        <div class="feature-icon">🚀</div>
                        <h5>Kubernetes</h5>
                        <p class="text-muted">Развертывание и оркестрация контейнеров в облачной среде</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card h-100 text-center p-4">
                        <div class="feature-icon">⚡</div>
                        <h5>CI/CD</h5>
                        <p class="text-muted">Автоматизация процессов сборки, тестирования и развертывания</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card h-100 text-center p-4">
                        <div class="feature-icon">🔧</div>
                        <h5>Infrastructure</h5>
                        <p class="text-muted">Управление инфраструктурой как код с использованием Terraform</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- System Information -->
    <section class="py-5 bg-light">
        <div class="container">
            <div class="row justify-content-center">
                <div class="col-lg-8">
                    <div class="system-info">
                        <h4 class="text-center mb-4">📊 Информация о системе</h4>
                        <div class="row text-center">
                            <div class="col-md-6 mb-3">
                                <strong>Текущее время:</strong>
                                <div id="current-time" class="text-primary fw-bold">--:--:--</div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <strong>Время работы:</strong>
                                <div id="page-uptime" class="text-success fw-bold">00:00:00</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-dark text-white py-4">
        <div class="container">
            <div class="row text-center">
                <div class="col-12">
                    <p class="mb-0">&copy; 2024 Куликова А.В. | NETOLOGY-SHVIRTD-17</p>
                    <p class="mb-0">Дипломный проект по DevOps инженерии</p>
                </div>
            </div>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz"
        crossorigin="anonymous"></script>

    <script>
        // Update current time
        function updateTime() {
            const now = new Date();
            document.getElementById('current-time').textContent =
                now.toLocaleTimeString('ru-RU');
        }

        // Update page uptime
        function updateUptime() {
            const startTime = Date.now();
            setInterval(() => {
                const uptime = Date.now() - startTime;
                const hours = Math.floor(uptime / 3600000);
                const minutes = Math.floor((uptime % 3600000) / 60000);
                const seconds = Math.floor((uptime % 60000) / 1000);
                document.getElementById('page-uptime').textContent =
                    `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
            }, 1000);
        }

        // Initialize functions when page loads
        document.addEventListener('DOMContentLoaded', function() {
            updateTime();
            setInterval(updateTime, 1000);
            updateUptime();
        });
    </script>
</body>

</html>
```

<img width="2160" height="1450" alt="image" src="https://github.com/user-attachments/assets/83a82a04-f9ef-4300-9c88-2f54d410c450" />

> Страница была сгенерирована (не обладаю знаниями по созданию web) и мое имя было написано с ошибкой *
