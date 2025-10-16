variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default     = "b1gphk6fe2qpbmph96u5"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  default     = "b1g2pak2mr3h8bt5nfam"
}

variable "default_zone" {
  description = "Default zone for resources"
  type        = string
  default     = "ru-central1-a"
}

variable "service_account_id" {
  description = "Service Account ID for Kubernetes"
  type        = string
  default     = "ajer93efebn650j9q2ta"
}
