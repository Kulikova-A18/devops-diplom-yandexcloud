# Пока закомментируем все проблемные ресурсы
/*
resource "local_file" "inventory" {
  content = templatefile("template/inventory.tftpl", {
    masters = yandex_compute_instance_group.k8s-masters.instances[*].network_interface[0].ip_address
    workers = yandex_compute_instance_group.k8s-workers.instances[*].network_interface[0].ip_address
  })
  filename        = "../ansible/kubespray/inventory/mycluster/inventory.ini"
  file_permission = "0777"
}
*/
