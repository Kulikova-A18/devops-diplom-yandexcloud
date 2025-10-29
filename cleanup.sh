#!/bin/bash

echo "=== Очистка ресурсов ==="

# Удаление приложения
kubectl delete namespace diplom-app

# Удаление мониторинга
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall loki -n monitoring
kubectl delete namespace monitoring

# Удаление ingress controller
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx

# Удаление Kubernetes кластера
yc managed-kubernetes cluster delete --name diplom-cluster

# Удаление Container Registry
yc container registry delete --name diplom-registry

# Удаление сети
yc vpc security-group delete --name diplom-sg
yc vpc subnet delete --name diplom-subnet
yc vpc network delete --name diplom-network

# Удаление service account
yc iam service-account delete --name diplom-sa

echo "=== Все ресурсы удалены ==="
