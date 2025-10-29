#!/bin/bash

# Переменные
YC_FOLDER_ID="your_folder_id"
YC_SERVICE_ACCOUNT="diplom-sa"
YC_NETWORK_NAME="diplom-network"
YC_SUBNET_NAME="diplom-subnet"
YC_SECURITY_GROUP="diplom-sg"

echo "=== Часть 1: Создание инфраструктуры в Yandex Cloud ==="

# Создание service account
echo "Создание service account..."
yc iam service-account create --name $YC_SERVICE_ACCOUNT --folder-id $YC_FOLDER_ID

# Назначение ролей
echo "Назначение ролей service account..."
YC_SA_ID=$(yc iam service-account get $YC_SERVICE_ACCOUNT --format json | jq -r '.id')

yc resource-manager folder add-access-binding $YC_FOLDER_ID \
  --role editor \
  --subject serviceAccount:$YC_SA_ID

yc resource-manager folder add-access-binding $YC_FOLDER_ID \
  --role storage.editor \
  --subject serviceAccount:$YC_SA_ID

yc resource-manager folder add-access-binding $YC_FOLDER_ID \
  --role container-registry.images.pusher \
  --subject serviceAccount:$YC_SA_ID

# Создание статического ключа доступа
echo "Создание статического ключа доступа..."
yc iam access-key create --service-account-name $YC_SERVICE_ACCOUNT --format json > key.json
export AWS_ACCESS_KEY_ID=$(cat key.json | jq -r '.access_key.key_id')
export AWS_SECRET_ACCESS_KEY=$(cat key.json | jq -r '.secret')

# Создание сети и подсети
echo "Создание сети и подсети..."
yc vpc network create --name $YC_NETWORK_NAME
yc vpc subnet create \
  --name $YC_SUBNET_NAME \
  --network-name $YC_NETWORK_NAME \
  --zone ru-central1-a \
  --range 192.168.10.0/24

# Создание группы безопасности
echo "Создание группы безопасности..."
yc vpc security-group create \
  --name $YC_SECURITY_GROUP \
  --network-name $YC_NETWORK_NAME \
  --rule "direction=ingress,port=80,protocol=tcp,v4-cidrs=0.0.0.0/0" \
  --rule "direction=ingress,port=443,protocol=tcp,v4-cidrs=0.0.0.0/0" \
  --rule "direction=ingress,port=30080,protocol=tcp,v4-cidrs=0.0.0.0/0" \
  --rule "direction=ingress,port=22,protocol=tcp,v4-cidrs=0.0.0.0/0"

echo "=== Инфраструктура создана успешно ==="
echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
