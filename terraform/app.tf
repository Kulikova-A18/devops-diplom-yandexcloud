# app.tf

# Namespace для приложения
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "app"
  }

  depends_on = [yandex_kubernetes_cluster.devops-diplom]
}

# Deployment для тестового приложения
resource "kubernetes_deployment" "testapp" {
  metadata {
    name      = "testapp"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "testapp"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "testapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "testapp"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "80"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          image = "cr.yandex/crps1p5u048a00f4o97j/testapp:1.0.1"
          name  = "testapp"

          port {
            container_port = 80
            name           = "http"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# Service для тестового приложения с другим NodePort
resource "kubernetes_service" "testapp" {
  metadata {
    name      = "testapp-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "testapp"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "80"
      "prometheus.io/path"   = "/metrics"
    }
  }

  spec {
    selector = {
      app = "testapp"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      node_port   = 30180  # Изменяем на другой порт
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.testapp]
}

# Ingress для тестового приложения
resource "kubernetes_ingress_v1" "testapp_ingress" {
  metadata {
    name      = "testapp-ingress"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "testapp-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.testapp]
}
