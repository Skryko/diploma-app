FROM nginx:1.27-alpine

# Метаданные
LABEL org.opencontainers.image.title="diploma-app"
LABEL org.opencontainers.image.description="Diploma practicum test application"

# Свой конфиг nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Статика
COPY index.html /usr/share/nginx/html/index.html

# Подстановка версии/сборки в момент старта контейнера
# (используем envsubst из nginx:alpine)
ARG APP_VERSION=dev
ARG APP_BUILD=local
ENV APP_VERSION=${APP_VERSION} APP_BUILD=${APP_BUILD}
RUN sed -i "s|__VERSION__|${APP_VERSION}|g; s|__BUILD__|${APP_BUILD}|g" /usr/share/nginx/html/index.html

EXPOSE 80
