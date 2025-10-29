#!/bin/bash

echo "=== Часть 3: Установка Nginx Ingress Controller ==="

# Добавление репозитория Helm
echo "Добавление репозитория Helm..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Установка Nginx Ingress Controller
echo "Установка Nginx Ingress Controller..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.config.proxy-real-ip-cidr=0.0.0.0/0 \
  --set controller.config.use-forwarded-headers=true

# Ожидание получения внешнего IP
echo "Ожидание получения внешнего IP..."
kubectl get service ingress-nginx-controller -n ingress-nginx -w
