# monitoring.tf - без ServiceMonitor

# Установка kube-prometheus-stack через Helm provider
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true
  version    = "58.0.0"

  values = [
    <<-EOT
    grafana:
      adminPassword: "prom-operator"
      service:
        type: NodePort
        nodePort: 30000
    prometheus:
      service:
        type: NodePort
        nodePort: 30090
    alertmanager:
      service:
        type: NodePort
        nodePort: 30093
    EOT
  ]

  depends_on = [
    yandex_kubernetes_cluster.devops-diplom
  ]
}
