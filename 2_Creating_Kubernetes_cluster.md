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

<img width="2121" height="815" alt="image" src="https://github.com/user-attachments/assets/667be2ce-ad01-4193-a022-c57710e5145d" />

Запустим `terraform apply --auto-approve` 

<details>
    <summary>подробнее</summary>

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform show
# yandex_kubernetes_cluster.devops-diplom:
resource "yandex_kubernetes_cluster" "devops-diplom" {
    cluster_ipv4_range       = "10.112.0.0/16"
    cluster_ipv6_range       = null
    created_at               = "2025-10-12T20:57:51Z"
    description              = "Kubernetes cluster for devops-diplom-yandexcloud project"
    folder_id                = "b1g2pak2mr3h8bt5nfam"
    health                   = "healthy"
    id                       = "cataatt5mvckuaid7at4"
    labels                   = {}
    log_group_id             = null
    name                     = "devops-diplom-yandexcloud-k8s"
    network_id               = "enpsj820vglkjv4mng70"
    node_ipv4_cidr_mask_size = 24
    node_service_account_id  = "ajer93efebn650j9q2ta"
    release_channel          = "REGULAR"
    service_account_id       = "ajer93efebn650j9q2ta"
    service_ipv4_range       = "10.96.0.0/16"
    service_ipv6_range       = null
    status                   = "running"

    master {
        cluster_ca_certificate = <<-EOT
            -----BEGIN CERTIFICATE-----
            MIIC5zCCAc+gAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
            cm5ldGVzMB4XDTI1MTAxMjIwNTc1M1oXDTM1MTAxMDIwNTc1M1owFTETMBEGA1UE
            AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALm/
            +0mFA9it4WcMNCW6VSY160wE9uxu6YWx/4oVqvtKZCFfn9z97NNEhXLrlD3Yj+RD
            GpNqJWa1ZK1ThR6CXBKWu2EBK/srzhZCu4LKXbB3OgHs2shVMEgVVLFyimr2Qw8h
            zz3f6iBVZ029fKzbqz6BMXOEqef2dSogywCm9pXu0MtnwVjEF6siib8Q3naYS478
            unI3dRO029gkFOcScHhCki5zufUynXTvPaPp1QUqn/GF3Myn/mMoUlOBpMJ5v//a
            HslHl+JqMmr3gC+lDvhp6ZvdPw19+V3uWdnxmmPJpaneBT0E9kHBfLQU7cOsWioF
            PEvsLJQAUI8BOPD06BkCAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
            /wQFMAMBAf8wHQYDVR0OBBYEFCW2flK5mM6A3F4VunHNowDJOGaoMA0GCSqGSIb3
            DQEBCwUAA4IBAQAC2pvOCvzVgsJHJ1UJIz9uA/lcUB9UC5n3unJ/PMwyj4rMROSF
            dD/d9017oLlx4+5vYDdAXzQzVsAyHScQpnt+1t0JD1Hk/lLZew5zAQOb78EnamvD
            dz7cRf/J9OWkJNmd0wv3ubQOG+8zAysai4ynZspfBIDs19h10cLaTxLs56hz49Fr
            UPDBfTYMFDRU2gPBqSHnLsPI8IF1Ar/XRYopNA2uUNooOHy7p1jNmu53sBa4GuER
            AvVF2tvGFbJJxuM7tINLuDMBw8PJ3WkoUnXU3YHuzTzd88tFcja1QTV0DsVXdsqW
            7CbUdhPD3FjdnMHBtD4gQYbaAKtwjbs3KrHH
            -----END CERTIFICATE-----
        EOT
        etcd_cluster_size      = 1
        external_v4_address    = "51.250.81.224"
        external_v4_endpoint   = "https://51.250.81.224"
        external_v6_address    = null
        external_v6_endpoint   = null
        internal_v4_address    = "10.0.1.16"
        internal_v4_endpoint   = "https://10.0.1.16"
        public_ip              = true
        version                = "1.30"
        version_info           = [
            {
                current_version        = "1.30"
                new_revision_available = false
                new_revision_summary   = null
                version_deprecated     = false
            },
        ]

        maintenance_policy {
            auto_upgrade = true
        }

        master_location {
            subnet_id = "e9bvamfk1tg5onjejbuu"
            zone      = "ru-central1-a"
        }

        scale_policy {
            auto_scale {
                min_resource_preset_id = "s-c2-m8"
            }
        }

        zonal {
            subnet_id = null
            zone      = "ru-central1-a"
        }
    }
}

# yandex_kubernetes_node_group.nodes:
resource "yandex_kubernetes_node_group" "nodes" {
    cluster_id        = "cataatt5mvckuaid7at4"
    created_at        = "2025-10-12T21:07:19Z"
    description       = null
    id                = "cat1t172pqnel732osd5"
    instance_group_id = "cl16dcj12goe1i9esl3p"
    labels            = {}
    name              = "devops-diplom-yandexcloud-nodes"
    status            = "running"
    version           = "1.30"
    version_info      = [
        {
            current_version        = "1.30"
            new_revision_available = false
            new_revision_summary   = null
            version_deprecated     = false
        },
    ]

    allocation_policy {
        location {
            subnet_id = "e9bvamfk1tg5onjejbuu"
            zone      = "ru-central1-a"
        }
        location {
            subnet_id = "e2l2pe3a9tbhubgasu7g"
            zone      = "ru-central1-b"
        }
        location {
            subnet_id = "fl8j7vd5kl32pi4phvmf"
            zone      = "ru-central1-d"
        }
    }

    deploy_policy {
        max_expansion   = 3
        max_unavailable = 0
    }

    instance_template {
        metadata                  = {}
        name                      = null
        nat                       = true
        network_acceleration_type = "type_unspecified"
        platform_id               = "standard-v2"

        boot_disk {
            size = 32
            type = "network-hdd"
        }

        container_network {
            pod_mtu = 0
        }

        network_interface {
            ipv4       = true
            ipv6       = false
            nat        = true
            subnet_ids = [
                "e2l2pe3a9tbhubgasu7g",
                "e9bvamfk1tg5onjejbuu",
                "fl8j7vd5kl32pi4phvmf",
            ]
        }

        resources {
            core_fraction = 100
            cores         = 2
            gpus          = 0
            memory        = 2
        }

        scheduling_policy {
            preemptible = true
        }
    }

    maintenance_policy {
        auto_repair  = true
        auto_upgrade = true
    }

    scale_policy {
        fixed_scale {
            size = 3
        }
    }
}

# yandex_vpc_network.net:
resource "yandex_vpc_network" "net" {
    created_at                = "2025-10-12T18:49:03Z"
    default_security_group_id = "enp0crnald9apaq6navg"
    description               = null
    folder_id                 = "b1g2pak2mr3h8bt5nfam"
    id                        = "enpsj820vglkjv4mng70"
    labels                    = {}
    name                      = "devops-diplom-yandexcloud-net"
    subnet_ids                = [
        "e2l2pe3a9tbhubgasu7g",
        "e9b61nsohap6actrl0tn",
        "e9bhtgcm53uuudoftm30",
        "e9bvamfk1tg5onjejbuu",
        "fl8j7vd5kl32pi4phvmf",
    ]
}

# yandex_vpc_subnet.central1-a:
resource "yandex_vpc_subnet" "central1-a" {
    created_at     = "2025-10-12T18:49:06Z"
    description    = null
    folder_id      = "b1g2pak2mr3h8bt5nfam"
    id             = "e9bvamfk1tg5onjejbuu"
    labels         = {}
    name           = "devops-diplom-yandexcloud-central1-a"
    network_id     = "enpsj820vglkjv4mng70"
    route_table_id = null
    v4_cidr_blocks = [
        "10.0.1.0/24",
    ]
    v6_cidr_blocks = []
    zone           = "ru-central1-a"
}

# yandex_vpc_subnet.central1-b:
resource "yandex_vpc_subnet" "central1-b" {
    created_at     = "2025-10-12T18:49:07Z"
    description    = null
    folder_id      = "b1g2pak2mr3h8bt5nfam"
    id             = "e2l2pe3a9tbhubgasu7g"
    labels         = {}
    name           = "devops-diplom-yandexcloud-central1-b"
    network_id     = "enpsj820vglkjv4mng70"
    route_table_id = null
    v4_cidr_blocks = [
        "10.0.2.0/24",
    ]
    v6_cidr_blocks = []
    zone           = "ru-central1-b"
}

# yandex_vpc_subnet.central1-d:
resource "yandex_vpc_subnet" "central1-d" {
    created_at     = "2025-10-12T18:49:06Z"
    description    = null
    folder_id      = "b1g2pak2mr3h8bt5nfam"
    id             = "fl8j7vd5kl32pi4phvmf"
    labels         = {}
    name           = "devops-diplom-yandexcloud-central1-d"
    network_id     = "enpsj820vglkjv4mng70"
    route_table_id = null
    v4_cidr_blocks = [
        "10.0.3.0/24",
    ]
    v6_cidr_blocks = []
    zone           = "ru-central1-d"
}
```
</details>

> при запуске пришлось повозиться с памятью на диске. поэтому данные немного будут разниться 

```

user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get nodes -A -owide
NAME                        STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl16dcj12goe1i9esl3p-efah   Ready    <none>   5m40s   v1.30.1   10.0.3.7      84.201.170.84    Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl16dcj12goe1i9esl3p-ohyd   Ready    <none>   5m29s   v1.30.1   10.0.1.4      89.169.143.123   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl16dcj12goe1i9esl3p-ysol   Ready    <none>   5m43s   v1.30.1   10.0.2.13     84.201.142.166   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -A -owide
NAMESPACE     NAME                                   READY   STATUS    RESTARTS   AGE     IP             NODE                        NOMINATED NODE   READINESS GATES
kube-system   coredns-5b9d99c8f4-7l9lj               1/1     Running   0          8m4s    10.112.129.3   cl16dcj12goe1i9esl3p-efah   <none>           <none>
kube-system   coredns-5b9d99c8f4-8ft8k               1/1     Running   0          6m      10.112.128.5   cl16dcj12goe1i9esl3p-ysol   <none>           <none>
kube-system   ip-masq-agent-lj25d                    1/1     Running   0          6m11s   10.0.2.13      cl16dcj12goe1i9esl3p-ysol   <none>           <none>
kube-system   ip-masq-agent-vsgbn                    1/1     Running   0          5m57s   10.0.1.4       cl16dcj12goe1i9esl3p-ohyd   <none>           <none>
kube-system   ip-masq-agent-w2ww5                    1/1     Running   0          6m8s    10.0.3.7       cl16dcj12goe1i9esl3p-efah   <none>           <none>
kube-system   kube-dns-autoscaler-6f89667998-5mksq   1/1     Running   0          8m2s    10.112.128.4   cl16dcj12goe1i9esl3p-ysol   <none>           <none>
kube-system   kube-proxy-hh6bx                       1/1     Running   0          6m8s    10.0.3.7       cl16dcj12goe1i9esl3p-efah   <none>           <none>
kube-system   kube-proxy-nq6mn                       1/1     Running   0          5m57s   10.0.1.4       cl16dcj12goe1i9esl3p-ohyd   <none>           <none>
kube-system   kube-proxy-pzlh7                       1/1     Running   0          6m11s   10.0.2.13      cl16dcj12goe1i9esl3p-ysol   <none>           <none>
kube-system   metrics-server-6568ff6f44-t6dt5        1/1     Running   0          8m2s    10.112.129.4   cl16dcj12goe1i9esl3p-efah   <none>           <none>
kube-system   metrics-server-6568ff6f44-v2rlh        1/1     Running   0          8m2s    10.112.128.3   cl16dcj12goe1i9esl3p-ysol   <none>           <none>
kube-system   npd-v0.8.0-2rlhk                       1/1     Running   0          6m8s    10.112.129.2   cl16dcj12goe1i9esl3p-efah   <none>           <none>
kube-system   npd-v0.8.0-c6cqf                       1/1     Running   0          6m11s   10.112.128.2   cl16dcj12goe1i9esl3p-ysol   <none>           <none>
kube-system   npd-v0.8.0-fmmlh                       1/1     Running   0          5m57s   10.112.130.2   cl16dcj12goe1i9esl3p-ohyd   <none>           <none>
kube-system   yc-disk-csi-node-v2-6fm4c              6/6     Running   0          6m11s   10.0.2.13      cl16dcj12goe1i9esl3p-ysol   <none>           <none>
kube-system   yc-disk-csi-node-v2-g9qqh              6/6     Running   0          5m57s   10.0.1.4       cl16dcj12goe1i9esl3p-ohyd   <none>           <none>
kube-system   yc-disk-csi-node-v2-qm5z2              6/6     Running   0          6m8s    10.0.3.7       cl16dcj12goe1i9esl3p-efah   <none>           <none>
```
</details>

