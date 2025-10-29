#!/bin/bash

# Переменные
YC_CLUSTER_NAME="diplom-cluster"
YC_K8S_VERSION="1.28"
YC_NODE_SERVICE_ACCOUNT="diplom-sa"
YC_PREEMPTIBLE="true"

echo "=== Часть 2: Создание Kubernetes кластера ==="

# Создание кластера Kubernetes
echo "Создание Kubernetes кластера..."
yc managed-kubernetes cluster create \
  --name $YC_CLUSTER_NAME \
  --network-name diplom-network \
  --zone ru-central1-a \
  --subnet-name diplom-subnet \
  --public-ip \
  --release-channel regular \
  --version $YC_K8S_VERSION \
  --cluster-ipv4-range 10.10.0.0/16 \
  --service-ipv4-range 10.11.0.0/16 \
  --security-group-name diplom-sg \
  --node-service-account-name $YC_NODE_SERVICE_ACCOUNT

# Создание группы узлов
echo "Создание группы узлов..."
yc managed-kubernetes node-group create \
  --name diplom-node-group \
  --cluster-name $YC_CLUSTER_NAME \
  --platform-id standard-v3 \
  --public-ip \
  --cores 2 \
  --memory 4 \
  --core-fraction 50 \
  --disk-type network-ssd \
  --disk-size 64 \
  --fixed-size 2 \
  --preemptible $YC_PREEMPTIBLE \
  --network-interface subnets=diplom-subnet,ipv4-address=auto,security-group-ids=auto

# Получение kubeconfig
echo "Получение kubeconfig..."
yc managed-kubernetes cluster get-credentials $YC_CLUSTER_NAME --external --force

# Проверка подключения к кластеру
echo "Проверка подключения к кластеру..."
kubectl cluster-info
kubectl get nodes

echo "=== Kubernetes кластер создан успешно ==="
