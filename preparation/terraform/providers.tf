# providers.tf

# Kubernetes provider
provider "kubernetes" {
  host                   = yandex_kubernetes_cluster.devops-diplom.master[0].external_v4_endpoint
  cluster_ca_certificate = yandex_kubernetes_cluster.devops-diplom.master[0].cluster_ca_certificate
  token                  = data.yandex_client_config.client.iam_token
}

# Helm provider - правильный синтаксис
provider "helm" {
  kubernetes = {
    host                   = yandex_kubernetes_cluster.devops-diplom.master[0].external_v4_endpoint
    cluster_ca_certificate = yandex_kubernetes_cluster.devops-diplom.master[0].cluster_ca_certificate
    token                  = data.yandex_client_config.client.iam_token
  }
}
