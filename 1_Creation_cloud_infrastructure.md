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
    O5C1Hu1OHpqsE8Xd7A+KGEbyTXPzL7ep0ynCjebh2xDSBFn4/rmyxFuzP7eAyCOb
    fG8J4loU5qmAoosCW1ALQwzVyDZ1paEq5pi7FBqoNUFmQf3hkGlDas1e4+zGVXkA
    mX1r/bcAXOG60O5/5PNhNPedipkWq7YqMojr8D/YCoEuCc8+vE6cTFICxVvClJ+e
    hiA3ZRZSUKUKHGcC+K/ppz4ojS/WT1ZODMRQ6g+TDhRwu2jFwHTDnIYuz3vduSWN
    7wIDAQAB
    -----END PUBLIC KEY-----
  private_key: |
    PLEASE DO NOT REMOVE THIS LINE! Yandex.Cloud SA Key ID <ajen0eb8uk1qllevo48q>
    -----BEGIN PRIVATE KEY-----
    ***
    876eCXb3q6JXkA9+VUNloYLiUuUBWMcf35o4uyolyDju7JRWo+Z3UQKBgH5H5mNp
    zIyb7/22szaeqHCAk1a5XyhZkSVuqHz8s0Ikshx6/H+dPyy066P+KuH3ZxbdtfJ5
    mpK2eDXRGM5CyX36bHI7XVqL8d1pBeU5ZNGYuc1ywXUubQNCdWCjJcCoExCbMiiU
    5y/RY/DO01roLlfEgeT6aR2r7pjEj8zcqNbRAoGBAMBwIHw+kDgXQQH7PmOM5NQQ
    uT7HUERC26O1jyOVU9YiSLf8ujWqUJi0KcxEj88kmLnX4GZfLkP1OFkwySxIRCQ2
    LbidgnmJ25E7J2TSuVe2Kq8BuaTTRLqGP3XUqq5AmUjdCE3RoX91lLiS/AjH597X
    LGTfGCjN8klz6bSYTsg5
    -----END PRIVATE KEY-----
cloud-id: b1gphk6fe2qpbmph96u5
folder-id: b1g2pak2mr3h8bt5nfam
compute-default-zone: ru-central1-a
```

*После сдачи машинка со всеми данными будет удалена. Информация будет не действительна

### Выполнение

1. Для подгтовки облачной инфрастуктуры использем terraform и платформу Yandex.Cloud.

Готовим предпологаемую схему: 

```тут будет схема```

Создаем сервисный аккаунт в Yandex.Cloud с минимальными, но достаточными правами

> Во время выполнения уже авторизованы под сервисным аккаунтом, который уже работает в конкретной папке (```folder_id: b1g2pak2mr3h8bt5nfam```). У этого сервисного аккаунта нет прав создавать новые папки на уровне облака, но он может работать внутри своей папки

1.1.Создаем сервисный аккаунт в существующей папке ```yc iam service-account create --name devops-diplom-yandexcloud-sa --folder-id b1g2pak2mr3h8bt5nfam```

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

1.2.Получаем ID созданного сервисного аккаунта ```yc iam service-account get devops-diplom-yandexcloud-sa --format json | jq -r '.id'```

<details>
    <summary>подробнее</summary>
  
```shell
user@compute-vm-2-1-10-hdd-1742233033265:~$ yc iam service-account get devops-diplom-yandexcloud-sa --format json | jq -r '.id'
ajer93efebn650j9q2ta
```
</details>

1.3.Назначаем права сервисному аккаунту ```yc resource-manager folder add-access-binding b1g2pak2mr3h8bt5nfam --role editor --subject serviceAccount:<SA_ID>```

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

1.4.Создаем ключ доступа ```yc iam key create --service-account-name devops-diplom-yandexcloud-sa --folder-id b1g2pak2mr3h8bt5nfam --output key.json```

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

1.5.Проверяем, что ключ создан ```ls -la key.json``` и ```cat key.json | jq -r '.id'```

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
   "public_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2bLkugfgACsFpPV2dj4M\nyalAdaNOrhE7iiJST6Y007jtZ0SwAkpTQKTNHSn1bwi3ya5PyQ63Tw38sAr47Hpc\nNBrDaEkbsQLnffGo/uJhwCFkHPoJe3VvEFDbxxyfhdOqlBgcf/SqVG6TKUa8T1dk\nmEC2UkfB1Ydz5iUim9M0uKgw0Rl7IhpySzg+1YMqKfaaHm3mpHx+2O/UM5pfr4I1\n4pz1HOpchh0hKhEBB2RKz6BewEeT3SsLDzdDmtI0jTLXv+bDLc95hCf2n6zQ3FQG\nIJMbHJ0BWRKXj5xAdRVYu1ZbguAlQSZRAAxDO+4e7UHHqQMLjP9CQYMV2/c3DBB+\nYQIDAQAB\n-----END PUBLIC KEY-----\n",
   "private_key": "PLEASE DO NOT REMOVE THIS LINE! Yandex.Cloud SA Key ID \u003cajeau9qmpfmn0obm9kei\u003e\n-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDZsuS6B+AAKwWk\n9XZ2PgzJqUB1o06uETuKIlJPpjTTuO1nRLACSlNApM0dKfVvCLfJrk/JDrdPDfyw\nCvjselw0GsNoSRuxAud98aj+4mHAIWQc+gl7dW8QUNvHHJ+F06qUGBx/9KpUbpMp\nRrxPV2SYQLZSR8HVh3PmJSKb0zS4qDDRGXsiGnJLOD7Vgyop9poebeakfH7Y79Qz\nml+vgjXinPUc6lyGHSEqEQEHZErPoF7AR5PdKwsPN0Oa0jSNMte/5sMtz3mEJ/af\nrNDcVAYgkxscnQFZEpePnEB1FVi7VluC4CVBJlEADEM77h7tQcepAwuM/0JBgxXb\n9zcMEH5hAgMBAAECggEATB0FZltxgG2KTCn8MIwySWGRJXAjBq4EvJ+SWsG4L5w0\n+Mmlpi9ZWz0jb8JnStpn864rvBaWlZ/EzMIRVRDU4uzGjFQfR+zFhh2zYeZBmfyy\ntYTgQteErNYweTWzOoWOWrfxYvVmhh2g+yn9ldnu1GKvvCXVifQRXBJ4vrWB9dtG\nwtLQ/w3dRLt4XHdYPUx/CAbHML+7IJnLeOpv1mjrJbd+7w97zQXIW1tnh24P4EuG\nxivVss12FO1d/zJ+cUnt9buO+sapDPyZOzXR6EevoAtpk1UuomVn6riEi+E+/xGu\nQN13O0ZuhdTf5Rn4iHNT4idKe5u20nJadFsJOcYxJwKBgQD8HAkIqtjgMb1GSuCm\nzXgGGHU2SzBFc2jP7XLqo6DCBhMWavalAcmI6o9RegNpKVtUNDu57bsVkrR1YduR\n3X8aR9PtGSGWKP6egk50I88XW+ELP0BDWk6K5ngiJmgWbpdXb9LEZw/uDKuSIVKU\nTW80Zy5DtkzYuDsqcw1qxoPy/wKBgQDdDur3L1LoIFfZZieKjgTwpfaNcLArNDDT\ndCKn42wf2rL3UY6YtuGGe3jIVxcphJSLKYEI+ERy+JTlBOk7igH3g4IlILMBzKTe\nt4xB30w9N/6uanNiLdiZAfUNK4CtO8A5em2zV00HFQ7mvj8VFdxv0BDTUFtuDcAx\nL16iCU1unwKBgAckwDjHpoeLwUI5ou33CnyZutCEBuUg5QpnPwdZBZgZ1fafp0d7\nqns/sjnrzCbxrg3PwRV+n/t3gbeFw1P5w7055c5lFOeNV9Gj/Zca4KZXyyOncim2\naF1VNHg7QF3KWm121LEN/oyPPVlRqmZbX1hLyCrRApJtffew9ONepqR/AoGBALuB\nueCt7Z8kQCARvJyUVrBhtj7HRUeAX6IdMoBCMiba9U8/iLsU9TuDZDJbXTREV1Or\ngt4+6KC1JmcUwVlVeNGgZTZlBDIUigy4mGoPpLWQ16DOfszaoo020cu4CM/ojOa0\naHTlKltFi3xCB3Q1NORLEtqLoOI7G7kcuyKqzVl1AoGAe8KtdwYFI6e9w5PzDouM\nYPTMMbx2vWSwKEhlbrmu9Mhn+VE/rEj+QxScQYDObmTJmhQWmgdeFgW8EkTODlzd\ncjZTxOdteFn7ZiMMb+DtMCc3pwEzoHVlyu3W/3O/Q2IV20SUu70w3wxE8YIqhi7Y\nBAfCn5zX90xA82A2YvZF1jo=\n-----END PRIVATE KEY-----\n"
}user@compute-vm-2-1-10-hdd-1742233033265:~$
```
</details>

2. Готовим terraform который создаст специальную сервисную учетку `tf-sa` и S3 бакет для terraform backend в основном проекте [в отдельной папке](./preparation/) и запускаем его

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

3. Готовим [основновной манифест](./terraform/) terraform с VPC и запускаем егоиспользуя ключи из `backend.key` которые получили на прошлом шаге
    Результат:
`terraform init -backend-config="access_key=***" -backend-config="secret_key=***"`
`terraform apply --auto-approve`

<details>
    <summary>подробнее</summary>

```shell
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ ls -la backend.key
ackend.key-rwxrwxr-x 1 user user 97 Oct 12 18:29 backend.key
user@compute-vm-2-1-10-hdd-1742233033265:~/devops-diplom-yandexcloud/terraform$ cat backend.key
access_key = "YCAJEQkN5TTT1m3_Xb7tH7YJt"
secret_key = "YCObfKz_5JOvgp0uAm2oaSK5NBFROdVd3vPDaNiJ"
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
                    devops:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTpQSISAT/5DpL6RWkbipLhDKgj+lzcMpjchiGiVfdaXCVCCGFN4XDzcxCeJ6ioGRtyvSSyfCLoBS1zgY2P0LBSQLuXs/TuhioKqVkBWwFYrYY1NkvE4si5ciuVKUSUUeoCEwdIi0xdwp/0ukmRrviTXJ354sLtpTt2gCjQfYN6NVy9KKuQpa3DfA+MECG05FhLmQ2htCGM5MvInRTO9qYEcmO5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
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
                    ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTpQSISAT/5DpL6RWkbipLhDKgj+lzcMpjchiGiVfdaXCVCCGFN4XDzcxCeJ6ioGRtyvSSyfCLoBS1zgY2P0LBSQLuXs/TuhioKqVkBWwFYrYY1NkvE4si5ciuVKUSUUeoCEwdIi0xdwp/0ukmRrviTXJ354sLtpTt2gCjQfYN6NVy9KKuQpa3DfA+MECG05FhLmQ2htCGM5MvInRTO9qYEcmO5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
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

4. Проверяем `terraform destroy` и `terraform apply`
    Результат:
    
<details>
    <summary>подробнее</summary>

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
                    devops:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTpQSISAT/5DpL6RWkbipLhDKgj+lzcMpjchiGiVfdaXCVCCGFN4XDzcxCeJ6ioGRtyvSSyfCLoBS1zgY2P0LBSQLuXs/TuhioKqVkBWwFYrYY1NkvE4si5ciuVKUSUUeoCEwdIi0xdwp/0ukmRrviTXJ354sLtpTt2gCjQfYN6NVy9KKuQpa3DfA+MECG05FhLmQ2htCGM5MvInRTO9qYEcmO5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
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
                    ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTpQSISAT/5DpL6RWkbipLhDKgj+lzcMpjchiGiVfdaXCVCCGFN4XDzcxCeJ6ioGRtyvSSyfCLoBS1zgY2P0LBSQLuXs/TuhioKqVkBWwFYrYY1NkvE4si5ciuVKUSUUeoCEwdIi0xdwp/0ukmRrviTXJ354sLtpTt2gCjQfYN6NVy9KKuQpa3DfA+MECG05FhLmQ2htCGM5MvInRTO9qYEcmO5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
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
                    devops:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTpQSISAT/5DpL6RWkbipLhDKgj+lzcMpjchiGiVfdaXCVCCGFN4XDzcxCeJ6ioGRtyvSSyfCLoBS1zgY2P0LBSQLuXs/TuhioKqVkBWwFYrYY1NkvE4si5ciuVKUSUUeoCEwdIi0xdwp/0ukmRrviTXJ354sLtpTt2gCjQfYN6NVy9KKuQpa3DfA+MECG05FhLmQ2htCGM5MvInRTO9qYEcmO5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
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
                    ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTpQSISAT/5DpL6RWkbipLhDKgj+lzcMpjchiGiVfdaXCVCCGFN4XDzcxCeJ6ioGRtyvSSyfCLoBS1zgY2P0LBSQLuXs/TuhioKqVkBWwFYrYY1NkvE4si5ciuVKUSUUeoCEwdIi0xdwp/0ukmRrviTXJ354sLtpTt2gCjQfYN6NVy9KKuQpa3DfA+MECG05FhLmQ2htCGM5MvInRTO9qYEcmO5UFr/ZxAQFpxrhY//5y62+FIVpXAeSCD51BnUUxo2U0E+YkkmBEjex8YA+tx7lsMqAOQolyqZY11L14ZCigIjeXRWyFPJzsXIN1ROSA0WvedYYFKJ0tz2fht7yXj user@compute-vm-2-1-10-hdd-1742233033265
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
</details>
