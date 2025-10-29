#!/bin/bash

echo "=== Часть 5: Развертывание приложения в Kubernetes ==="

# Получение идентификатора реестра
REGISTRY_ID=$(yc container registry get --name diplom-registry --format json | jq -r '.id')
REGISTRY="cr.yandex/$REGISTRY_ID"

# Создание namespace
echo "Создание namespace..."
kubectl create namespace diplom-app

# Создание secret с учетными данными для доступа к registry
echo "Создание secret для доступа к registry..."
kubectl create secret docker-registry registry-credentials \
  --docker-server=cr.yandex \
  --docker-username=json_key \
  --docker-password="$(yc iam key create --service-account-name diplom-sa --output json | jq -r '.private_key')" \
  --namespace diplom-app

# Применение манифестов
echo "Применение манифестов приложения..."
kubectl apply -f ../k8s/ -n diplom-app

# Ожидание запуска подов
echo "Ожидание запуска подов..."
kubectl wait --for=condition=ready pod -l app=backend -n diplom-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n diplom-app --timeout=300s

# Проверка статуса развертывания
echo "Проверка статуса развертывания..."
kubectl get all -n diplom-app

# Получение внешнего IP адреса
echo "Внешний IP адрес:"
kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

echo "=== Приложение успешно развернуто ==="
