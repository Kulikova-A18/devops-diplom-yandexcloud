#  Проект для развертывания полнофункционального приложения в Yandex Cloud с использованием Kubernetes, мониторинга и CI/CD.

## Скрипты развертывания

| Скрипт | Назначение | Ссылка |
|--------|------------|--------|
| **deploy-all.sh** | Полное автоматическое развертывание всего проекта | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/deploy-all.sh |
| **1-setup-infrastructure.sh** | Создание инфраструктуры в Yandex Cloud | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/1-setup-infrastructure.sh |
| **2-create-k8s-cluster.sh** | Создание Kubernetes кластера | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/2-create-k8s-cluster.sh |
| **3-setup-ingress.sh** | Установка Nginx Ingress Controller | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/3-setup-ingress.sh |
| **4-build-and-push-images.sh** | Сборка и загрузка Docker образов | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/4-build-and-push-images.sh |
| **5-deploy-application.sh** | Развертывание приложения в Kubernetes | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/5-deploy-application.sh |
| **6-setup-monitoring.sh** | Настройка мониторинга и логирования | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/6-setup-monitoring.sh |
| **cleanup.sh** | Очистка всех созданных ресурсов | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/cleanup.sh |
| **check-status.sh** | Проверка статуса развертывания | https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/check-status.sh |

## Быстрый старт

```bash
chmod +x *.sh
./deploy-all.sh
./check-status.sh
```

## Очистить ресурсы (когда нужно удалить)

```bash
./cleanup.sh
```

## Требования

- Yandex Cloud CLI (`yc`)
- Kubernetes CLI (`kubectl`)
- Helm
- Docker
- jq (для обработки JSON)

## Структура проекта

- `src/` - Исходный код приложения
- `k8s/` - Kubernetes манифесты
- `monitoring/` - Конфигурации мониторинга
- Скрипты развертывания (в этом каталоге)
