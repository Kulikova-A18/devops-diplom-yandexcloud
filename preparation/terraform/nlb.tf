# nlb.tf

# Target group для нод кластера с внутренними IP адресами
resource "yandex_lb_target_group" "k8s_nodes" {
  name = "k8s-nodes-target-group"

  # Нода в ru-central1-a
  target {
    subnet_id = yandex_vpc_subnet.central1-a.id
    address   = "10.0.1.18"  # Внутренний IP ноды cl1s0g5l6bcohghv6dje-avib
  }

  # Нода в ru-central1-b  
  target {
    subnet_id = yandex_vpc_subnet.central1-b.id
    address   = "10.0.2.34"  # Внутренний IP ноды cl1s0g5l6bcohghv6dje-idys
  }

  # Нода в ru-central1-d
  target {
    subnet_id = yandex_vpc_subnet.central1-d.id
    address   = "10.0.3.29"  # Внутренний IP ноды cl1s0g5l6bcohghv6dje-ivac
  }

  depends_on = [yandex_kubernetes_node_group.cluster_nodes]
}

# Один Network Load Balancer для всех сервисов
resource "yandex_lb_network_load_balancer" "k8s_services" {
  name = "k8s-services-load-balancer"

  # Listener для приложения (port 80)
  listener {
    name = "app-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  # Listener для Grafana (port 3000)
  listener {
    name = "grafana-listener"
    port = 3000
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s_nodes.id

    # Используем healthcheck для приложения как основной
    healthcheck {
      name = "app-healthcheck"
      http_options {
        port = 30180
        path = "/healthz"
      }
    }
  }

  depends_on = [yandex_lb_target_group.k8s_nodes]
}
