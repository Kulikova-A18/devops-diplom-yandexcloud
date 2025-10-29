#!/bin/bash

echo "=== Часть 4: Создание и загрузка Docker образов ==="

# Создание Container Registry
echo "Создание Container Registry..."
yc container registry create --name diplom-registry

# Аутентификация в Container Registry
echo "Аутентификация в Container Registry..."
yc container registry configure-docker

# Получение идентификатора реестра
REGISTRY_ID=$(yc container registry get --name diplom-registry --format json | jq -r '.id')
REGISTRY="cr.yandex/$REGISTRY_ID"

# Сборка и загрузка образа backend
echo "Сборка и загрузка образа backend..."
docker build -t $REGISTRY/backend:latest -f ../src/backend/Dockerfile ../src/backend/
docker push $REGISTRY/backend:latest

# Сборка и загрузка образа frontend
echo "Сборка и загрузка образа frontend..."
docker build -t $REGISTRY/frontend:latest -f ../src/frontend/Dockerfile ../src/frontend/
docker push $REGISTRY/frontend:latest

echo "=== Образы успешно загружены в Container Registry ==="
echo "Registry: $REGISTRY"
