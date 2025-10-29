#!/bin/bash

echo "=== Полное развертывание проекта DevOps Diplom ==="

# Проверка наличия необходимых инструментов
command -v yc >/dev/null 2>&1 || { echo "YC CLI не установлен"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl не установлен"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm не установлен"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker не установлен"; exit 1; }

# Выполнение скриптов по порядку
./1-setup-infrastructure.sh
./2-create-k8s-cluster.sh
./3-setup-ingress.sh
./4-build-and-push-images.sh
./5-deploy-application.sh
./6-setup-monitoring.sh

echo "=== Развертывание завершено успешно ==="
echo "Приложение доступно по адресу:"
kubectl get ingress -n diplom-app
echo ""
echo "Grafana доступна по адресу:"
kubectl get service kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
