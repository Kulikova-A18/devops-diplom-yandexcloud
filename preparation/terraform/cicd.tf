# Используем существующий Service Account по ID из key.json
data "yandex_iam_service_account" "existing_sa" {
  service_account_id = "ajer93efebn650j9q2ta"  # Используем ID из key.json
}

# Kubernetes Service Account для CI/CD деплоя
resource "kubernetes_service_account" "cicd" {
  metadata {
    name      = "cicd-service-account"
    namespace = "default"
  }
}

# ClusterRoleBinding для CI/CD Service Account
resource "kubernetes_cluster_role_binding" "cicd" {
  metadata {
    name = "cicd-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cicd.metadata[0].name
    namespace = "default"
  }
}

# ConfigMap с настройками для CI/CD
resource "kubernetes_config_map" "cicd_config" {
  metadata {
    name      = "cicd-config"
    namespace = "default"
  }

  data = {
    registry-url     = "cr.yandex/${yandex_container_registry.app_registry.id}"
    cluster-endpoint = yandex_kubernetes_cluster.devops-diplom.master[0].external_v4_endpoint
    cluster-ca-cert  = yandex_kubernetes_cluster.devops-diplom.master[0].cluster_ca_certificate
    sa-id            = data.yandex_iam_service_account.existing_sa.id
    sa-name          = data.yandex_iam_service_account.existing_sa.name
  }
}

# Secret с информацией для CI/CD
resource "kubernetes_secret" "cicd_secrets" {
  metadata {
    name      = "cicd-secrets"
    namespace = "default"
  }

  data = {
    sa-id   = data.yandex_iam_service_account.existing_sa.id
    sa-name = data.yandex_iam_service_account.existing_sa.name
  }

  depends_on = [yandex_kubernetes_cluster.devops-diplom]
}