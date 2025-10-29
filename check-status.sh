#!/bin/bash

echo "=== Статус развертывания ==="

echo "1. Kubernetes Nodes:"
kubectl get nodes

echo ""
echo "2. Поды в namespace diplom-app:"
kubectl get pods -n diplom-app

echo ""
echo "3. Сервисы:"
kubectl get services -n diplom-app

echo ""
echo "4. Ingress:"
kubectl get ingress -n diplom-app

echo ""
echo "5. Поды мониторинга:"
kubectl get pods -n monitoring

echo ""
echo "6. Внешние IP адреса:"
echo "Приложение:"
kubectl get ingress -n diplom-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}'
echo ""
echo "Grafana:"
kubectl get service kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Не доступен"
