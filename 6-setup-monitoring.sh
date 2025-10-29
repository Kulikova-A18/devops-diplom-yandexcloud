#!/bin/bash

echo "=== Часть 6: Настройка мониторинга и логирования ==="

# Создание namespace для мониторинга
kubectl create namespace monitoring

# Установка Prometheus Stack
echo "Установка kube-prometheus-stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=7d \
  --set grafana.adminPassword=admin \
  --set grafana.service.type=LoadBalancer

# Установка Loki для логирования
echo "Установка Loki..."
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true

# Применение ServiceMonitor для приложения
echo "Настройка мониторинга приложения..."
kubectl apply -f ../monitoring/ -n diplom-app

# Ожидание запуска компонентов мониторинга
echo "Ожидание запуска компонентов мониторинга..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

# Получение доступа к Grafana
echo "Grafana Dashboard:"
GRAFANA_IP=$(kubectl get service kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$GRAFANA_IP:3000"
echo "Username: admin"
echo "Password: admin"

echo "=== Мониторинг настроен успешно ==="
