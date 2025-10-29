# Дипломный практикум в Yandex.Cloud

Данный дипломный практикум в Yandex.Cloud выполнила Куликова А.В. NETOLOGY-SHVIRTD-17

## Цели дипломного практикума в Yandex.Cloud

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

## 1. Создание облачной инфраструктуры

### Цель

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.

### Подготовка

0. Необходимо установить CLI installation по инструкции: `https://yandex.cloud/en/docs/cli/operations/install-cli`
1. Проверка текущей конфигурации*

```shell
user@compute-vm-2-1-10-hdd-1742233033265:~$ yc config list
service-account-key:
  id: ajen0eb8uk1qllevo48q
  service_account_id: ajevr3943agpiaa65qau
  created_at: "2025-03-24T18:17:06.795831372Z"
  key_algorithm: RSA_2048
  public_key: |
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzNUUYZDgFbnbrnUwEZOj
    5Ou+SHX18Qu25T86AnpXC/u+c77OtPK/d9ahUkKVt1w+lBPttL0bPbvIU5S2mQnJ
    ***
    7wIDAQAB
    -----END PUBLIC KEY-----
  private_key: |
    PLEASE DO NOT REMOVE THIS LINE! Yandex.Cloud SA Key ID <ajen0eb8uk1qllevo48q>
    -----BEGIN PRIVATE KEY-----
    ***
    876eCXb3q6JXkA9+VUNloYLiUuUBWMcf35o4uyolyDju7JRWo+Z3UQKBgH5H5mNp
    zIyb7/22szaeqHCAk1a5XyhZkSVuqHz8s0Ikshx6/H+dPyy066P+KuH3ZxbdtfJ5
    ***
    uT7HUERC26O1jyOVU9YiSLf8ujWqUJi0KcxEj88kmLnX4GZfLkP1OFkwySxIRCQ2
    LbidgnmJ25E7J2TSuVe2Kq8BuaTTRLqGP3XUqq5AmUjdCE3RoX91lLiS/AjH597X
    LGTfGCjN8klz6bSYTsg5
    -----END PRIVATE KEY-----
cloud-id: b1gphk6fe2qpbmph96u5
folder-id: b1g2pak2mr3h8bt5nfam
compute-default-zone: ru-central1-a
```

> После сдачи машинка со всеми данными будет удалена. Чувствительная информация будет не действительна

### Выполнение

Для подгтовки облачной инфрастуктуры использем terraform и платформу Yandex.Cloud.

Создаем сервисный аккаунт в Yandex.Cloud с минимальными, но достаточными правами

> Во время выполнения уже авторизованы под сервисным аккаунтом, который уже работает в конкретной папке (```folder_id: b1g2pak2mr3h8bt5nfam```). У этого сервисного аккаунта нет прав создавать новые папки на уровне облака, но он может работать внутри своей папки

Создаем сервисный аккаунт в существующей папке ```yc iam service-account create --name devops-diplom-yandexcloud-sa --folder-id b1g2pak2mr3h8bt5nfam```

<details>
    <summary>подробнее</summary>
  
```shell
user@compute-vm-2-1-10-hdd-1742233033265:~$ yc iam service-account create --name devops-diplom-yandexcloud-sa --folder-id b1g2pak2mr3h8bt5nfam
done (1s)
id: ajer93efebn650j9q2ta
folder_id: b1g2pak2mr3h8bt5nfam
created_at: "2025-10-12T17:38:26.407820371Z"
name: devops-diplom-yandexcloud-sa
```
</details>

Получаем ID созданного сервисного аккаунта ```yc iam service-account get devops-diplom-yandexcloud-sa --format json | jq -r '.id'```

<details>
    <summary>подробнее</summary>
  
```shell
user@compute-vm-2-1-10-hdd-1742233033265:~$ yc iam service-account get devops-diplom-yandexcloud-sa --format json | jq -r '.id'
ajer93efebn650j9q2ta
```
</details>

Назначаем права сервисному аккаунту ```yc resource-manager folder add-access-binding b1g2pak2mr3h8bt5nfam --role editor --subject serviceAccount:<SA_ID>```

<SA_ID> - реальный ID из шага 2

> <SA_ID> = ajer93efebn650j9q2ta

<details>
    <summary>подробнее</summary>
  
```shell
user@compute-vm-2-1-10-hdd-1742233033265:~$ yc resource-manager folder add-access-binding b1g2pak2mr3h8bt5nfam --role editor --subject serviceAccount:ajer93efebn650j9q2ta
done (2s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: editor
      subject:
        id: ajer93efebn650j9q2ta
        type: serviceAccount
```
</details>

Создаем ключ доступа ```yc iam key create --service-account-name devops-diplom-yandexcloud-sa --folder-id b1g2pak2mr3h8bt5nfam --output key.json```

<details>
    <summary>подробнее</summary>
  
```shell
user@compute-vm-2-1-10-hdd-1742233033265:~$ yc iam key create --service-account-name devops-diplom-yandexcloud-sa --folder-id b1g2pak2mr3h8bt5nfam --output key.json
id: ajeau9qmpfmn0obm9kei
service_account_id: ajer93efebn650j9q2ta
created_at: "2025-10-12T17:47:43.156406564Z"
key_algorithm: RSA_2048
```
</details>

Проверяем, что ключ создан ```ls -la key.json``` и ```cat key.json | jq -r '.id'```

<details>
    <summary>подробнее</summary>
  
```shell
user@compute-vm-2-1-10-hdd-1742233033265:~$ ls -la key.json
-rw------- 1 user user 2491 Oct 12 17:47 key.json
user@compute-vm-2-1-10-hdd-1742233033265:~$ cat key.json
{
   "id": "ajeau9qmpfmn0obm9kei",
   "service_account_id": "ajer93efebn650j9q2ta",
   "created_at": "2025-10-12T17:47:43.156406564Z",
   "key_algorithm": "RSA_2048",
   "public_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBg******1Ydz5iUim9M0uKgw0Rl7IhpySzg+1YMqKfaaHm3mpHx+2O/UM5pfr4I1\n4pz1HOpchh0hKhEBB2RKz6BewEeT3SsLDzdDmtI0jTLXv+bDLc95hCf2n6zQ3FQG\nIJMbHJ0BWRKXj5xAdRVYu1ZbguAlQSZRAAxDO+4e7UHHqQMLjP9CQYMV2/c3DBB+\nYQIDAQAB\n-----END PUBLIC KEY-----\n",
   "private_key": "PLEASE DO NOT REMOVE THIS LINE! Yandex.Cloud SA Key ID \u003cajeau9qmpfmn0obm9kei\u003e\n-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDZsuS6B+AAKwWk\n9XZ2PgzJqUB1o06uETuKIlJPpjTTuO1nRLACSlNApM0dKfVvC******************************************ngt4+6KC1JmcUwVlVeNGgZTZlBDIUigy4mGoPpLWQ16DOfszaoo020cu4CM/ojOa0\naHTlKltFi3xCB3Q1NORLEtqLoOI7G7kcuyKqzVl1AoGAe8KtdwYFI6e9w5PzDouM\nYPTMMbx2vWSwKEhlbrmu9Mhn+VE/rEj+QxScQYDObmTJmhQWmgdeFgW8EkTODlzd\ncjZTxOdteFn7ZiMMb+DtMCc3pwEzoHVlyu3W/3O/Q2IV20SUu70w3wxE8YIqhi7Y\nBAfCn5zX90xA82A2YvZF1jo=\n-----END PRIVATE KEY-----\n"
}user@compute-vm-2-1-10-hdd-1742233033265:~$
```
</details>

Готовим terraform который создаст специальную сервисную учетку `tf-sa` и S3 бакет для terraform backend в основном проекте в отдельной папке ( https://github.com/Kulikova-A18/devops-diplom-yandexcloud/tree/main/preparation ) и запускаем его

Результат:

`terraform apply --auto-approve`

> cloud_id = "b1gphk6fe2qpbmph96u5" и folder_id = "b1g2pak2mr3h8bt5nfam"

<details>
    <summary>подробнее</summary>

```shell
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ tree
.
├── ansible.tf
├── app.tf
├── cicd.tf
├── k8s-masters.tf
├── k8s-workers.tf
├── monitoring.tf
├── network.tf
├── nlb.tf
├── outputs.tf
├── providers.tf
├── template
│   └── inventory.tftpl
└── variables.tf

2 directories, 12 files
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching ">= 0.89.0"...
- Finding hashicorp/null versions matching ">= 3.0.0"...
- Finding hashicorp/local versions matching ">= 2.0.0"...
- Installing yandex-cloud/yandex v0.164.0...
- Installed yandex-cloud/yandex v0.164.0 (unauthenticated)
- Installing hashicorp/null v3.2.4...
- Installed hashicorp/null v3.2.4 (unauthenticated)
- Installing hashicorp/local v2.5.3...
- Installed hashicorp/local v2.5.3 (unauthenticated)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│
│ Due to your customized provider installation methods, Terraform was forced to calculate lock file checksums locally
│ for the following providers:
│   - hashicorp/local
│   - hashicorp/null
│   - yandex-cloud/yandex
│
│ The current .terraform.lock.hcl file only includes checksums for linux_amd64, so Terraform running on another
│ platform will fail to install these providers.
│
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ ls -la ~/.ssh/id_rsa*
-rw------- 1 user user 1856 Oct 12 18:10 /home/user/.ssh/id_rsa
-rw-r--r-- 1 user user  422 Oct 12 18:10 /home/user/.ssh/id_rsa.pub
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ sed -i 's|~/.ssh/id_rsa.pub|/home/user/.ssh/id_rsa.pub|' k8s-masters.tf
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc iam service-account list
yc iam service-account create --name vm-service-account --folder-id b1g2pak2mr3h8bt5nfam
SA_ID=$(yc iam service-account get vm-service-account --format json | jq -r '.id')
yc resource-manager folder add-access-binding b1g2pak2mr3h8bt5nfam \
  --role editor \
  --subject serviceAccount:$SA_ID
+----------------------+------------------------------+--------+---------------------+-----------------------+
|          ID          |             NAME             | LABELS |     CREATED AT      | LAST AUTHENTICATED AT |
+----------------------+------------------------------+--------+---------------------+-----------------------+
| ajer93efebn650j9q2ta | devops-diplom-yandexcloud-sa |        | 2025-10-12 17:38:26 | 2025-10-12 18:10:00   |
| ajevr3943agpiaa65qau | xcw55wtaa                    |        | 2025-03-24 17:59:54 | 2025-10-12 17:40:00   |
+----------------------+------------------------------+--------+---------------------+-----------------------+

user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ # Создать новый сервисный аккаунт для инстансов
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc iam service-account create --name vm-service-account --folder-id b1g2pak2mr3h8bt5nfam
done (1s)
id: ajeaedtelvo4jbaqukek
folder_id: b1g2pak2mr3h8bt5nfam
created_at: "2025-10-12T18:12:49.676026576Z"
name: vm-service-account
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ SA_ID=$(yc iam service-account get vm-service-account --format json | jq -r '.id')
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc resource-manager folder add-access-binding b1g2pak2mr3h8bt5nfam \
>   --role editor \
>   --subject serviceAccount:$SA_ID
done (2s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: editor
      subject:
        id: ajeaedtelvo4jbaqukek
        type: serviceAccount
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud$ git clone https://github.com/kubernetes-sigs/kubespray.git ansible/kubespray
Cloning into 'ansible/kubespray'...
remote: Enumerating objects: 84330, done.
remote: Counting objects: 100% (100/100), done.
remote: Compressing objects: 100% (63/63), done.
remote: Total 84330 (delta 70), reused 37 (delta 37), pack-reused 84230 (from 2)
Receiving objects: 100% (84330/84330), 27.47 MiB | 22.27 MiB/s, done.
Resolving deltas: 100% (47225/47225), done.
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud$ curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11913  100 11913    0     0   127k      0 --:--:-- --:--:-- --:--:--  129k
Downloading https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz
Verifying checksum... Done.
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/preparation$ SA_ID=$(yc iam service-account get tf-sa --format json | jq -r '.id')
ID: $SA_ID"user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/preparation$ echo "Service Account ID: $SA_ID"
Service Account ID: ajena75o7bbk24o8rqi0
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/preparation$ yc resource-manager folder add-access-binding b1g2pak2mr3h8bt5nfam \
-role editor \
  --subject serviceAccount:$S>   --role editor \
>   --subject serviceAccount:$SA_ID
done (2s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: editor
      subject:
        id: ajena75o7bbk24o8rqi0
        type: serviceAccount

user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/preparation$ terraform apply --auto-approve
var.cloud_id
  Enter a value: b1gphk6fe2qpbmph96u5

var.folder_id
  Enter a value: b1g2pak2mr3h8bt5nfam

yandex_iam_service_account.tf-sa: Refreshing state... [id=ajena75o7bbk24o8rqi0]
yandex_iam_service_account_static_access_key.tf-key: Refreshing state... [id=ajetvumev2v03ot62vs2]
null_resource.example: Refreshing state... [id=6905718889333603223]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # local_file.backend-conf will be created
  + resource "local_file" "backend-conf" {
      + content              = (sensitive value)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "../terraform/backend.key"
      + id                   = (known after apply)
    }

  # yandex_storage_bucket.s3-backet will be created
  + resource "yandex_storage_bucket" "s3-backet" {
      + access_key            = "YCAJEQkN5TTT1m3_Xb7tH7YJt"
      + acl                   = (known after apply)
      + bucket                = "devops-diplom-yandexcloud-bucket-mrg"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = true
      + id                    = (known after apply)
      + policy                = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags {
          + list = false
          + read = false
        }

      + grant (known after apply)

      + versioning (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
yandex_storage_bucket.s3-backet: Creating...
yandex_storage_bucket.s3-backet: Creation complete after 5s [id=devops-diplom-yandexcloud-bucket-mrg]
local_file.backend-conf: Creating...
local_file.backend-conf: Creation complete after 0s [id=40f9a60a2d7fb3de260c39fe69967f8e5581c4b4]

```
</details>

Готовим основновной манифест ( https://github.com/Kulikova-A18/devops-diplom-yandexcloud/tree/main/terraform ) terraform с VPC и запускаем егоиспользуя ключи из `backend.key` которые получили на прошлом шаге

Результат `terraform init -backend-config="access_key=***" -backend-config="secret_key=***"` и `terraform apply --auto-approve`

<details>
    <summary>подробнее</summary>

```shell
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ ls -la backend.key
ackend.key-rwxrwxr-x 1 user user 97 Oct 12 18:29 backend.key
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ cat backend.key
access_key = "YCA***7tH7YJt"
secret_key = "YCObfKz_5***OdVd3vPDaNiJ"
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ ls -lah
total 100K
drwxrwxr-x 4 user user 4.0K Oct 12 18:34 .
drwxrwxr-x 7 user user 4.0K Oct 12 18:15 ..
-rw-rw-r-- 1 user user 3.5K Oct 12 17:54 ansible.tf
-rw-rw-r-- 1 user user  510 Oct 12 17:54 app.tf
-rwxrwxr-x 1 user user   97 Oct 12 18:29 backend.key
-rw-rw-r-- 1 user user  528 Oct 12 17:54 cicd.tf
-rw-rw-r-- 1 user user  171 Oct 12 17:54 .gitignore
-rw-rw-r-- 1 user user 1.5K Oct 12 18:10 k8s-masters.tf
-rw-rw-r-- 1 user user 1.4K Oct 12 17:54 k8s-workers.tf
-rw------- 1 user user 2.5K Oct 12 18:27 key-tf-sa.json
-rw-rw-r-- 1 user user  650 Oct 12 18:01 monitoring.tf
-rw-rw-r-- 1 user user  884 Oct 12 17:54 network.tf
-rw-rw-r-- 1 user user 1.6K Oct 12 17:54 nlb.tf
-rw-rw-r-- 1 user user   81 Oct 12 17:54 outputs.tf
-rw-rw-r-- 1 user user 1.2K Oct 12 18:34 providers.tf
-rw-rw-r-- 1 user user  792 Oct 12 18:01 providers.tf.backup
-rw-rw-r-- 1 user user  808 Oct 12 18:03 providers.tf.backup2
drwxrwxr-x 2 user user 4.0K Oct 12 17:54 template
drwxr-xr-x 3 user user 4.0K Oct 12 18:33 .terraform
-rw-r--r-- 1 user user  644 Oct 12 18:06 .terraform.lock.hcl
-rw-rw-r-- 1 user user  182 Oct 12 18:27 terraform.tfstate
-rw-rw-r-- 1 user user 5.5K Oct 12 18:26 terraform.tfstate.backup
-rw-rw-r-- 1 user user  100 Oct 12 18:33 terraform.tfvars
-rw-rw-r-- 1 user user  882 Oct 12 17:54 variables.tf
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ rm -rf .terraform
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform init -backend-config="backend.key"
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/local from the dependency lock file
- Installing hashicorp/local v2.5.3...
- Installed hashicorp/local v2.5.3 (unauthenticated)
- Installing yandex-cloud/yandex v0.164.0...
- Installed yandex-cloud/yandex v0.164.0 (unauthenticated)
- Installing hashicorp/null v3.2.4...
- Installed hashicorp/null v3.2.4 (unauthenticated)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc compute instance-group list
+----------------------+-------------+--------+------+
|          ID          |    NAME     | STATUS | SIZE |
+----------------------+-------------+--------+------+
| cl1bjko7dt91pas989k6 | k8s-masters | ACTIVE |    3 |
+----------------------+-------------+--------+------+
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc compute instance-group delete --name k8s-masters --async
id: cl1akkip5r6ts33s80qr
description: Delete instance group
created_at: "2025-10-12T18:46:04.524975443Z"
created_by: ajevr3943agpiaa65qau
modified_at: "2025-10-12T18:46:04.524975443Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.compute.v1.instancegroup.DeleteInstanceGroupMetadata
  instance_group_id: cl1bjko7dt91pas989k6
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc compute instance-group list
+----------------------+-------------+----------+--------+
|          ID          |    NAME     |  STATUS  |  SIZE  |
+----------------------+-------------+----------+--------+
| cl1bjko7dt91pas989k6 | k8s-masters | DELETING | 0 -> 0 |
+----------------------+-------------+----------+--------+
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc compute instance-group list
+----+------+--------+------+
| ID | NAME | STATUS | SIZE |
+----+------+--------+------+
+----+------+--------+------+
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply -auto-approve
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance_group.k8s-masters will be created
  + resource "yandex_compute_instance_group" "k8s-masters" {
      + created_at          = (known after apply)
      + deletion_protection = false
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + instances           = (known after apply)
      + name                = "k8s-masters"
      + service_account_id  = "ajer93efebn650j9q2ta"
      + status              = (known after apply)

      + allocation_policy {
          + zones = [
              + "ru-central1-a",
              + "ru-central1-b",
              + "ru-central1-d",
            ]
        }

      + deploy_policy {
          + max_creating     = 3
          + max_deleting     = 3
          + max_expansion    = 3
          + max_unavailable  = 3
          + startup_duration = 0
          + strategy         = (known after apply)
        }

      + instance_template {
          + labels      = (known after apply)
          + metadata    = {
              + "ssh-keys" = <<-EOT
                    devops:ssh-rsa AAAAB3NzaC1yc2EAAAAD***xAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            }
          + name        = "master-{instance.index}"
          + platform_id = "standard-v2"

          + boot_disk {
              + device_name = (known after apply)
              + mode        = "READ_WRITE"

              + initialize_params {
                  + image_id    = "fd8vmcue7aajpmeo39kk"
                  + size        = 10
                  + snapshot_id = (known after apply)
                  + type        = "network-ssd"
                }
            }

          + metadata_options (known after apply)

          + network_interface {
              + ip_address   = (known after apply)
              + ipv4         = true
              + ipv6         = (known after apply)
              + ipv6_address = (known after apply)
              + nat          = true
              + network_id   = "enpsj820vglkjv4mng70"
              + subnet_ids   = [
                  + "e2l2pe3a9tbhubgasu7g",
                  + "e9bvamfk1tg5onjejbuu",
                  + "fl8j7vd5kl32pi4phvmf",
                ]
            }

          + network_settings {
              + type = "STANDARD"
            }

          + resources {
              + core_fraction = 20
              + cores         = 2
              + memory        = 2
            }

          + scheduling_policy {
              + preemptible = true
            }
        }

      + scale_policy {
          + fixed_scale {
              + size = 3
            }
        }
    }

  # yandex_compute_instance_group.k8s-workers will be created
  + resource "yandex_compute_instance_group" "k8s-workers" {
      + created_at          = (known after apply)
      + deletion_protection = false
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + instances           = (known after apply)
      + name                = "k8s-workers"
      + service_account_id  = "ajer93efebn650j9q2ta"
      + status              = (known after apply)

      + allocation_policy {
          + zones = [
              + "ru-central1-a",
              + "ru-central1-b",
              + "ru-central1-d",
            ]
        }

      + deploy_policy {
          + max_creating     = 3
          + max_deleting     = 3
          + max_expansion    = 3
          + max_unavailable  = 3
          + startup_duration = 0
          + strategy         = (known after apply)
        }

      + instance_template {
          + labels      = (known after apply)
          + metadata    = {
              + "ssh-keys" = <<-EOT
                    ubuntu:ssh-rsa AAAAB3NzaC1yc2EA***Y//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            }
          + name        = "worker-{instance.index}"
          + platform_id = "standard-v2"

          + boot_disk {
              + device_name = (known after apply)
              + mode        = "READ_WRITE"

              + initialize_params {
                  + image_id    = "fd8vmcue7aajpmeo39kk"
                  + size        = 10
                  + snapshot_id = (known after apply)
                  + type        = "network-hdd"
                }
            }

          + metadata_options (known after apply)

          + network_interface {
              + ip_address   = (known after apply)
              + ipv4         = true
              + ipv6         = (known after apply)
              + ipv6_address = (known after apply)
              + nat          = true
              + network_id   = "enpsj820vglkjv4mng70"
              + subnet_ids   = [
                  + "e2l2pe3a9tbhubgasu7g",
                  + "e9bvamfk1tg5onjejbuu",
                  + "fl8j7vd5kl32pi4phvmf",
                ]
            }

          + network_settings {
              + type = "STANDARD"
            }

          + resources {
              + core_fraction = 20
              + cores         = 2
              + memory        = 2
            }

          + scheduling_policy {
              + preemptible = true
            }
        }

      + scale_policy {
          + fixed_scale {
              + size = 3
            }
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
yandex_compute_instance_group.k8s-masters: Creating...
yandex_compute_instance_group.k8s-masters: Still creating... [00m10s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [00m20s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [00m30s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [00m40s elapsed]
yandex_compute_instance_group.k8s-masters: Creation complete after 45s [id=cl1ruup7856jrr1rvg3b]
yandex_compute_instance_group.k8s-workers: Creating...
yandex_compute_instance_group.k8s-workers: Still creating... [00m10s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m20s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m30s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m40s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m50s elapsed]
yandex_compute_instance_group.k8s-workers: Creation complete after 54s [id=cl1lohoq8msc7vvc7ug3]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```
</details>

<img width="1975" height="639" alt="image" src="https://github.com/user-attachments/assets/a55b32d4-c17f-4aea-a6ad-5fe15536072a" />

<img width="2113" height="1173" alt="image" src="https://github.com/user-attachments/assets/a48b6369-cdb5-401e-be02-69d35170d707" />

<img width="2121" height="726" alt="image" src="https://github.com/user-attachments/assets/44fc69ce-6309-4759-85de-544d4a59cb0a" />

Проверяем `terraform destroy` и `terraform apply`

Результат:

```shell
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform destroy
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_compute_instance_group.k8s-masters: Refreshing state... [id=cl1ruup7856jrr1rvg3b]
yandex_compute_instance_group.k8s-workers: Refreshing state... [id=cl1lohoq8msc7vvc7ug3]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_compute_instance_group.k8s-masters will be destroyed
  - resource "yandex_compute_instance_group" "k8s-masters" {
      - created_at          = "2025-10-12T19:06:15Z" -> null
      - deletion_protection = false -> null
      - folder_id           = "b1g2pak2mr3h8bt5nfam" -> null
      - id                  = "cl1ruup7856jrr1rvg3b" -> null
      - instances           = [
          - {
              - fqdn              = "master-1.ru-central1.internal"
              - instance_id       = "fhm75o2th2v5relabk4j"
              - name              = "master-1"
              - network_interface = [
                  - {
                      - index          = 0
                      - ip_address     = "10.0.1.22"
                      - ipv4           = true
                      - ipv6           = false
                      - mac_address    = "d0:0d:72:e0:5d:88"
                      - nat            = true
                      - nat_ip_address = "89.169.145.24"
                      - nat_ip_version = "IPV4"
                      - subnet_id      = "e9bvamfk1tg5onjejbuu"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - status            = "RUNNING_ACTUAL"
              - status_changed_at = "2025-10-12T19:06:49Z"
              - zone_id           = "ru-central1-a"
                # (2 unchanged attributes hidden)
            },
          - {
              - fqdn              = "master-2.ru-central1.internal"
              - instance_id       = "epdnk23hadcs1ff9oata"
              - name              = "master-2"
              - network_interface = [
                  - {
                      - index          = 0
                      - ip_address     = "10.0.2.13"
                      - ipv4           = true
                      - ipv6           = false
                      - mac_address    = "d0:0d:17:a0:87:15"
                      - nat            = true
                      - nat_ip_address = "84.201.166.120"
                      - nat_ip_version = "IPV4"
                      - subnet_id      = "e2l2pe3a9tbhubgasu7g"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - status            = "RUNNING_ACTUAL"
              - status_changed_at = "2025-10-12T19:06:54Z"
              - zone_id           = "ru-central1-b"
                # (2 unchanged attributes hidden)
            },
          - {
              - fqdn              = "master-3.ru-central1.internal"
              - instance_id       = "fv4i78mntl22ejmsu8o7"
              - name              = "master-3"
              - network_interface = [
                  - {
                      - index          = 0
                      - ip_address     = "10.0.3.4"
                      - ipv4           = true
                      - ipv6           = false
                      - mac_address    = "d0:0d:12:3a:2d:7e"
                      - nat            = true
                      - nat_ip_address = "158.160.195.131"
                      - nat_ip_version = "IPV4"
                      - subnet_id      = "fl8j7vd5kl32pi4phvmf"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - status            = "RUNNING_ACTUAL"
              - status_changed_at = "2025-10-12T19:06:59Z"
              - zone_id           = "ru-central1-d"
                # (2 unchanged attributes hidden)
            },
        ] -> null
      - labels              = {} -> null
      - name                = "k8s-masters" -> null
      - service_account_id  = "ajer93efebn650j9q2ta" -> null
      - status              = "ACTIVE" -> null
      - variables           = {} -> null
        # (1 unchanged attribute hidden)

      - allocation_policy {
          - zones = [
              - "ru-central1-a",
              - "ru-central1-b",
              - "ru-central1-d",
            ] -> null
        }

      - deploy_policy {
          - max_creating     = 3 -> null
          - max_deleting     = 3 -> null
          - max_expansion    = 3 -> null
          - max_unavailable  = 3 -> null
          - startup_duration = 0 -> null
          - strategy         = "proactive" -> null
        }

      - instance_template {
          - labels             = {} -> null
          - metadata           = {
              - "ssh-keys" = <<-EOT
                    devops:ssh-rsa AAAAB3NzaC***5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            } -> null
          - name               = "master-{instance.index}" -> null
          - platform_id        = "standard-v2" -> null
            # (3 unchanged attributes hidden)

          - boot_disk {
              - mode        = "READ_WRITE" -> null
                name        = null
                # (2 unchanged attributes hidden)

              - initialize_params {
                  - image_id    = "fd8vmcue7aajpmeo39kk" -> null
                  - size        = 10 -> null
                  - type        = "network-ssd" -> null
                    # (2 unchanged attributes hidden)
                }
            }

          - metadata_options {
              - aws_v1_http_endpoint = 0 -> null
              - aws_v1_http_token    = 0 -> null
              - gce_http_endpoint    = 0 -> null
              - gce_http_token       = 0 -> null
            }

          - network_interface {
              - ipv4               = true -> null
              - ipv6               = false -> null
              - nat                = true -> null
              - network_id         = "enpsj820vglkjv4mng70" -> null
              - security_group_ids = [] -> null
              - subnet_ids         = [
                  - "e2l2pe3a9tbhubgasu7g",
                  - "e9bvamfk1tg5onjejbuu",
                  - "fl8j7vd5kl32pi4phvmf",
                ] -> null
                # (3 unchanged attributes hidden)
            }

          - network_settings {
              - type = "STANDARD" -> null
            }

          - resources {
              - core_fraction = 20 -> null
              - cores         = 2 -> null
              - gpus          = 0 -> null
              - memory        = 2 -> null
            }

          - scheduling_policy {
              - preemptible = true -> null
            }
        }

      - scale_policy {
          - fixed_scale {
              - size = 3 -> null
            }
        }
    }

  # yandex_compute_instance_group.k8s-workers will be destroyed
  - resource "yandex_compute_instance_group" "k8s-workers" {
      - created_at          = "2025-10-12T19:07:01Z" -> null
      - deletion_protection = false -> null
      - folder_id           = "b1g2pak2mr3h8bt5nfam" -> null
      - id                  = "cl1lohoq8msc7vvc7ug3" -> null
      - instances           = [
          - {
              - fqdn              = "worker-1.ru-central1.internal"
              - instance_id       = "fhmsekiklqtq8lc1hv4g"
              - name              = "worker-1"
              - network_interface = [
                  - {
                      - index          = 0
                      - ip_address     = "10.0.1.10"
                      - ipv4           = true
                      - ipv6           = false
                      - mac_address    = "d0:0d:1c:75:25:4a"
                      - nat            = true
                      - nat_ip_address = "51.250.65.164"
                      - nat_ip_version = "IPV4"
                      - subnet_id      = "e9bvamfk1tg5onjejbuu"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - status            = "RUNNING_ACTUAL"
              - status_changed_at = "2025-10-12T19:07:34Z"
              - zone_id           = "ru-central1-a"
                # (2 unchanged attributes hidden)
            },
          - {
              - fqdn              = "worker-2.ru-central1.internal"
              - instance_id       = "epdiub6ga33f3bm7ao15"
              - name              = "worker-2"
              - network_interface = [
                  - {
                      - index          = 0
                      - ip_address     = "10.0.2.4"
                      - ipv4           = true
                      - ipv6           = false
                      - mac_address    = "d0:0d:12:f2:cd:05"
                      - nat            = true
                      - nat_ip_address = "51.250.20.18"
                      - nat_ip_version = "IPV4"
                      - subnet_id      = "e2l2pe3a9tbhubgasu7g"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - status            = "RUNNING_ACTUAL"
              - status_changed_at = "2025-10-12T19:07:53Z"
              - zone_id           = "ru-central1-b"
                # (2 unchanged attributes hidden)
            },
          - {
              - fqdn              = "worker-3.ru-central1.internal"
              - instance_id       = "fv4gvu184i6p5ekth0ip"
              - name              = "worker-3"
              - network_interface = [
                  - {
                      - index          = 0
                      - ip_address     = "10.0.3.12"
                      - ipv4           = true
                      - ipv6           = false
                      - mac_address    = "d0:0d:10:ff:82:82"
                      - nat            = true
                      - nat_ip_address = "158.160.195.94"
                      - nat_ip_version = "IPV4"
                      - subnet_id      = "fl8j7vd5kl32pi4phvmf"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - status            = "RUNNING_ACTUAL"
              - status_changed_at = "2025-10-12T19:07:42Z"
              - zone_id           = "ru-central1-d"
                # (2 unchanged attributes hidden)
            },
        ] -> null
      - labels              = {} -> null
      - name                = "k8s-workers" -> null
      - service_account_id  = "ajer93efebn650j9q2ta" -> null
      - status              = "ACTIVE" -> null
      - variables           = {} -> null
        # (1 unchanged attribute hidden)

      - allocation_policy {
          - zones = [
              - "ru-central1-a",
              - "ru-central1-b",
              - "ru-central1-d",
            ] -> null
        }

      - deploy_policy {
          - max_creating     = 3 -> null
          - max_deleting     = 3 -> null
          - max_expansion    = 3 -> null
          - max_unavailable  = 3 -> null
          - startup_duration = 0 -> null
          - strategy         = "proactive" -> null
        }

      - instance_template {
          - labels             = {} -> null
          - metadata           = {
              - "ssh-keys" = <<-EOT
                    ubuntu:ssh-rsa AAAAB3NzaC1y***rhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            } -> null
          - name               = "worker-{instance.index}" -> null
          - platform_id        = "standard-v2" -> null
            # (3 unchanged attributes hidden)

          - boot_disk {
              - mode        = "READ_WRITE" -> null
                name        = null
                # (2 unchanged attributes hidden)

              - initialize_params {
                  - image_id    = "fd8vmcue7aajpmeo39kk" -> null
                  - size        = 10 -> null
                  - type        = "network-hdd" -> null
                    # (2 unchanged attributes hidden)
                }
            }

          - metadata_options {
              - aws_v1_http_endpoint = 0 -> null
              - aws_v1_http_token    = 0 -> null
              - gce_http_endpoint    = 0 -> null
              - gce_http_token       = 0 -> null
            }

          - network_interface {
              - ipv4               = true -> null
              - ipv6               = false -> null
              - nat                = true -> null
              - network_id         = "enpsj820vglkjv4mng70" -> null
              - security_group_ids = [] -> null
              - subnet_ids         = [
                  - "e2l2pe3a9tbhubgasu7g",
                  - "e9bvamfk1tg5onjejbuu",
                  - "fl8j7vd5kl32pi4phvmf",
                ] -> null
                # (3 unchanged attributes hidden)
            }

          - network_settings {
              - type = "STANDARD" -> null
            }

          - resources {
              - core_fraction = 20 -> null
              - cores         = 2 -> null
              - gpus          = 0 -> null
              - memory        = 2 -> null
            }

          - scheduling_policy {
              - preemptible = true -> null
            }
        }

      - scale_policy {
          - fixed_scale {
              - size = 3 -> null
            }
        }
    }

  # yandex_vpc_network.net will be destroyed
  - resource "yandex_vpc_network" "net" {
      - created_at                = "2025-10-12T18:49:03Z" -> null
      - default_security_group_id = "enp0crnald9apaq6navg" -> null
      - folder_id                 = "b1g2pak2mr3h8bt5nfam" -> null
      - id                        = "enpsj820vglkjv4mng70" -> null
      - labels                    = {} -> null
      - name                      = "net" -> null
      - subnet_ids                = [
          - "e2l2pe3a9tbhubgasu7g",
          - "e9bvamfk1tg5onjejbuu",
          - "fl8j7vd5kl32pi4phvmf",
        ] -> null
        # (1 unchanged attribute hidden)
    }

  # yandex_vpc_subnet.central1-a will be destroyed
  - resource "yandex_vpc_subnet" "central1-a" {
      - created_at     = "2025-10-12T18:49:06Z" -> null
      - folder_id      = "b1g2pak2mr3h8bt5nfam" -> null
      - id             = "e9bvamfk1tg5onjejbuu" -> null
      - labels         = {} -> null
      - name           = "central1-a" -> null
      - network_id     = "enpsj820vglkjv4mng70" -> null
      - v4_cidr_blocks = [
          - "10.0.1.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-a" -> null
        # (2 unchanged attributes hidden)
    }

  # yandex_vpc_subnet.central1-b will be destroyed
  - resource "yandex_vpc_subnet" "central1-b" {
      - created_at     = "2025-10-12T18:49:07Z" -> null
      - folder_id      = "b1g2pak2mr3h8bt5nfam" -> null
      - id             = "e2l2pe3a9tbhubgasu7g" -> null
      - labels         = {} -> null
      - name           = "central1-b" -> null
      - network_id     = "enpsj820vglkjv4mng70" -> null
      - v4_cidr_blocks = [
          - "10.0.2.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-b" -> null
        # (2 unchanged attributes hidden)
    }

  # yandex_vpc_subnet.central1-d will be destroyed
  - resource "yandex_vpc_subnet" "central1-d" {
      - created_at     = "2025-10-12T18:49:06Z" -> null
      - folder_id      = "b1g2pak2mr3h8bt5nfam" -> null
      - id             = "fl8j7vd5kl32pi4phvmf" -> null
      - labels         = {} -> null
      - name           = "central1-d" -> null
      - network_id     = "enpsj820vglkjv4mng70" -> null
      - v4_cidr_blocks = [
          - "10.0.3.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-d" -> null
        # (2 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 6 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

yandex_compute_instance_group.k8s-workers: Destroying... [id=cl1lohoq8msc7vvc7ug3]
yandex_compute_instance_group.k8s-workers: Still destroying... [id=cl1lohoq8msc7vvc7ug3, 00m10s elapsed]
yandex_compute_instance_group.k8s-workers: Still destroying... [id=cl1lohoq8msc7vvc7ug3, 00m20s elapsed]
yandex_compute_instance_group.k8s-workers: Still destroying... [id=cl1lohoq8msc7vvc7ug3, 00m30s elapsed]
yandex_compute_instance_group.k8s-workers: Still destroying... [id=cl1lohoq8msc7vvc7ug3, 00m40s elapsed]
yandex_compute_instance_group.k8s-workers: Still destroying... [id=cl1lohoq8msc7vvc7ug3, 00m50s elapsed]
yandex_compute_instance_group.k8s-workers: Destruction complete after 51s
yandex_compute_instance_group.k8s-masters: Destroying... [id=cl1ruup7856jrr1rvg3b]
yandex_compute_instance_group.k8s-masters: Still destroying... [id=cl1ruup7856jrr1rvg3b, 00m10s elapsed]
yandex_compute_instance_group.k8s-masters: Still destroying... [id=cl1ruup7856jrr1rvg3b, 00m20s elapsed]
yandex_compute_instance_group.k8s-masters: Still destroying... [id=cl1ruup7856jrr1rvg3b, 00m30s elapsed]
yandex_compute_instance_group.k8s-masters: Still destroying... [id=cl1ruup7856jrr1rvg3b, 00m40s elapsed]
yandex_compute_instance_group.k8s-masters: Still destroying... [id=cl1ruup7856jrr1rvg3b, 00m50s elapsed]
yandex_compute_instance_group.k8s-masters: Destruction complete after 51s
yandex_vpc_subnet.central1-b: Destroying... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_subnet.central1-d: Destroying... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_subnet.central1-a: Destroying... [id=e9bvamfk1tg5onjejbuu]
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance_group.k8s-masters will be created
  + resource "yandex_compute_instance_group" "k8s-masters" {
      + created_at          = (known after apply)
      + deletion_protection = false
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + instances           = (known after apply)
      + name                = "k8s-masters"
      + service_account_id  = "ajer93efebn650j9q2ta"
      + status              = (known after apply)

      + allocation_policy {
          + zones = [
              + "ru-central1-a",
              + "ru-central1-b",
              + "ru-central1-d",
            ]
        }

      + deploy_policy {
          + max_creating     = 3
          + max_deleting     = 3
          + max_expansion    = 3
          + max_unavailable  = 3
          + startup_duration = 0
          + strategy         = (known after apply)
        }

      + instance_template {
          + labels      = (known after apply)
          + metadata    = {
              + "ssh-keys" = <<-EOT
                    devops:ssh-rsa AAAAB3Nz***pxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            }
          + name        = "master-{instance.index}"
          + platform_id = "standard-v2"

          + boot_disk {
              + device_name = (known after apply)
              + mode        = "READ_WRITE"

              + initialize_params {
                  + image_id    = "fd8vmcue7aajpmeo39kk"
                  + size        = 10
                  + snapshot_id = (known after apply)
                  + type        = "network-ssd"
                }
            }

          + metadata_options (known after apply)

          + network_interface {
              + ip_address   = (known after apply)
              + ipv4         = true
              + ipv6         = (known after apply)
              + ipv6_address = (known after apply)
              + nat          = true
              + network_id   = "enpsj820vglkjv4mng70"
              + subnet_ids   = [
                  + "e2l2pe3a9tbhubgasu7g",
                  + "e9bvamfk1tg5onjejbuu",
                  + "fl8j7vd5kl32pi4phvmf",
                ]
            }

          + network_settings {
              + type = "STANDARD"
            }

          + resources {
              + core_fraction = 20
              + cores         = 2
              + memory        = 2
            }

          + scheduling_policy {
              + preemptible = true
            }
        }

      + scale_policy {
          + fixed_scale {
              + size = 3
            }
        }
    }

  # yandex_compute_instance_group.k8s-workers will be created
  + resource "yandex_compute_instance_group" "k8s-workers" {
      + created_at          = (known after apply)
      + deletion_protection = false
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + instances           = (known after apply)
      + name                = "k8s-workers"
      + service_account_id  = "ajer93efebn650j9q2ta"
      + status              = (known after apply)

      + allocation_policy {
          + zones = [
              + "ru-central1-a",
              + "ru-central1-b",
              + "ru-central1-d",
            ]
        }

      + deploy_policy {
          + max_creating     = 3
          + max_deleting     = 3
          + max_expansion    = 3
          + max_unavailable  = 3
          + startup_duration = 0
          + strategy         = (known after apply)
        }

      + instance_template {
          + labels      = (known after apply)
          + metadata    = {
              + "ssh-keys" = <<-EOT
                    ubuntu:ssh-rsa AAAAB3Nza***hY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            }
          + name        = "worker-{instance.index}"
          + platform_id = "standard-v2"

          + boot_disk {
              + device_name = (known after apply)
              + mode        = "READ_WRITE"

              + initialize_params {
                  + image_id    = "fd8vmcue7aajpmeo39kk"
                  + size        = 10
                  + snapshot_id = (known after apply)
                  + type        = "network-hdd"
                }
            }

          + metadata_options (known after apply)

          + network_interface {
              + ip_address   = (known after apply)
              + ipv4         = true
              + ipv6         = (known after apply)
              + ipv6_address = (known after apply)
              + nat          = true
              + network_id   = "enpsj820vglkjv4mng70"
              + subnet_ids   = [
                  + "e2l2pe3a9tbhubgasu7g",
                  + "e9bvamfk1tg5onjejbuu",
                  + "fl8j7vd5kl32pi4phvmf",
                ]
            }

          + network_settings {
              + type = "STANDARD"
            }

          + resources {
              + core_fraction = 20
              + cores         = 2
              + memory        = 2
            }

          + scheduling_policy {
              + preemptible = true
            }
        }

      + scale_policy {
          + fixed_scale {
              + size = 3
            }
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_compute_instance_group.k8s-masters: Creating...
yandex_compute_instance_group.k8s-masters: Still creating... [00m10s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [00m20s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [00m30s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [00m40s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [00m50s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [01m00s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [01m10s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [01m20s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [01m30s elapsed]
yandex_compute_instance_group.k8s-masters: Still creating... [01m40s elapsed]
yandex_compute_instance_group.k8s-masters: Creation complete after 1m41s [id=cl147ct0bt3194cd68nh]
yandex_compute_instance_group.k8s-workers: Creating...
yandex_compute_instance_group.k8s-workers: Still creating... [00m10s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m20s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m30s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m40s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [00m50s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [01m00s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [01m10s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [01m20s elapsed]
yandex_compute_instance_group.k8s-workers: Still creating... [01m30s elapsed]
yandex_compute_instance_group.k8s-workers: Creation complete after 1m33s [id=cl1m0pfn221pruhcmoop]
```

### 2. Создание Kubernetes кластера

Для создание k8s-кластера нам потребуются создать по 3-и master и worker ноды размещенные в разных расположениях в соответсвии со схемой.

используем манифесты `./terraform/k8s-masters.tf` и `./terraform/k8s-workers.tf` `./terraform/ansible.tf`. Которые поднимут ВМ и через kubespray развернут кластер.

Установим kubespray, он будет находится в `./ansible/kubespray`

```shell
cd ~/devops-diplom-yandexcloud/ansible
wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.21.0.tar.gz
tar -xvzf v2.21.0.tar.gz
mv kubespray-2.21.0 kubespray
python3 -m venv venv
source venv/bin/activate
pip3 install -r kubespray/requirements.txt
```

или же 

```
sduo apt install ansible-core
```

Процесс установки выглядит так

> При запуске пришлось повозиться с памятью на диске. поэтому данные немного будут разниться с прошлой части. Проблема в создании регионального кластера с 3 мастер-нодами - это занимает очень много времени и превышает таймаут.

<details>
    <summary>main.tf</summary>

```
terraform {
  required_version = ">= 0.13"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89"
    }
  }

  backend "s3" {
    endpoints = { s3 = "https://storage.yandexcloud.net" }
    bucket    = "devops-diplom-yandexcloud-bucket-mrg"
    region    = "ru-central1"
    key       = "terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = "b1gphk6fe2qpbmph96u5"
  folder_id = "b1g2pak2mr3h8bt5nfam"
  zone      = "ru-central1-a"
}

# VPC Network
resource "yandex_vpc_network" "net" {
  name = "devops-diplom-yandexcloud-net"
}

# Subnets in different zones
resource "yandex_vpc_subnet" "central1-a" {
  name           = "devops-diplom-yandexcloud-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "central1-b" {
  name           = "devops-diplom-yandexcloud-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

resource "yandex_vpc_subnet" "central1-d" {
  name           = "devops-diplom-yandexcloud-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Security Group for Kubernetes
resource "yandex_vpc_security_group" "k8s-sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH"
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  ingress {
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "HTTP"
  }

  ingress {
    protocol       = "TCP"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "NodePort services"
  }

  ingress {
    protocol       = "TCP"
    port           = 10250
    v4_cidr_blocks = ["10.0.0.0/8"]
    description    = "Kubelet API"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Outbound traffic"
  }
}

# Managed Kubernetes Cluster with zonal master (simpler and faster)
resource "yandex_kubernetes_cluster" "devops-diplom" {
  name        = "devops-diplom-yandexcloud-k8s"
  description = "Kubernetes cluster for devops-diplom-yandexcloud project"
  network_id  = yandex_vpc_network.net.id
  folder_id   = "b1g2pak2mr3h8bt5nfam"

  master {
    version   = "1.30"
    public_ip = true

    # Zonal master configuration (simpler and faster to create)
    zonal {
      zone      = yandex_vpc_subnet.central1-a.zone
      subnet_id = yandex_vpc_subnet.central1-a.id
    }

    # Security settings
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
  }

  service_account_id      = "ajer93efebn650j9q2ta"
  node_service_account_id = "ajer93efebn650j9q2ta"

  release_channel = "REGULAR"
  network_policy_provider = "CALICO"

  depends_on = [
    yandex_vpc_security_group.k8s-sg
  ]
}

# Single Node Group for both control plane and workers
resource "yandex_kubernetes_node_group" "cluster_nodes" {
  cluster_id = yandex_kubernetes_cluster.devops-diplom.id
  name       = "devops-diplom-yandexcloud-nodes"

  instance_template {
    platform_id = "standard-v2"

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    network_interface {
      nat        = true
      subnet_ids = [
        yandex_vpc_subnet.central1-a.id,
        yandex_vpc_subnet.central1-b.id,
        yandex_vpc_subnet.central1-d.id
      ]
      security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
    }

    scheduling_policy {
      preemptible = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3  # 3 worker nodes distributed across zones
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    location {
      zone = "ru-central1-b"
    }
    location {
      zone = "ru-central1-d"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}

# Outputs to see the cluster information
output "kubernetes_cluster_id" {
  value = yandex_kubernetes_cluster.devops-diplom.id
}

output "kubernetes_cluster_external_endpoint" {
  value = yandex_kubernetes_cluster.devops-diplom.master[0].external_v4_endpoint
}

output "node_group_id" {
  value = yandex_kubernetes_node_group.cluster_nodes.id
}
```
</details>

<details>
    <summary> подробнее terraform apply --auto-approve </summary>

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply --auto-approve
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_security_group.k8s-sg: Refreshing state... [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Refreshing state... [id=catolupegjo8fu6470am]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the last "terraform apply" which may have
affected this plan:

  # yandex_kubernetes_cluster.devops-diplom has changed
  ~ resource "yandex_kubernetes_cluster" "devops-diplom" {
        id                       = "catolupegjo8fu6470am"
        name                     = "devops-diplom-yandexcloud-k8s"
        # (8 unchanged attributes hidden)

      ~ master {
          + external_v4_endpoint   = "https://158.160.204.36"
            # (11 unchanged attributes hidden)

            # (1 unchanged block hidden)
        }
    }


Unless you have made equivalent changes to your configuration, or ignored the relevant attributes using ignore_changes,
the following plan may include actions to undo or respond to these changes.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create
  ~ update in-place
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # yandex_kubernetes_cluster.devops-diplom is tainted, so must be replaced
-/+ resource "yandex_kubernetes_cluster" "devops-diplom" {
      ~ cluster_ipv4_range       = "10.112.0.0/16" -> (known after apply)
      + cluster_ipv6_range       = (known after apply)
      ~ created_at               = "2025-10-13T17:45:27Z" -> (known after apply)
      ~ health                   = "unhealthy" -> (known after apply)
      ~ id                       = "catolupegjo8fu6470am" -> (known after apply)
      ~ labels                   = {} -> (known after apply)
      + log_group_id             = (known after apply)
        name                     = "devops-diplom-yandexcloud-k8s"
      ~ service_ipv4_range       = "10.96.0.0/16" -> (known after apply)
      + service_ipv6_range       = (known after apply)
      ~ status                   = "provisioning" -> (known after apply)
        # (8 unchanged attributes hidden)

      ~ master {
          ~ cluster_ca_certificate = <<-EOT
                -----BEGIN CERTIFICATE-----
                MIIC5zCCAc+gAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
                cm5ldGVzMB4XDTI1MTAxMzE3NDUyOVoXDTM1MTAxMTE3NDUyOVowFTETMBEGA1UE
                ****
                aRuwAxZKZOG54WIfZY1gpq5VfhImxzFUf/F5Cf/RFAthW178rwaJ1oVnrai0fVoX
                EJPfKPj5YMseaMPd9XmwtUrYVCtk3eG+pXvYXQZge9Z5AXrqw+573BvBI66WWfKV
                czOr41EfdrsScsd2/PLBffv5z8wEimg9bfaHLlYSYzB897DuwnVb479/Zwys1UXY
                JmOvqJFSuslqCSu3zVn4DZ/5gJQKwT+crIM5
                -----END CERTIFICATE-----
            EOT -> (known after apply)
          ~ etcd_cluster_size      = 3 -> (known after apply)
          ~ external_v4_address    = "158.160.204.36" -> (known after apply)
          ~ external_v4_endpoint   = "https://158.160.204.36" -> (known after apply)
          + external_v6_endpoint   = (known after apply)
          ~ internal_v4_address    = "10.0.1.10" -> (known after apply)
          ~ internal_v4_endpoint   = "https://10.0.1.10" -> (known after apply)
          ~ version_info           = [
              - {
                  - current_version        = "1.30"
                  - new_revision_available = false
                  - version_deprecated     = false
                    # (1 unchanged attribute hidden)
                },
            ] -> (known after apply)
            # (4 unchanged attributes hidden)

          ~ maintenance_policy (known after apply)
          - maintenance_policy {
              - auto_upgrade = true -> null
            }

          ~ master_location (known after apply)
          - master_location {
              - subnet_id = "e9bvamfk1tg5onjejbuu" -> null
              - zone      = "ru-central1-a" -> null
            }
          - master_location {
              - subnet_id = "e2l2pe3a9tbhubgasu7g" -> null
              - zone      = "ru-central1-b" -> null
            }
          - master_location {
              - subnet_id = "fl8j7vd5kl32pi4phvmf" -> null
              - zone      = "ru-central1-d" -> null
            }

          ~ regional (known after apply)
          - regional {
              - region = "ru-central1" -> null

              - location {
                  - subnet_id = "e9bvamfk1tg5onjejbuu" -> null
                  - zone      = "ru-central1-a" -> null
                }
              - location {
                  - subnet_id = "e2l2pe3a9tbhubgasu7g" -> null
                  - zone      = "ru-central1-b" -> null
                }
              - location {
                  - subnet_id = "fl8j7vd5kl32pi4phvmf" -> null
                  - zone      = "ru-central1-d" -> null
                }
            }

          ~ scale_policy (known after apply)
          - scale_policy {
              - auto_scale {
                  - min_resource_preset_id = "s-c2-m8" -> null
                }
            }

          + zonal {
              + subnet_id = "e9bvamfk1tg5onjejbuu"
              + zone      = "ru-central1-a"
            }
        }
    }

  # yandex_kubernetes_node_group.cluster_nodes will be created
  + resource "yandex_kubernetes_node_group" "cluster_nodes" {
      + cluster_id        = (known after apply)
      + created_at        = (known after apply)
      + description       = (known after apply)
      + id                = (known after apply)
      + instance_group_id = (known after apply)
      + labels            = (known after apply)
      + name              = "devops-diplom-yandexcloud-nodes"
      + status            = (known after apply)
      + version           = (known after apply)
      + version_info      = (known after apply)

      + allocation_policy {
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-a"
            }
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-b"
            }
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-d"
            }
        }

      + deploy_policy (known after apply)

      + instance_template {
          + metadata                  = {
              + "ssh-keys" = <<-EOT
                    ubuntu:ssh-rsa AAAAB3NzaC****Y//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
                EOT
            }
          + nat                       = (known after apply)
          + network_acceleration_type = (known after apply)
          + platform_id               = "standard-v2"

          + boot_disk {
              + size = 32
              + type = "network-hdd"
            }

          + container_network (known after apply)

          + container_runtime (known after apply)

          + gpu_settings (known after apply)

          + network_interface {
              + ipv4               = true
              + ipv6               = (known after apply)
              + nat                = true
              + security_group_ids = [
                  + "enpa3pvoodtt6im48d7l",
                ]
              + subnet_ids         = [
                  + "e2l2pe3a9tbhubgasu7g",
                  + "e9bvamfk1tg5onjejbuu",
                  + "fl8j7vd5kl32pi4phvmf",
                ]
            }

          + resources {
              + core_fraction = (known after apply)
              + cores         = 2
              + gpus          = 0
              + memory        = 2
            }

          + scheduling_policy {
              + preemptible = true
            }
        }

      + maintenance_policy {
          + auto_repair  = true
          + auto_upgrade = true
        }

      + scale_policy {
          + fixed_scale {
              + size = 3
            }
        }
    }

  # yandex_vpc_security_group.k8s-sg will be updated in-place
  ~ resource "yandex_vpc_security_group" "k8s-sg" {
        id          = "enpa3pvoodtt6im48d7l"
        name        = "k8s-security-group"
        # (6 unchanged attributes hidden)

      - ingress {
          - description       = "HTTP" -> null
          - from_port         = -1 -> null
          - id                = "enp47plc1t7d0tcj4db9" -> null
          - labels            = {} -> null
          - port              = 80 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Kubelet API" -> null
          - from_port         = -1 -> null
          - id                = "enp984rh3pffuff9d3jq" -> null
          - labels            = {} -> null
          - port              = 10250 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "10.0.0.0/8",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Kubernetes API" -> null
          - from_port         = -1 -> null
          - id                = "enpmklqm0rvjm6rbcbe4" -> null
          - labels            = {} -> null
          - port              = 443 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Kubernetes API" -> null
          - from_port         = -1 -> null
          - id                = "enpouqe3ocekq992ts2i" -> null
          - labels            = {} -> null
          - port              = 6443 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "NodePort services" -> null
          - from_port         = 30000 -> null
          - id                = "enp1gt8usneni2m6mbdq" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "TCP" -> null
          - to_port           = 32767 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "SSH" -> null
          - from_port         = -1 -> null
          - id                = "enpt95rs2938en321mva" -> null
          - labels            = {} -> null
          - port              = 22 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "etcd peer" -> null
          - from_port         = -1 -> null
          - id                = "enpppsa2ef4v52llctdh" -> null
          - labels            = {} -> null
          - port              = 2380 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "10.0.0.0/8",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "etcd" -> null
          - from_port         = -1 -> null
          - id                = "enp4qt2il9cqbmklbp2i" -> null
          - labels            = {} -> null
          - port              = 2379 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "10.0.0.0/8",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description    = "HTTP"
          + from_port      = -1
          + id             = "enp47plc1t7d0tcj4db9"
          + labels         = {}
          + port           = 80
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "Kubelet API"
          + from_port      = -1
          + id             = "enp984rh3pffuff9d3jq"
          + labels         = {}
          + port           = 10250
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "10.0.0.0/8",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "Kubernetes API"
          + from_port      = -1
          + id             = "enpmklqm0rvjm6rbcbe4"
          + labels         = {}
          + port           = 443
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "Kubernetes API"
          + from_port      = -1
          + id             = "enpouqe3ocekq992ts2i"
          + labels         = {}
          + port           = 6443
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "NodePort services"
          + from_port      = 30000
          + id             = "enp1gt8usneni2m6mbdq"
          + labels         = {}
          + port           = -1
          + protocol       = "TCP"
          + to_port        = 32767
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }
      + ingress {
          + description    = "SSH"
          + from_port      = -1
          + id             = "enpt95rs2938en321mva"
          + labels         = {}
          + port           = 22
          + protocol       = "TCP"
          + to_port        = -1
          + v4_cidr_blocks = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks = []
        }

        # (1 unchanged block hidden)
    }

Plan: 2 to add, 1 to change, 1 to destroy.

Changes to Outputs:
  + kubernetes_cluster_external_endpoint = (known after apply)
  + kubernetes_cluster_id                = (known after apply)
  + node_group_id                        = (known after apply)
yandex_kubernetes_cluster.devops-diplom: Destroying... [id=catolupegjo8fu6470am]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 00m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still destroying... [id=catolupegjo8fu6470am, 01m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Destruction complete after 1m41s
yandex_vpc_security_group.k8s-sg: Modifying... [id=enpa3pvoodtt6im48d7l]
yandex_vpc_security_group.k8s-sg: Modifications complete after 2s [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Creating...
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [00m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [01m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [02m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [03m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [04m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [05m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m30s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m40s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [06m50s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [07m00s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [07m10s elapsed]
yandex_kubernetes_cluster.devops-diplom: Still creating... [07m20s elapsed]
yandex_kubernetes_cluster.devops-diplom: Creation complete after 7m25s [id=cataclo3jasi4sdlfq89]
yandex_kubernetes_node_group.cluster_nodes: Creating...
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m10s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m20s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m30s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m40s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [00m50s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m00s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m10s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m20s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m30s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Still creating... [01m40s elapsed]
yandex_kubernetes_node_group.cluster_nodes: Creation complete after 1m41s [id=cat9nhjl3jsrefkdgpcu]

Apply complete! Resources: 2 added, 1 changed, 1 destroyed.

Outputs:

kubernetes_cluster_external_endpoint = "https://89.169.131.228"
kubernetes_cluster_id = "cataclo3jasi4sdlfq89"
node_group_id = "cat9nhjl3jsrefkdgpcu"
```

</details>

<img width="2473" height="457" alt="image" src="https://github.com/user-attachments/assets/439273a1-bf53-475c-aa01-29e2ccb05c47" />

Таблица конфигурации инфраструктуры Kubernetes

| Компонент | Тип | Название | Конфигурация | Назначение |
|-----------|-----|----------|--------------|------------|
| **Terraform** | Backend | S3 | `devops-diplom-yandexcloud-bucket-mrg` | Хранение состояния Terraform |
| **Provider** | Yandex Cloud | - | Cloud: `b1gphk6fe2qpbmph96u5`<br>Folder: `b1g2pak2mr3h8bt5nfam`<br>Zone: `ru-central1-a` | Подключение к Yandex Cloud |
| **VPC Network** | Сеть | `devops-diplom-yandexcloud-net` | - | Основная сеть кластера |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-a` | Zone: `ru-central1-a`<br>CIDR: `10.0.1.0/24` | Подсеть в зоне A |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-b` | Zone: `ru-central1-b`<br>CIDR: `10.0.2.0/24` | Подсеть в зоне B |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-d` | Zone: `ru-central1-d`<br>CIDR: `10.0.3.0/24` | Подсеть в зоне D |
| **Security Group** | Группа безопасности | `k8s-security-group` | Порты: 22, 80, 443, 6443, 10250, 30000-32767 | Управление доступом к кластеру |
| **Kubernetes Cluster** | Кластер | `devops-diplom-yandexcloud-k8s` | Версия: 1.30<br>Канал: REGULAR<br>Network Policy: CALICO | Управляемый Kubernetes кластер |
| **Master Node** | Control Plane | - | Zone: `ru-central1-a`<br>Public IP: true<br>Security Group: включена | Управляющая нода кластера |
| **Node Group** | Группа нод | `devops-diplom-yandexcloud-nodes` | Размер: 3 ноды<br>Зоны: A, B, D | Worker ноды приложений |
| **Instance Template** | Шаблон ВМ | - | Platform: `standard-v2`<br>CPU: 2 ядра<br>RAM: 2 GB<br>Disk: 32 GB HDD | Конфигурация worker нод |
| **Networking** | Сетевые настройки | - | NAT: включен<br>Subnets: все 3 зоны<br>Security Groups: включены | Сетевая конфигурация нод |
| **Scheduling** | Политика планирования | - | Preemptible: true | Использование прерываемых инстансов |

Детализация Security Group Rules

| Направление | Протокол | Порт | CIDR | Описание |
|-------------|----------|------|------|-----------|
| Ingress | TCP | 22 | 0.0.0.0/0 | SSH доступ |
| Ingress | TCP | 80 | 0.0.0.0/0 | HTTP трафик |
| Ingress | TCP | 443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 6443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 10250 | 10.0.0.0/8 | Kubelet API (внутренний) |
| Ingress | TCP | 30000-32767 | 0.0.0.0/0 | NodePort сервисы |
| Egress | ANY | ALL | 0.0.0.0/0 | Исходящий трафик |

Распределение ресурсов по зонам

| Зона | Подсеть | Ноды | Роль |
|------|---------|------|------|
| ru-central1-a | 10.0.1.0/24 | Master + 1 Worker | Control Plane + Worker |
| ru-central1-b | 10.0.2.0/24 | 1 Worker | Worker |
| ru-central1-d | 10.0.3.0/24 | 1 Worker | Worker |

Спецификации нод

| Параметр | Master | Worker |
|----------|---------|---------|
| **Управление** | Yandex Managed | Terraform Managed |
| **Количество** | 1 (auto-managed) | 3 |
| **CPU** | - | 2 ядра |
| **RAM** | - | 2 GB |
| **Disk** | - | 32 GB HDD |
| **Тип диска** | - | Network HDD |
| **Preemptible** | - | Да |
| **NAT** | Нет | Да |
| **Public IP** | Да | Нет (через NAT) |

Service Accounts

| Назначение | ID |
|------------|----|
| Cluster Service Account | `ajer93efebn650j9q2ta` |
| Node Service Account | `ajer93efebn650j9q2ta` |

Выходные данные (Outputs)

| Output | Описание |
|--------|-----------|
| `kubernetes_cluster_id` | ID кластера Kubernetes |
| `kubernetes_cluster_external_endpoint` | Внешний endpoint API |
| `node_group_id` | ID группы нод |


Вручная обновка конфигурации

```
yc managed-kubernetes cluster get-credentials devops-diplom-yandexcloud-k8s --external --kubeconfig ./new-kubeconfig.yaml
export KUBECONFIG=./new-kubeconfig.yaml
kubectl get nodes
```

Результат 

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get nodes -A -owide
NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl1s0g5l6bcohghv6dje-avib   Ready    <none>   10m   v1.30.1   10.0.1.18     158.160.56.167   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-idys   Ready    <none>   10m   v1.30.1   10.0.2.34     84.201.152.99    Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-ivac   Ready    <none>   10m   v1.30.1   10.0.3.29     158.160.144.41   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -A -owide
NAMESPACE     NAME                                                  READY   STATUS             RESTARTS        AGE   IP             NODE                        NOMINATED NODE   READINESS GATES
kube-system   calico-node-6fnhg                                     0/1     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   calico-node-lz95d                                     1/1     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   calico-node-x4sxw                                     0/1     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   calico-typha-64fd6cf7d8-gtlnv                         1/1     Running            0               17m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   calico-typha-horizontal-autoscaler-5ccf4cb46b-hjzg2   1/1     Running            0               17m   10.112.128.3   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   calico-typha-vertical-autoscaler-7c8d49d7d6-885vv     0/1     CrashLoopBackOff   7 (4m43s ago)   17m   10.112.128.4   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   coredns-5b9d99c8f4-7xxdk                              1/1     Running            0               17m   10.112.129.2   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   coredns-5b9d99c8f4-p8xbm                              1/1     Running            0               15m   10.112.130.3   cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   ip-masq-agent-6mqrv                                   1/1     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   ip-masq-agent-h6s79                                   1/1     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   ip-masq-agent-zsb6h                                   1/1     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   kube-dns-autoscaler-6f89667998-pw5z4                  1/1     Running            0               17m   10.112.129.4   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   kube-proxy-f4p46                                      1/1     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   kube-proxy-kzd47                                      1/1     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   kube-proxy-vllx5                                      1/1     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   metrics-server-6568ff6f44-4vw5d                       1/1     Running            0               17m   10.112.128.5   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   metrics-server-6568ff6f44-rhppf                       1/1     Running            0               17m   10.112.129.5   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   npd-v0.8.0-7xf6n                                      1/1     Running            0               15m   10.112.129.3   cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   npd-v0.8.0-lx5hn                                      1/1     Running            0               15m   10.112.128.2   cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
kube-system   npd-v0.8.0-x88cj                                      1/1     Running            0               15m   10.112.130.2   cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   yc-disk-csi-node-v2-4kfkw                             6/6     Running            0               15m   10.0.1.18      cl1s0g5l6bcohghv6dje-avib   <none>           <none>
kube-system   yc-disk-csi-node-v2-n7qcv                             6/6     Running            0               15m   10.0.2.34      cl1s0g5l6bcohghv6dje-idys   <none>           <none>
kube-system   yc-disk-csi-node-v2-r62c9                             6/6     Running            0               15m   10.0.3.29      cl1s0g5l6bcohghv6dje-ivac   <none>           <none>
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$
```
</details>


### 3. Создание тестового приложения

Проверяем версию докера (который поставил ранее), и авторизиовывемся в dockerhub

```shell
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/testapp$ docker --version
Docker version 28.5.1, build e180ab8
```

<details>
    <summary>подробнее main.tf </summary>

```
terraform {
  required_version = ">= 0.13"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89"
    }
  }

  backend "s3" {
    endpoints = { s3 = "https://storage.yandexcloud.net" }
    bucket    = "devops-diplom-yandexcloud-bucket-mrg"
    region    = "ru-central1"
    key       = "terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = "b1gphk6fe2qpbmph96u5"
  folder_id = "b1g2pak2mr3h8bt5nfam"
  zone      = "ru-central1-a"
}

# VPC Network
resource "yandex_vpc_network" "net" {
  name = "devops-diplom-yandexcloud-net"
}

# Subnets in different zones
resource "yandex_vpc_subnet" "central1-a" {
  name           = "devops-diplom-yandexcloud-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "central1-b" {
  name           = "devops-diplom-yandexcloud-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

resource "yandex_vpc_subnet" "central1-d" {
  name           = "devops-diplom-yandexcloud-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Security Group for Kubernetes
resource "yandex_vpc_security_group" "k8s-sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH"
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  ingress {
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "HTTP"
  }

  ingress {
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Grafana"
  }

  ingress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Prometheus"
  }

  ingress {
    protocol       = "TCP"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "NodePort services"
  }

  ingress {
    protocol       = "TCP"
    port           = 10250
    v4_cidr_blocks = ["10.0.0.0/8"]
    description    = "Kubelet API"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Outbound traffic"
  }
}

# Yandex Container Registry for application images
resource "yandex_container_registry" "app_registry" {
  name      = "devops-diplom-registry"
  folder_id = "b1g2pak2mr3h8bt5nfam"
}

# Managed Kubernetes Cluster with zonal master (simpler and faster)
resource "yandex_kubernetes_cluster" "devops-diplom" {
  name        = "devops-diplom-yandexcloud-k8s"
  description = "Kubernetes cluster for devops-diplom-yandexcloud project"
  network_id  = yandex_vpc_network.net.id
  folder_id   = "b1g2pak2mr3h8bt5nfam"

  master {
    version   = "1.30"
    public_ip = true

    # Zonal master configuration (simpler and faster to create)
    zonal {
      zone      = yandex_vpc_subnet.central1-a.zone
      subnet_id = yandex_vpc_subnet.central1-a.id
    }

    # Security settings
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
  }

  service_account_id      = "ajer93efebn650j9q2ta"
  node_service_account_id = "ajer93efebn650j9q2ta"

  release_channel = "REGULAR"
  network_policy_provider = "CALICO"

  depends_on = [
    yandex_vpc_security_group.k8s-sg
  ]
}

# Single Node Group for both control plane and workers
resource "yandex_kubernetes_node_group" "cluster_nodes" {
  cluster_id = yandex_kubernetes_cluster.devops-diplom.id
  name       = "devops-diplom-yandexcloud-nodes"

  instance_template {
    platform_id = "standard-v2"

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    network_interface {
      nat        = true
      subnet_ids = [
        yandex_vpc_subnet.central1-a.id,
        yandex_vpc_subnet.central1-b.id,
        yandex_vpc_subnet.central1-d.id
      ]
      security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
    }

    scheduling_policy {
      preemptible = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3  # 3 worker nodes distributed across zones
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    location {
      zone = "ru-central1-b"
    }
    location {
      zone = "ru-central1-d"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }

  depends_on = [
    yandex_kubernetes_cluster.devops-diplom
  ]
}

# Outputs to see the cluster information
output "kubernetes_cluster_id" {
  value = yandex_kubernetes_cluster.devops-diplom.id
}

output "kubernetes_cluster_external_endpoint" {
  value = yandex_kubernetes_cluster.devops-diplom.master[0].external_v4_endpoint
}

output "node_group_id" {
  value = yandex_kubernetes_node_group.cluster_nodes.id
}

output "container_registry_id" {
  value = yandex_container_registry.app_registry.id
}

output "container_registry_url" {
  value = "cr.yandex/${yandex_container_registry.app_registry.id}"
}
```

</details>

Таблица конфигурации инфраструктуры Kubernetes

| Компонент | Тип | Название | Конфигурация | Назначение |
|-----------|-----|----------|--------------|------------|
| **Terraform Backend** | S3 Storage | `devops-diplom-yandexcloud-bucket-mrg` | Region: `ru-central1`<br>Key: `terraform.tfstate` | Хранение состояния Terraform |
| **Provider** | Yandex Cloud | - | Cloud: `b1gphk6fe2qpbmph96u5`<br>Folder: `b1g2pak2mr3h8bt5nfam`<br>Zone: `ru-central1-a` | Подключение к Yandex Cloud |
| **VPC Network** | Сеть | `devops-diplom-yandexcloud-net` | - | Основная сеть кластера |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-a` | Zone: `ru-central1-a`<br>CIDR: `10.0.1.0/24` | Подсеть в зоне A |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-b` | Zone: `ru-central1-b`<br>CIDR: `10.0.2.0/24` | Подсеть в зоне B |
| **Subnet** | Подсеть | `devops-diplom-yandexcloud-central1-d` | Zone: `ru-central1-d`<br>CIDR: `10.0.3.0/24` | Подсеть в зоне D |
| **Security Group** | Группа безопасности | `k8s-security-group` | 9 правил ingress<br>1 правило egress | Управление доступом к кластеру |
| **Container Registry** | Docker Registry | `devops-diplom-registry` | Folder: `b1g2pak2mr3h8bt5nfam` | Хранение Docker образов приложения |
| **Kubernetes Cluster** | Managed K8s | `devops-diplom-yandexcloud-k8s` | Версия: 1.30<br>Канал: REGULAR<br>Network Policy: CALICO | Управляемый Kubernetes кластер |
| **Master Node** | Control Plane | - | Zone: `ru-central1-a`<br>Public IP: true<br>Security Group: включена | Управляющая нода кластера |
| **Node Group** | Группа нод | `devops-diplom-yandexcloud-nodes` | Размер: 3 ноды<br>Зоны: A, B, D | Worker ноды приложений |
| **Instance Template** | Шаблон ВМ | - | Platform: `standard-v2`<br>CPU: 2 ядра<br>RAM: 2 GB<br>Disk: 32 GB HDD | Конфигурация worker нод |

Детализация Security Group Rules

| Направление | Протокол | Порт | CIDR | Описание |
|-------------|----------|------|------|-----------|
| Ingress | TCP | 22 | 0.0.0.0/0 | SSH доступ |
| Ingress | TCP | 80 | 0.0.0.0/0 | HTTP трафик |
| Ingress | TCP | 443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 6443 | 0.0.0.0/0 | Kubernetes API |
| Ingress | TCP | 3000 | 0.0.0.0/0 | Grafana |
| Ingress | TCP | 9090 | 0.0.0.0/0 | Prometheus |
| Ingress | TCP | 10250 | 10.0.0.0/8 | Kubelet API (внутренний) |
| Ingress | TCP | 30000-32767 | 0.0.0.0/0 | NodePort сервисы |
| Egress | ANY | ALL | 0.0.0.0/0 | Исходящий трафик |

Распределение ресурсов по зонам

| Зона | Подсеть | Ноды | Роль |
|------|---------|------|------|
| ru-central1-a | 10.0.1.0/24 | Master + 1 Worker | Control Plane + Worker |
| ru-central1-b | 10.0.2.0/24 | 1 Worker | Worker |
| ru-central1-d | 10.0.3.0/24 | 1 Worker | Worker |

Спецификации нод

| Параметр | Master | Worker |
|----------|---------|---------|
| **Управление** | Yandex Managed | Terraform Managed |
| **Количество** | 1 (auto-managed) | 3 |
| **CPU** | - | 2 ядра |
| **RAM** | - | 2 GB |
| **Disk** | - | 32 GB HDD |
| **Тип диска** | - | Network HDD |
| **Preemptible** | - | Да |
| **NAT** | Нет | Да |
| **Public IP** | Да | Нет (через NAT) |

Service Accounts

| Назначение | ID | Имя |
|------------|----|-----|
| Cluster Service Account | `ajer93efebn650j9q2ta` | `devops-diplom-yandexcloud-sa` |
| Node Service Account | `ajer93efebn650j9q2ta` | `devops-diplom-yandexcloud-sa` |

Выходные данные (Outputs)

| Output | Описание | Пример значения |
|--------|-----------|-----------------|
| `kubernetes_cluster_id` | ID кластера Kubernetes | `cataclo3jasi4sdlfq89` |
| `kubernetes_cluster_external_endpoint` | Внешний endpoint API | `https://89.169.131.228` |
| `node_group_id` | ID группы нод | `cat9nhjl3jsrefkdgpcu` |
| `container_registry_id` | ID container registry | `crps1p5u048a00f4o97j` |
| `container_registry_url` | URL registry | `cr.yandex/crps1p5u048a00f4o97j` |

Сетевые диапазоны

| Назначение | CIDR диапазон |
|------------|---------------|
| Pod Network | 10.112.0.0/16 |
| Service Network | 10.96.0.0/16 |
| Node Network | 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 |

Текущее состояние развертывания

| Ресурс | Статус | Количество |
|--------|--------|------------|
| Kubernetes Cluster | RUNNING | 1 |
| Worker Nodes | Ready | 3 |
| Container Registry | Active | 1 |
| Test Application Pod | Running | 1 |
| Test Application Service | NodePort | 1 |
| Ingress | Created | 1 |


<details>
    <summary>подробнее terraform apply -auto-approve</summary>

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply -auto-approve
yandex_iam_service_account_static_access_key.cicd_sa_key: Refreshing state... [id=aje32joh3e5ostb0q30r]
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
yandex_iam_service_account.cicd_sa: Refreshing state... [id=aje1kbha8ivn1l7n8dmr]
yandex_container_registry.app_registry: Refreshing state... [id=crps1p5u048a00f4o97j]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_security_group.k8s-sg: Refreshing state... [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Refreshing state... [id=cataclo3jasi4sdlfq89]
yandex_kubernetes_node_group.cluster_nodes: Refreshing state... [id=cat9nhjl3jsrefkdgpcu]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_iam_service_account.cicd_sa will be destroyed
  # (because yandex_iam_service_account.cicd_sa is not in configuration)
  - resource "yandex_iam_service_account" "cicd_sa" {
      - created_at         = "2025-10-13T19:18:50Z" -> null
      - description        = "Service account for CI/CD operations" -> null
      - folder_id          = "b1g2pak2mr3h8bt5nfam" -> null
      - id                 = "aje1kbha8ivn1l7n8dmr" -> null
      - name               = "cicd-service-account" -> null
      - service_account_id = "aje1kbha8ivn1l7n8dmr" -> null
    }

  # yandex_iam_service_account_static_access_key.cicd_sa_key will be destroyed
  # (because yandex_iam_service_account_static_access_key.cicd_sa_key is not in configuration)
  - resource "yandex_iam_service_account_static_access_key" "cicd_sa_key" {
      - access_key         = "YCAJEao0NfX9aW5sr37VMt4EW" -> null
      - created_at         = "2025-10-13T19:18:52Z" -> null
      - description        = "Static access key for CI/CD" -> null
      - id                 = "aje32joh3e5ostb0q30r" -> null
      - secret_key         = (sensitive value) -> null
      - service_account_id = "aje1kbha8ivn1l7n8dmr" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Changes to Outputs:
  - cicd_access_key_id                   = (sensitive value) -> null
  - cicd_secret_key                      = (sensitive value) -> null
  - cicd_service_account_id              = "aje1kbha8ivn1l7n8dmr" -> null
yandex_iam_service_account_static_access_key.cicd_sa_key: Destroying... [id=aje32joh3e5ostb0q30r]
yandex_iam_service_account_static_access_key.cicd_sa_key: Destruction complete after 0s
yandex_iam_service_account.cicd_sa: Destroying... [id=aje1kbha8ivn1l7n8dmr]
yandex_iam_service_account.cicd_sa: Destruction complete after 3s

Apply complete! Resources: 0 added, 0 changed, 2 destroyed.

Outputs:

container_registry_id = "crps1p5u048a00f4o97j"
container_registry_url = "cr.yandex/crps1p5u048a00f4o97j"
kubernetes_cluster_external_endpoint = "https://89.169.131.228"
kubernetes_cluster_id = "cataclo3jasi4sdlfq89"
node_group_id = "cat9nhjl3jsrefkdgpcu"
```
</details>


Создаем права для registry вручную

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc iam service-account list
+----------------------+------------------------------+--------+---------------------+-----------------------+
|          ID          |             NAME             | LABELS |     CREATED AT      | LAST AUTHENTICATED AT |
+----------------------+------------------------------+--------+---------------------+-----------------------+
| ajeaedtelvo4jbaqukek | vm-service-account           |        | 2025-10-12 18:12:49 |                       |
| ajena75o7bbk24o8rqi0 | tf-sa                        |        | 2025-10-12 18:27:23 | 2025-10-13 19:20:00   |
| ajer93efebn650j9q2ta | devops-diplom-yandexcloud-sa |        | 2025-10-12 17:38:26 | 2025-10-13 19:20:00   |
| ajevr3943agpiaa65qau | xcw55wtaa                    |        | 2025-03-24 17:59:54 | 2025-10-13 18:30:00   |
+----------------------+------------------------------+--------+---------------------+-----------------------+
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container registry add-access-binding crps1p5u048a00f4o97j \
  --role container-registry.images.puller \
  --service-account-name devops-diplom-yandexcloud-sa
done (4s)
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container registry add-access-binding crps1p5u048a00f4o97j \
  --role container-registry.images.pusher \
  --service-account-name devops-diplom-yandexcloud-sa
done (4s)
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container registry list-access-bindings crps1p5u048a00f4o97j
+----------------------------------+----------------+----------------------+
|             ROLE ID              |  SUBJECT TYPE  |      SUBJECT ID      |
+----------------------------------+----------------+----------------------+
| container-registry.images.puller | serviceAccount | ajer93efebn650j9q2ta |
| container-registry.images.pusher | serviceAccount | ajer93efebn650j9q2ta |
+----------------------------------+----------------+----------------------+

```

Теперь собираем и опубликуем Docker образ. Создаем файл ```build-and-push.sh``` в папке terraform

<details>
    <summary>подробнее build-and-push.sh</summary>
  
```
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
```
</details>

А теперь запускаем

```
chmod +x build-and-push.sh
./build-and-push.sh
```

Проверяем

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc container image list --registry-name devops-diplom-registry
+----------------------+---------------------+------------------------------+---------------+-----------------+
|          ID          |       CREATED       |             NAME             |     TAGS      | COMPRESSED SIZE |
+----------------------+---------------------+------------------------------+---------------+-----------------+
| crp3kunplon8ue2fur48 | 2025-10-14 17:52:07 | crps1p5u048a00f4o97j/testapp | 1.0.0, latest | 19.5 MB         |
| crpu1gb6ho1u3f1tjm6d | 2025-10-13 19:30:44 | crps1p5u048a00f4o97j/testapp |               | 19.5 MB         |
+----------------------+---------------------+------------------------------+---------------+-----------------+
```

Обновляем Kubernetes манифесты

В файлах в папке k8s/ image на: ```image: cr.yandex/crps1p5u048a00f4o97j/testapp:1.0.0```

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ cat ../k8s/deployment-testapp.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: testapp
  labels:
    app: testapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: testapp
  template:
    metadata:
      labels:
        app: testapp
    spec:
      containers:
        - name: testapp
          image: cr.yandex/devops-diplom-registry/testapp:1.0.1
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "128Mi"
              cpu: "1"
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc managed-kubernetes cluster get-credentials devops-diplom-yandexcloud-k8s --external --force

Context 'yc-devops-diplom-yandexcloud-k8s' was added as default to kubeconfig '/home/user/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/user/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'a21a21b9-2363-4940-b141-c00b6a9bf1dc'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl apply -f ../k8s/
deployment.apps/testapp unchanged
ingress.networking.k8s.io/testapp-ingress unchanged
service/grafana-service unchanged
service/testapp-service unchanged
```

Проверка развертывания

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE                        NOMINATED NODE   READINESS GATES
testapp-86dffd4b4b-c6zlg   1/1     Running   0          32s   10.112.130.5   cl1s0g5l6bcohghv6dje-avib   <none>           <none>
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -o wide
NAME                       READY   STATUS      RESTARTS   AGE   IP             NODE                        NOMINATED NODE   READINESS GATES
testapp-86dffd4b4b-c6zlg   0/1     Completed   0          22h   <none>         cl1s0g5l6bcohghv6dje-avib   <none>           <none>
testapp-86dffd4b4b-d86kg   0/1     Completed   0          70m   <none>         cl1s0g5l6bcohghv6dje-idys   <none>           <none>
testapp-86dffd4b4b-sgfc2   1/1     Running     0          26m   10.112.130.7   cl1s0g5l6bcohghv6dje-avib   <none>           <none>
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get deployments
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
testapp   1/1     1            1           22h
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -k https://89.169.131.228/healthz
okuser@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ nc -zv 89.169.131.228 443
Connection to 89.169.131.228 443 port [tcp/https] succeeded!
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$
```

Настроим доступ 

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ nano ../k8s/ingress-testapp.yaml
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl apply -f ../k8s/ingress-testapp.yaml
ingress.networking.k8s.io/testapp-ingress created
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ cat ../k8s/ingress-testapp.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: testapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: testapp-service
            port:
              number: 80
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get nodes -o wide
NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl1s0g5l6bcohghv6dje-avib   Ready    <none>   23h   v1.30.1   10.0.1.18     89.169.152.21    Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-idys   Ready    <none>   23h   v1.30.1   10.0.2.34     84.201.152.99    Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
cl1s0g5l6bcohghv6dje-ivac   Ready    <none>   23h   v1.30.1   10.0.3.29     158.160.197.70   Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl http://158.160.197.70:30102
<!doctype html>
<html lang="ru">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Дипломный проект - КУЛИКОВА АЛЁНА ВЛАДИМИРОВНА, NETOLOGY-SHVIRTD-17</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"
        integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <style>
        .hero-section {
            background: linear-gradient(135deg, #000000 0%, #333333 100%);
            color: white;
            padding: 80px 0;
        }

        .card {
            border: none;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
        }

        .card:hover {
            transform: translateY(-5px);
        }

        .system-info {
            background-color: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
        }
    </style>
</head>

<body>
    <!-- Hero Section -->
    <section class="hero-section">
        <div class="container">
            <div class="row text-center">
                <div class="col-12">
                    <h1 class="display-4 fw-bold mb-4">Дипломный проект</h1>
                    <p class="lead mb-3">КУЛИКОВА АЛЁНА ВЛАДИМИРОВНА</p>
                    <p class="mb-4">Группа: NETOLOGY-SHVIRTD-17</p>
                    <div class="d-flex justify-content-center gap-3 flex-wrap">
                        <span class="badge bg-light text-dark">Версия: v1.0.0</span>
                        <span class="badge bg-success">Статус: Production</span>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="py-5">
        <div class="container">
            <div class="row g-4">
                <div class="col-md-4">
                    <div class="card h-100 text-center p-4">
                        <h5>Kubernetes</h5>
                        <p class="text-muted">Развертывание и оркестрация контейнеров в облачной среде</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card h-100 text-center p-4">
                        <h5>CI/CD</h5>
                        <p class="text-muted">Автоматизация процессов сборки, тестирования и развертывания</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card h-100 text-center p-4">
                        <h5>Infrastructure</h5>
                        <p class="text-muted">Управление инфраструктурой как код с использованием Terraform</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- System Information -->
    <section class="py-5 bg-light">
        <div class="container">
            <div class="row justify-content-center">
                <div class="col-lg-8">
                    <div class="system-info">
                        <h4 class="text-center mb-4">Информация о системе</h4>
                        <div class="row text-center">
                            <div class="col-md-6 mb-3">
                                <strong>Текущее время:</strong>
                                <div id="current-time" class="text-primary fw-bold">--:--:--</div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <strong>Время работы:</strong>
                                <div id="page-uptime" class="text-success fw-bold">00:00:00</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-dark text-white py-4">
        <div class="container">
            <div class="row text-center">
                <div class="col-12">
                    <p class="mb-0">&copy; 2025 КУЛИКОВА А.В. | NETOLOGY-SHVIRTD-17</p>
                    <p class="mb-0">Дипломный проект по DevOps инженерии</p>
                </div>
            </div>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz"
        crossorigin="anonymous"></script>

    <script>
        // Update current time
        function updateTime() {
            const now = new Date();
            document.getElementById('current-time').textContent =
                now.toLocaleTimeString('ru-RU');
        }

        // Update page uptime
        function updateUptime() {
            const startTime = Date.now();
            setInterval(() => {
                const uptime = Date.now() - startTime;
                const hours = Math.floor(uptime / 3600000);
                const minutes = Math.floor((uptime % 3600000) / 60000);
                const seconds = Math.floor((uptime % 60000) / 1000);
                document.getElementById('page-uptime').textContent =
                    `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
            }, 1000);
        }

        // Initialize functions when page loads
        document.addEventListener('DOMContentLoaded', function() {
            updateTime();
            setInterval(updateTime, 1000);
            updateUptime();
        });
    </script>
</body>

</html>
```

<img width="2085" height="1281" alt="image" src="https://github.com/user-attachments/assets/ffd65c70-9bc2-4aa2-a02c-7e7b70fede33" />

### 4. Подготовка cистемы мониторинга и деплой приложения

Развернем его в кластере продублируем код в `./terraform/monitoring.tf` используя helm и поднимим сервис  `./k8s/service-grafana.yaml`

Подготовим network_load_balancer для доступа к grafana и testapp `./terraform/nlb.tf`

настроим развертывание в k8s тестового приложения `./terraform/app.tf`

Применяем конфигурацию
```
terraform init
terraform plan
terraform apply -auto-approve
```

<details>
    <summary>подробнее terraform apply -auto-approve</summary>
  
```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ terraform apply -auto-approve
data.yandex_client_config.client: Reading...
yandex_container_registry.app_registry: Refreshing state... [id=crps1p5u048a00f4o97j]
yandex_vpc_network.net: Refreshing state... [id=enpsj820vglkjv4mng70]
data.yandex_client_config.client: Read complete after 0s [id=3771214742]
yandex_vpc_subnet.central1-b: Refreshing state... [id=e2l2pe3a9tbhubgasu7g]
yandex_vpc_subnet.central1-a: Refreshing state... [id=e9bvamfk1tg5onjejbuu]
yandex_vpc_subnet.central1-d: Refreshing state... [id=fl8j7vd5kl32pi4phvmf]
yandex_vpc_security_group.k8s-sg: Refreshing state... [id=enpa3pvoodtt6im48d7l]
yandex_kubernetes_cluster.devops-diplom: Refreshing state... [id=cataclo3jasi4sdlfq89]
yandex_kubernetes_node_group.cluster_nodes: Refreshing state... [id=cat9nhjl3jsrefkdgpcu]
helm_release.kube_prometheus_stack: Refreshing state... [id=kube-prometheus-stack]
kubernetes_namespace.app_namespace: Refreshing state... [id=app]
yandex_lb_target_group.k8s_nodes: Refreshing state... [id=enp1308h4k6apj3fpd0v]
kubernetes_deployment.testapp: Refreshing state... [id=app/testapp]
kubernetes_service.testapp: Refreshing state... [id=app/testapp-service]
kubernetes_ingress_v1.testapp_ingress: Refreshing state... [id=app/testapp-ingress]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_lb_network_load_balancer.k8s_services will be created
  + resource "yandex_lb_network_load_balancer" "k8s_services" {
      + allow_zonal_shift   = (known after apply)
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "k8s-services-load-balancer"
      + region_id           = (known after apply)
      + type                = "external"

      + attached_target_group {
          + target_group_id = "enp1308h4k6apj3fpd0v"

          + healthcheck {
              + healthy_threshold   = 2
              + interval            = 2
              + name                = "app-healthcheck"
              + timeout             = 1
              + unhealthy_threshold = 2

              + http_options {
                  + path = "/healthz"
                  + port = 30180
                }
            }
        }

      + listener {
          + name        = "app-listener"
          + port        = 80
          + protocol    = (known after apply)
          + target_port = (known after apply)

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
      + listener {
          + name        = "grafana-listener"
          + port        = 3000
          + protocol    = (known after apply)
          + target_port = (known after apply)

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
yandex_lb_network_load_balancer.k8s_services: Creating...
yandex_lb_network_load_balancer.k8s_services: Creation complete after 4s [id=enpf3g2ikr8hup8458qu]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

container_registry_id = "crps1p5u048a00f4o97j"
container_registry_url = "cr.yandex/crps1p5u048a00f4o97j"
kubernetes_cluster_external_endpoint = "https://89.169.131.228"
kubernetes_cluster_id = "cataclo3jasi4sdlfq89"
node_group_id = "cat9nhjl3jsrefkdgpcu"
```
</details>

Применяем сервис Grafana вручную после применения Terraform:

```
kubectl delete pod -n monitoring kube-prometheus-stack-grafana-5c878c597-lcm99
pod "kube-prometheus-stack-grafana-5c878c597-lcm99" deleted from monitoring namespace
yc managed-kubernetes cluster get-credentials devops-diplom-yandexcloud-k8s --external --force
kubectl apply -f ../k8s/service-grafana.yaml
```

Проверяем развертывание

```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get pods -A
NAMESPACE     NAME                                                        READY   STATUS                   RESTARTS         AGE
app           testapp-699d4b754d-6nj4x                                    1/1     Running                  0                10m
app           testapp-699d4b754d-bzqnp                                    1/1     Running                  0                10m
default       testapp-86dffd4b4b-c6zlg                                    0/1     Completed                0                23h
default       testapp-86dffd4b4b-d86kg                                    0/1     Completed                0                122m
default       testapp-8f5bf7f99-jqzjn                                     1/1     Running                  0                40m
kube-system   calico-node-c44jj                                           0/1     Running                  0                64m
kube-system   calico-node-lrkwp                                           1/1     Running                  0                78m
kube-system   calico-node-tvscd                                           0/1     Running                  0                122m
kube-system   calico-typha-64fd6cf7d8-59c5l                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-5rgfl                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-5xtrn                               0/1     NodePorts                0                78m
kube-system   calico-typha-64fd6cf7d8-65p4z                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-6wwr7                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-972bs                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-btwmt                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-c6w4k                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-drtc2                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-f9ntr                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-gc2vl                               1/1     Running                  0                78m
kube-system   calico-typha-64fd6cf7d8-gr626                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-gtlnv                               0/1     Error                    0                24h
kube-system   calico-typha-64fd6cf7d8-j5vmw                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-jx4ws                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-jzbbn                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-kxsbw                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-q96wd                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-qf6dd                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-qhhsh                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-qjr6c                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-sqvkr                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-x52bs                               0/1     ContainerStatusUnknown   0                78m
kube-system   calico-typha-64fd6cf7d8-z8zgb                               0/1     NodePorts                0                78m
kube-system   calico-typha-horizontal-autoscaler-5ccf4cb46b-4p7qv         1/1     Running                  0                64m
kube-system   calico-typha-horizontal-autoscaler-5ccf4cb46b-hjzg2         0/1     Error                    0                24h
kube-system   calico-typha-vertical-autoscaler-7c8d49d7d6-885vv           0/1     Error                    277              24h
kube-system   calico-typha-vertical-autoscaler-7c8d49d7d6-lz4v5           0/1     CrashLoopBackOff         17 (2m23s ago)   64m
kube-system   coredns-5b9d99c8f4-67t57                                    1/1     Running                  0                64m
kube-system   coredns-5b9d99c8f4-7xxdk                                    0/1     Completed                0                24h
kube-system   coredns-5b9d99c8f4-bvtvh                                    0/1     Completed                0                122m
kube-system   coredns-5b9d99c8f4-p8xbm                                    0/1     Completed                0                24h
kube-system   coredns-5b9d99c8f4-tv8jw                                    1/1     Running                  0                78m
kube-system   ip-masq-agent-jnv46                                         1/1     Running                  0                122m
kube-system   ip-masq-agent-rcmlh                                         1/1     Running                  0                64m
kube-system   ip-masq-agent-z9crf                                         1/1     Running                  0                78m
kube-system   kube-dns-autoscaler-6f89667998-pw5z4                        0/1     Error                    0                24h
kube-system   kube-dns-autoscaler-6f89667998-x89mg                        1/1     Running                  0                78m
kube-system   kube-proxy-tl9pj                                            1/1     Running                  0                78m
kube-system   kube-proxy-tlnkb                                            1/1     Running                  0                64m
kube-system   kube-proxy-wmfxc                                            1/1     Running                  0                122m
kube-system   metrics-server-6568ff6f44-4vw5d                             0/1     Completed                0                24h
kube-system   metrics-server-6568ff6f44-76c95                             1/1     Running                  0                78m
kube-system   metrics-server-6568ff6f44-g27w9                             1/1     Running                  0                64m
kube-system   metrics-server-6568ff6f44-rhppf                             0/1     Completed                0                24h
kube-system   npd-v0.8.0-6sb4c                                            1/1     Running                  0                78m
kube-system   npd-v0.8.0-jm98k                                            1/1     Running                  0                64m
kube-system   npd-v0.8.0-ljfnk                                            1/1     Running                  1                122m
kube-system   yc-disk-csi-node-v2-4czpj                                   6/6     Running                  1                64m
kube-system   yc-disk-csi-node-v2-6nft9                                   6/6     Running                  1                78m
kube-system   yc-disk-csi-node-v2-xnf58                                   6/6     Running                  0                122m
monitoring    alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running                  0                13m
monitoring    kube-prometheus-stack-grafana-5c878c597-st9b7               3/3     Running                  0                13m
monitoring    kube-prometheus-stack-kube-state-metrics-6fb5dddbdb-h9hbt   1/1     Running                  0                13m
monitoring    kube-prometheus-stack-operator-67f99b8b8b-ps2lc             1/1     Running                  0                13m
monitoring    kube-prometheus-stack-prometheus-node-exporter-lwpd4        1/1     Running                  0                13m
monitoring    kube-prometheus-stack-prometheus-node-exporter-xcnqq        1/1     Running                  0                13m
monitoring    kube-prometheus-stack-prometheus-node-exporter-xl85d        1/1     Running                  0                13m
monitoring    prometheus-kube-prometheus-stack-prometheus-0               2/2     Running                  0                13m
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ kubectl get svc -A
NAMESPACE     NAME                                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
app           testapp-service                                  NodePort    10.96.130.127   <none>        80:30180/TCP                    10m
default       grafana-service                                  NodePort    10.96.168.136   <none>        3000:30101/TCP                  23h
default       kubernetes                                       ClusterIP   10.96.128.1     <none>        443/TCP                         24h
default       testapp-service                                  NodePort    10.96.246.96    <none>        80:30102/TCP                    23h
kube-system   calico-typha                                     ClusterIP   10.96.216.1     <none>        5473/TCP                        24h
kube-system   kube-dns                                         ClusterIP   10.96.128.2     <none>        53/UDP,53/TCP,9153/TCP          24h
kube-system   kube-prometheus-stack-coredns                    ClusterIP   None            <none>        9153/TCP                        14m
kube-system   kube-prometheus-stack-kube-controller-manager    ClusterIP   None            <none>        10257/TCP                       14m
kube-system   kube-prometheus-stack-kube-etcd                  ClusterIP   None            <none>        2381/TCP                        14m
kube-system   kube-prometheus-stack-kube-proxy                 ClusterIP   None            <none>        10249/TCP                       14m
kube-system   kube-prometheus-stack-kube-scheduler             ClusterIP   None            <none>        10259/TCP                       14m
kube-system   kube-prometheus-stack-kubelet                    ClusterIP   None            <none>        10250/TCP,10255/TCP,4194/TCP    14m
kube-system   metrics-server                                   ClusterIP   10.96.208.69    <none>        443/TCP                         24h
monitoring    alertmanager-operated                            ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP      14m
monitoring    kube-prometheus-stack-alertmanager               NodePort    10.96.235.199   <none>        9093:30093/TCP,8080:30156/TCP   14m
monitoring    kube-prometheus-stack-grafana                    NodePort    10.96.217.211   <none>        80:30000/TCP                    14m
monitoring    kube-prometheus-stack-kube-state-metrics         ClusterIP   10.96.221.249   <none>        8080/TCP                        14m
monitoring    kube-prometheus-stack-operator                   ClusterIP   10.96.162.112   <none>        443/TCP                         14m
monitoring    kube-prometheus-stack-prometheus                 NodePort    10.96.176.64    <none>        9090:30090/TCP,8080:31626/TCP   14m
monitoring    kube-prometheus-stack-prometheus-node-exporter   ClusterIP   10.96.149.4     <none>        9100/TCP                        14m
monitoring    prometheus-operated                              ClusterIP   None            <none>        9090/TCP                        14m
```

Проверим доступность по IP балансировщиков

<details>
    <summary>подробнее IP балансировщиков</summary>
  
```
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc load-balancer network-load-balancer get k8s-services-load-balancer
id: enpf3g2ikr8hup8458qu
folder_id: b1g2pak2mr3h8bt5nfam
created_at: "2025-10-14T18:45:56Z"
name: k8s-services-load-balancer
region_id: ru-central1
status: ACTIVE
type: EXTERNAL
listeners:
  - name: app-listener
    address: 158.160.165.44
    port: "80"
    protocol: TCP
    target_port: "80"
    ip_version: IPV4
  - name: grafana-listener
    address: 158.160.165.44
    port: "3000"
    protocol: TCP
    target_port: "3000"
    ip_version: IPV4
attached_target_groups:
  - target_group_id: enp1308h4k6apj3fpd0v
    health_checks:
      - name: app-healthcheck
        interval: 2s
        timeout: 1s
        unhealthy_threshold: "2"
        healthy_threshold: "2"
        http_options:
          port: "30180"
          path: /healthz

user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc load-balancer target-group get k8s-nodes-target-group
id: enp1308h4k6apj3fpd0v
folder_id: b1g2pak2mr3h8bt5nfam
created_at: "2025-10-14T18:42:46Z"
name: k8s-nodes-target-group
region_id: ru-central1
targets:
  - subnet_id: e2l2pe3a9tbhubgasu7g
    address: 10.0.2.34
  - subnet_id: e9bvamfk1tg5onjejbuu
    address: 10.0.1.18
  - subnet_id: fl8j7vd5kl32pi4phvmf
    address: 10.0.3.29

user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ yc load-balancer target-group get k8s-nodes-target-group --format json | jq '.targets[] | {address: .address, status: .status}'
{
  "address": "10.0.2.34",
  "status": null
}
{
  "address": "10.0.1.18",
  "status": null
}
{
  "address": "10.0.3.29",
  "status": null
}
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://89.169.152.21:30180/healthz
*   Trying 89.169.152.21:30180...
* Connected to 89.169.152.21 (89.169.152.21) port 30180
> GET /healthz HTTP/1.1
> Host: 89.169.152.21:30180
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Tue, 14 Oct 2025 18:53:54 GMT
< Content-Type: application/octet-stream
< Content-Length: 8
< Connection: keep-alive
< Content-Type: text/plain
<
healthy
* Connection #0 to host 89.169.152.21 left intact
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://84.201.152.99:30180/healthz
*   Trying 84.201.152.99:30180...
* Connected to 84.201.152.99 (84.201.152.99) port 30180
> GET /healthz HTTP/1.1
> Host: 84.201.152.99:30180
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Tue, 14 Oct 2025 18:54:00 GMT
< Content-Type: application/octet-stream
< Content-Length: 8
< Connection: keep-alive
< Content-Type: text/plain
<
healthy
* Connection #0 to host 84.201.152.99 left intact
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://158.160.197.70:30180/healthz
*   Trying 158.160.197.70:30180...
* Connected to 158.160.197.70 (158.160.197.70) port 30180
> GET /healthz HTTP/1.1
> Host: 158.160.197.70:30180
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Tue, 14 Oct 2025 18:54:05 GMT
< Content-Type: application/octet-stream
< Content-Length: 8
< Connection: keep-alive
< Content-Type: text/plain
<
healthy
* Connection #0 to host 158.160.197.70 left intact
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ echo "Проверка Grafana на нодах:"
Проверка Grafana на нодах:
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://89.169.152.21:30000/api/health
*   Trying 89.169.152.21:30000...
* Connected to 89.169.152.21 (89.169.152.21) port 30000
> GET /api/health HTTP/1.1
> Host: 89.169.152.21:30000
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Cache-Control: no-store
< Content-Type: application/json; charset=UTF-8
< X-Content-Type-Options: nosniff
< X-Frame-Options: deny
< X-Xss-Protection: 1; mode=block
< Date: Tue, 14 Oct 2025 18:54:16 GMT
< Content-Length: 101
<
{
  "commit": "03f502a94d17f7dc4e6c34acdf8428aedd986e4c",
  "database": "ok",
  "version": "10.4.0"
* Connection #0 to host 89.169.152.21 left intact
}user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://84.201.152.99:30000/api/health
*   Trying 84.201.152.99:30000...
* Connected to 84.201.152.99 (84.201.152.99) port 30000
> GET /api/health HTTP/1.1
> Host: 84.201.152.99:30000
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Cache-Control: no-store
< Content-Type: application/json; charset=UTF-8
< X-Content-Type-Options: nosniff
< X-Frame-Options: deny
< X-Xss-Protection: 1; mode=block
< Date: Tue, 14 Oct 2025 18:54:22 GMT
< Content-Length: 101
<
{
  "commit": "03f502a94d17f7dc4e6c34acdf8428aedd986e4c",
  "database": "ok",
  "version": "10.4.0"
* Connection #0 to host 84.201.152.99 left intact
}user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ curl -v http://158.160.197.70:30000/api/health
*   Trying 158.160.197.70:30000...
* Connected to 158.160.197.70 (158.160.197.70) port 30000
> GET /api/health HTTP/1.1
> Host: 158.160.197.70:30000
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Cache-Control: no-store
< Content-Type: application/json; charset=UTF-8
< X-Content-Type-Options: nosniff
< X-Frame-Options: deny
< X-Xss-Protection: 1; mode=block
< Date: Tue, 14 Oct 2025 18:54:27 GMT
< Content-Length: 101
<
{
  "commit": "03f502a94d17f7dc4e6c34acdf8428aedd986e4c",
  "database": "ok",
  "version": "10.4.0"
* Connection #0 to host 158.160.197.70 left intact
```
</details>

Мониторинг Входим в Grafana http://158.160.197.70:3000/ c ```admin/prom-operator```, открываем дашборд Kubernetes / Compute Resources / Cluster по ссылке: ```http://89.169.152.21:30000/d/efa86fd1d0c121a26444b636a3f509a8/kubernetes-compute-resources-cluster?orgId=1&refresh=10s```

<img width="2276" height="1468" alt="image" src="https://github.com/user-attachments/assets/1c9a08a6-6049-4786-a2a6-8d7e58128f9b" />

### 5. Установка и настройка CI/CD

Для настройки был выбран github action

Был написан ```./terraform/cicd.tf``` 
 
```
# Используем существующий Service Account по ID из key.json
data "yandex_iam_service_account" "existing_sa" {
  service_account_id = "ajer93efebn650j9q2ta"  # Используем ID из key.json
}

# Kubernetes Service Account для CI/CD деплоя
resource "kubernetes_service_account" "cicd" {
  metadata {
    name      = "cicd-service-account"
    namespace = "default"
  }
}

# ClusterRoleBinding для CI/CD Service Account
resource "kubernetes_cluster_role_binding" "cicd" {
  metadata {
    name = "cicd-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cicd.metadata[0].name
    namespace = "default"
  }
}

# ConfigMap с настройками для CI/CD
resource "kubernetes_config_map" "cicd_config" {
  metadata {
    name      = "cicd-config"
    namespace = "default"
  }

  data = {
    registry-url     = "cr.yandex/${yandex_container_registry.app_registry.id}"
    cluster-endpoint = yandex_kubernetes_cluster.devops-diplom.master[0].external_v4_endpoint
    cluster-ca-cert  = yandex_kubernetes_cluster.devops-diplom.master[0].cluster_ca_certificate
    sa-id            = data.yandex_iam_service_account.existing_sa.id
    sa-name          = data.yandex_iam_service_account.existing_sa.name
  }
}

# Secret с информацией для CI/CD
resource "kubernetes_secret" "cicd_secrets" {
  metadata {
    name      = "cicd-secrets"
    namespace = "default"
  }

  data = {
    sa-id   = data.yandex_iam_service_account.existing_sa.id
    sa-name = data.yandex_iam_service_account.existing_sa.name
  }

  depends_on = [yandex_kubernetes_cluster.devops-diplom]
}
```

добавляем Helm https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/terraform/monitoring.tf в приложение

```
# monitoring.tf - без ServiceMonitor

# Установка kube-prometheus-stack через Helm provider
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true
  version    = "58.0.0"

  values = [
    <<-EOT
    grafana:
      adminPassword: "prom-operator"
      service:
        type: NodePort
        nodePort: 30000
    prometheus:
      service:
        type: NodePort
        nodePort: 30090
    alertmanager:
      service:
        type: NodePort
        nodePort: 30093
    EOT
  ]

  depends_on = [
    yandex_kubernetes_cluster.devops-diplom
  ]
}
```

Сам репозиторий https://github.com/Kulikova-A18/devops-diplom-yandexcloud-app

Также записываем свои ключи в настройке

<img width="1281" height="1354" alt="image" src="https://github.com/user-attachments/assets/16462cc8-04fd-438e-9b5c-eadf7e7bf814" />


<img width="1107" height="300" alt="image" src="https://github.com/user-attachments/assets/727ddfa1-18dd-4a70-9690-0bb2402b6c57" />

## Итоги дипломного практикума в Yandex.Cloud

Для упрощения процесса ранее выполненных действий написаны следующие скрипты:

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

Вся инструкция по запуску скриптов располагается по следующей ссылке: https://github.com/Kulikova-A18/devops-diplom-yandexcloud/blob/main/deploy-all.md

<img width="1790" height="464" alt="image" src="https://github.com/user-attachments/assets/aff434d0-4cb2-42fb-bfde-813bf7897532" />

Репозиторий с конфигурационными файлами Terraform: 

https://github.com/Kulikova-A18/devops-diplom-yandexcloud/tree/main/terraform

grafana:

[http://51.250.21.171:30001/](http://51.250.21.171:30001/)
[http://158.160.127.184:30001/](http://158.160.127.184:30001/)
[http://158.160.205.249:30001/](http://158.160.205.249:30001/)

Логин ```admin``` 

Пароль ```prom-operator```

Приложения:

[http://51.250.21.171](http://51.250.21.171:30102/)
[http://158.160.127.184](http://158.160.127.184:30102/)
[http://158.160.205.249](http://158.160.205.249:30102/)

Репозиторий с Dockerfile тестового приложения:

https://github.com/Kulikova-A18/devops-diplom-yandexcloud-app/blob/main/Dockerfile

CI-CD-terraform pipeline:

https://github.com/Kulikova-A18/devops-diplom-yandexcloud-app/tree/main/.github/workflows

Репозиторий с конфигурацией ansible:

https://github.com/Kulikova-A18/devops-diplom-yandexcloud/tree/main/ansible
