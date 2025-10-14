## 4. Подготовка cистемы мониторинга и деплой приложения

Развернем его в кластере продублируем код в `./terraform/monitoring.tf` используя helm и поднимим сервис  `./k8s/service-grafana.yaml`

Подготовим network_load_balancer для доступа к grafana и testapp `./terraform/nlb.tf`

настроим развертывание в k8s тестового приложения `./terraform/app.tf`

Применяем конфигурацию
```
terraform init
terraform plan
terraform apply -auto-approve
```

terraform apply -auto-approve

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply -auto-approve
data.yandex_client_config.client: Reading...
yandex_container_registry.app_registry: Refreshing state... [id=crps1p5u048a00f4o97j]
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
data.yandex_client_config.client: Read complete after 0s [id=3771214742]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_security_group.k8s-sg: Refreshing state... [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Refreshing state... [id=cataclo3jasi4sdlfq89]
yandex_kubernetes_node_group.cluster_nodes: Refreshing state... [id=cat9nhjl3jsrefkdgpcu]
helm_release.kube_prometheus_stack: Refreshing state... [id=kube-prometheus-stack]
kubernetes_namespace.app_namespace: Refreshing state... [id=app]
yandex_lb_target_group.k8s_nodes: Refreshing state... [id=enp1308h4k6apj3fpd0v]
kubernetes_deployment.testapp: Refreshing state... [id=app/testapp]
kubernetes_service.testapp: Refreshing state... [id=app/testapp-service]
kubernetes_ingress_v1.testapp_ingress: Refreshing state... [id=app/testapp-ingress]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_lb_network_load_balancer.k8s_services will be created
  + resource "yandex_lb_network_load_balancer" "k8s_services" {
      + allow_zonal_shift   = (known after apply)
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "k8s-services-load-balancer"
      + region_id           = (known after apply)
      + type                = "external"

      + attached_target_group {
          + target_group_id = "enp1308h4k6apj3fpd0v"

          + healthcheck {
              + healthy_threshold   = 2
              + interval            = 2
              + name                = "app-healthcheck"
              + timeout             = 1
              + unhealthy_threshold = 2

              + http_options {
                  + path = "/healthz"
                  + port = 30180
                }
            }
        }

      + listener {
          + name        = "app-listener"
          + port        = 80
          + protocol    = (known after apply)
          + target_port = (known after apply)

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
      + listener {
          + name        = "grafana-listener"
          + port        = 3000
          + protocol    = (known after apply)
          + target_port = (known after apply)

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
yandex_lb_network_load_balancer.k8s_services: Creating...
yandex_lb_network_load_balancer.k8s_services: Creation complete after 4s [id=enpf3g2ikr8hup8458qu]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

container_registry_id = "crps1p5u048a00f4o97j"
container_registry_url = "cr.yandex/crps1p5u048a00f4o97j"
kubernetes_cluster_external_endpoint = "https://89.169.131.228"
kubernetes_cluster_id = "cataclo3jasi4sdlfq89"
node_group_id = "cat9nhjl3jsrefkdgpcu"
```

Применяем сервис Grafana вручную после применения Terraform:

```
yc managed-kubernetes cluster get-credentials devops-diplom-yandexcloud-k8s --external --force
kubectl apply -f ../k8s/service-grafana.yaml
```

Проверяем развертывание

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -A
NAMESPACE     NAME                                                        READY   STATUS                   RESTARTS         AGE
app           testapp-699d4b754d-6nj4x                                    1/1     Running                  0                10m
app           testapp-699d4b754d-bzqnp                                    1/1     Running                  0                10m
default       testapp-86dffd4b4b-c6zlg                                    0/1     Completed                0                23h
default       testapp-86dffd4b4b-d86kg                                    0/1     Completed                0                122m
default       testapp-8f5bf7f99-jqzjn                                     1/1     Running                  0                40m
kube-system   calico-node-c44jj                                           0/1     Running                  0                64m
kube-system   calico-node-lrkwp                                           1/1     Running                  0                78m
kube-system   calico-node-tvscd                                           0/1     Running                  0                122m
kube-system   calico-typha-64fd6cf7d8-59c5l                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-5rgfl                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-5xtrn                               0/1     NodePorts                0                78m
kube-system   calico-typha-64fd6cf7d8-65p4z                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-6wwr7                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-972bs                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-btwmt                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-c6w4k                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-drtc2                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-f9ntr                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-gc2vl                               1/1     Running                  0                78m
kube-system   calico-typha-64fd6cf7d8-gr626                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-gtlnv                               0/1     Error                    0                24h
kube-system   calico-typha-64fd6cf7d8-j5vmw                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-jx4ws                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-jzbbn                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-kxsbw                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-q96wd                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-qf6dd                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-qhhsh                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-qjr6c                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-sqvkr                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-x52bs                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-z8zgb                               0/1     NodePorts                0                78m
kube-system   calico-typha-horizontal-autoscaler-5ccf4cb46b-4p7qv         1/1     Running                  0                64m
kube-system   calico-typha-horizontal-autoscaler-5ccf4cb46b-hjzg2         0/1     Error                    0                24h
kube-system   calico-typha-vertical-autoscaler-7c8d49d7d6-885vv           0/1     Error                    277              24h
kube-system   calico-typha-vertical-autoscaler-7c8d49d7d6-lz4v5           0/1     CrashLoopBackOff         17 (2m23s ago)   64m
kube-system   coredns-5b9d99c8f4-67t57                                    1/1     Running                  0                64m
kube-system   coredns-5b9d99c8f4-7xxdk                                    0/1     Completed                0                24h
kube-system   coredns-5b9d99c8f4-bvtvh                                    0/1     Completed                0                122m
kube-system   coredns-5b9d99c8f4-p8xbm                                    0/1     Completed                0                24h
kube-system   coredns-5b9d99c8f4-tv8jw                                    1/1     Running                  0                78m
kube-system   ip-masq-agent-jnv46                                         1/1     Running                  0                122m
kube-system   ip-masq-agent-rcmlh                                         1/1     Running                  0                64m
kube-system   ip-masq-agent-z9crf                                         1/1     Running                  0                78m
kube-system   kube-dns-autoscaler-6f89667998-pw5z4                        0/1     Error                    0                24h
kube-system   kube-dns-autoscaler-6f89667998-x89mg                        1/1     Running                  0                78m
kube-system   kube-proxy-tl9pj                                            1/1     Running                  0                78m
kube-system   kube-proxy-tlnkb                                            1/1     Running                  0                64m
kube-system   kube-proxy-wmfxc                                            1/1     Running                  0                122m
kube-system   metrics-server-6568ff6f44-4vw5d                             0/1     Completed                0                24h
kube-system   metrics-server-6568ff6f44-76c95                             1/1     Running                  0                78m
kube-system   metrics-server-6568ff6f44-g27w9                             1/1     Running                  0                64m
kube-system   metrics-server-6568ff6f44-rhppf                             0/1     Completed                0                24h
kube-system   npd-v0.8.0-6sb4c                                            1/1     Running                  0                78m
kube-system   npd-v0.8.0-jm98k                                            1/1     Running                  0                64m
kube-system   npd-v0.8.0-ljfnk                                            1/1     Running                  1                122m
kube-system   yc-disk-csi-node-v2-4czpj                                   6/6     Running                  1                64m
kube-system   yc-disk-csi-node-v2-6nft9                                   6/6     Running                  1                78m
kube-system   yc-disk-csi-node-v2-xnf58                                   6/6     Running                  0                122m
monitoring    alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running                  0                13m
monitoring    kube-prometheus-stack-grafana-5c878c597-st9b7               3/3     Running                  0                13m
monitoring    kube-prometheus-stack-kube-state-metrics-6fb5dddbdb-h9hbt   1/1     Running                  0                13m
monitoring    kube-prometheus-stack-operator-67f99b8b8b-ps2lc             1/1     Running                  0                13m
monitoring    kube-prometheus-stack-prometheus-node-exporter-lwpd4        1/1     Running                  0                13m
monitoring    kube-prometheus-stack-prometheus-node-exporter-xcnqq        1/1     Running                  0                13m
monitoring    kube-prometheus-stack-prometheus-node-exporter-xl85d        1/1     Running                  0                13m
monitoring    prometheus-kube-prometheus-stack-prometheus-0               2/2     Running                  0                13m
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get svc -A
NAMESPACE     NAME                                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
app           testapp-service                                  NodePort    10.96.130.127   <none>        80:30180/TCP                    10m
default       grafana-service                                  NodePort    10.96.168.136   <none>        3000:30101/TCP                  23h
default       kubernetes                                       ClusterIP   10.96.128.1     <none>        443/TCP                         24h
default       testapp-service                                  NodePort    10.96.246.96    <none>        80:30102/TCP                    23h
kube-system   calico-typha                                     ClusterIP   10.96.216.1     <none>        5473/TCP                        24h
kube-system   kube-dns                                         ClusterIP   10.96.128.2     <none>        53/UDP,53/TCP,9153/TCP          24h
kube-system   kube-prometheus-stack-coredns                    ClusterIP   None            <none>        9153/TCP                        14m
kube-system   kube-prometheus-stack-kube-controller-manager    ClusterIP   None            <none>        10257/TCP                       14m
kube-system   kube-prometheus-stack-kube-etcd                  ClusterIP   None            <none>        2381/TCP                        14m
kube-system   kube-prometheus-stack-kube-proxy                 ClusterIP   None            <none>        10249/TCP                       14m
kube-system   kube-prometheus-stack-kube-scheduler             ClusterIP   None            <none>        10259/TCP                       14m
kube-system   kube-prometheus-stack-kubelet                    ClusterIP   None            <none>        10250/TCP,10255/TCP,4194/TCP    14m
kube-system   metrics-server                                   ClusterIP   10.96.208.69    <none>        443/TCP                         24h
monitoring    alertmanager-operated                            ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP      14m
monitoring    kube-prometheus-stack-alertmanager               NodePort    10.96.235.199   <none>        9093:30093/TCP,8080:30156/TCP   14m
monitoring    kube-prometheus-stack-grafana                    NodePort    10.96.217.211   <none>        80:30000/TCP                    14m
monitoring    kube-prometheus-stack-kube-state-metrics         ClusterIP   10.96.221.249   <none>        8080/TCP                        14m
monitoring    kube-prometheus-stack-operator                   ClusterIP   10.96.162.112   <none>        443/TCP                         14m
monitoring    kube-prometheus-stack-prometheus                 NodePort    10.96.176.64    <none>        9090:30090/TCP,8080:31626/TCP   14m
monitoring    kube-prometheus-stack-prometheus-node-exporter   ClusterIP   10.96.149.4     <none>        9100/TCP                        14m
monitoring    prometheus-operated                              ClusterIP   None            <none>        9090/TCP                        14m
```

Проверим доступность по IP балансировщиков

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc load-balancer network-load-balancer get k8s-services-load-balancer
id: enpf3g2ikr8hup8458qu
folder_id: b1g2pak2mr3h8bt5nfam
created_at: "2025-10-14T18:45:56Z"
name: k8s-services-load-balancer
region_id: ru-central1
status: ACTIVE
type: EXTERNAL
listeners:
  - name: app-listener
    address: 158.160.165.44
    port: "80"
    protocol: TCP
    target_port: "80"
    ip_version: IPV4
  - name: grafana-listener
    address: 158.160.165.44
    port: "3000"
    protocol: TCP
    target_port: "3000"
    ip_version: IPV4
attached_target_groups:
  - target_group_id: enp1308h4k6apj3fpd0v
    health_checks:
      - name: app-healthcheck
        interval: 2s
        timeout: 1s
        unhealthy_threshold: "2"
        healthy_threshold: "2"
        http_options:
          port: "30180"
          path: /healthz

user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc load-balancer target-group get k8s-nodes-target-group
id: enp1308h4k6apj3fpd0v
folder_id: b1g2pak2mr3h8bt5nfam
created_at: "2025-10-14T18:42:46Z"
name: k8s-nodes-target-group
region_id: ru-central1
targets:
  - subnet_id: e2l2pe3a9tbhubgasu7g
    address: 10.0.2.34
  - subnet_id: e9bvamfk1tg5onjejbuu
    address: 10.0.1.18
  - subnet_id: fl8j7vd5kl32pi4phvmf
    address: 10.0.3.29

user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc load-balancer target-group get k8s-nodes-target-group --format json | jq '.targets[] | {address: .address, status: .status}'
{
  "address": "10.0.2.34",
  "status": null
}
{
  "address": "10.0.1.18",
  "status": null
}
{
  "address": "10.0.3.29",
  "status": null
}
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://89.169.152.21:30180/healthz
*   Trying 89.169.152.21:30180...
* Connected to 89.169.152.21 (89.169.152.21) port 30180
> GET /healthz HTTP/1.1
> Host: 89.169.152.21:30180
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Tue, 14 Oct 2025 18:53:54 GMT
< Content-Type: application/octet-stream
< Content-Length: 8
< Connection: keep-alive
< Content-Type: text/plain
<
healthy
* Connection #0 to host 89.169.152.21 left intact
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://84.201.152.99:30180/healthz
*   Trying 84.201.152.99:30180...
* Connected to 84.201.152.99 (84.201.152.99) port 30180
> GET /healthz HTTP/1.1
> Host: 84.201.152.99:30180
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Tue, 14 Oct 2025 18:54:00 GMT
< Content-Type: application/octet-stream
< Content-Length: 8
< Connection: keep-alive
< Content-Type: text/plain
<
healthy
* Connection #0 to host 84.201.152.99 left intact
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://158.160.197.70:30180/healthz
*   Trying 158.160.197.70:30180...
* Connected to 158.160.197.70 (158.160.197.70) port 30180
> GET /healthz HTTP/1.1
> Host: 158.160.197.70:30180
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Tue, 14 Oct 2025 18:54:05 GMT
< Content-Type: application/octet-stream
< Content-Length: 8
< Connection: keep-alive
< Content-Type: text/plain
<
healthy
* Connection #0 to host 158.160.197.70 left intact
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ echo "Проверка Grafana на нодах:"
Проверка Grafana на нодах:
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://89.169.152.21:30000/api/health
*   Trying 89.169.152.21:30000...
* Connected to 89.169.152.21 (89.169.152.21) port 30000
> GET /api/health HTTP/1.1
> Host: 89.169.152.21:30000
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Cache-Control: no-store
< Content-Type: application/json; charset=UTF-8
< X-Content-Type-Options: nosniff
< X-Frame-Options: deny
< X-Xss-Protection: 1; mode=block
< Date: Tue, 14 Oct 2025 18:54:16 GMT
< Content-Length: 101
<
{
  "commit": "03f502a94d17f7dc4e6c34acdf8428aedd986e4c",
  "database": "ok",
  "version": "10.4.0"
* Connection #0 to host 89.169.152.21 left intact
}user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://84.201.152.99:30000/api/health
*   Trying 84.201.152.99:30000...
* Connected to 84.201.152.99 (84.201.152.99) port 30000
> GET /api/health HTTP/1.1
> Host: 84.201.152.99:30000
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Cache-Control: no-store
< Content-Type: application/json; charset=UTF-8
< X-Content-Type-Options: nosniff
< X-Frame-Options: deny
< X-Xss-Protection: 1; mode=block
< Date: Tue, 14 Oct 2025 18:54:22 GMT
< Content-Length: 101
<
{
  "commit": "03f502a94d17f7dc4e6c34acdf8428aedd986e4c",
  "database": "ok",
  "version": "10.4.0"
* Connection #0 to host 84.201.152.99 left intact
}user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://158.160.197.70:30000/api/health
*   Trying 158.160.197.70:30000...
* Connected to 158.160.197.70 (158.160.197.70) port 30000
> GET /api/health HTTP/1.1
> Host: 158.160.197.70:30000
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Cache-Control: no-store
< Content-Type: application/json; charset=UTF-8
< X-Content-Type-Options: nosniff
< X-Frame-Options: deny
< X-Xss-Protection: 1; mode=block
< Date: Tue, 14 Oct 2025 18:54:27 GMT
< Content-Length: 101
<
{
  "commit": "03f502a94d17f7dc4e6c34acdf8428aedd986e4c",
  "database": "ok",
  "version": "10.4.0"
* Connection #0 to host 158.160.197.70 left intact
```

Мониторинг Входим в Grafana http://158.160.197.70:3000/ c ```admin/prom-operator```, открываем дашборд Kubernetes / Compute Resources / Cluster по ссылке: ```http://89.169.152.21:30000/d/efa86fd1d0c121a26444b636a3f509a8/kubernetes-compute-resources-cluster?orgId=1&refresh=10s```

<img width="2276" height="1468" alt="image" src="https://github.com/user-attachments/assets/1c9a08a6-6049-4786-a2a6-8d7e58128f9b" />
