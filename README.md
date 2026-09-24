# diploma-app

Тестовое приложение для дипломного практикума в Yandex Cloud.

Простой nginx со статической страницей, собранный в Docker-образ
и задеплоенный в Kubernetes через CI/CD.

## Состав

- `index.html` — статическая страница приложения
- `nginx.conf` — конфиг nginx с эндпоинтом /healthz для проб
- `Dockerfile` — сборка образа на базе nginx:1.27-alpine
- `deploy/k8s/` — Kubernetes-манифесты:
  - `deployment.yaml` — 2 реплики, readiness/liveness-пробы, imagePullSecrets
  - `service.yaml` — ClusterIP
  - `ingress.yaml` — публикация через nginx-ingress на app.<IP>.nip.io
- `.github/workflows/build-deploy.yml` — CI/CD

## CI/CD (GitHub Actions)

Триггеры:

- push в main → сборка и push образа с тегом sha-<short>
- push тега v* → сборка, push с версионным тегом + deploy в кластер
- workflow_dispatch → ручной запуск

Шаги job'а build:

1. Установка buildx v0.9.1 (совместимо с Yandex Container Registry)
2. Login в cr.yandex через SA JSON
3. Сборка образа с build-args APP_VERSION и APP_BUILD
4. Push в Yandex Container Registry

Шаги job'а deploy (только для тега v*):

1. Установка kubectl и yc CLI
2. Динамическое добавление IP GitHub-раннера в security group YC
   (порт 6443, CIDR /32 — не открываем API всему интернету)
3. Настройка kubeconfig из secret KUBE_CONFIG_B64
4. kubectl apply манифестов и kubectl set image на новый тег
5. Ожидание rollout status
6. Удаление правила SG в блоке always()

## GitHub Secrets

- YC_SA_KEY_JSON — сервисный аккаунт Yandex Cloud (JSON-ключ)
- KUBE_CONFIG_B64 — base64 от ~/.kube/config
- YC_CLOUD_ID — ID облака
- YC_FOLDER_ID — ID каталога

## Ссылки

- Образ: cr.yandex/crpvgs42tbh16im42p7a/diploma-app
- Приложение: http://app.89.169.146.16.nip.io/
- Yandex Container Registry: создаётся через diploma-infra

## Сборка и запуск локально

  docker build -t diploma-app:local .
  docker run --rm -p 8080:80 diploma-app:local
  curl http://localhost:8080/healthz

## Деплой в кластер

  kubectl apply -f deploy/k8s/

Секрет yc-registry для pull из приватного реестра создаётся один раз:

  kubectl create secret docker-registry yc-registry \
    --docker-server=cr.yandex \
    --docker-username=json_key \
    --docker-password="$(cat /path/to/sa-key.json | tr -d '\n')" \
    --docker-email=unused@example.com \
    --namespace=default
