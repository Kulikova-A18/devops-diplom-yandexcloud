#!/bin/bash

# Variables
REGISTRY_ID="crps1p5u048a00f4o97j"
IMAGE_NAME="testapp"
VERSION="1.0.1"
APP_DIR="../testapp"

echo "Building Docker image..."
echo "Registry ID: $REGISTRY_ID"

cd $APP_DIR

# Login to Yandex Container Registry
yc container registry configure-docker

# Build Docker image
docker build -t cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION .

# Push to registry
docker push cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION

# Also tag as latest
docker tag cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION cr.yandex/$REGISTRY_ID/$IMAGE_NAME:latest
docker push cr.yandex/$REGISTRY_ID/$IMAGE_NAME:latest

echo "========================================="
echo "Image pushed successfully!"
echo "Image: cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$VERSION"
echo "Latest: cr.yandex/$REGISTRY_ID/$IMAGE_NAME:latest"
echo "========================================="
