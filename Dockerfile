FROM php:7.4-apache

COPY . /var/www/html/

# Скачиваем и запускаем скрипт установки расширений
RUN curl -sSLf \
        -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions xmlrpc

# Используется Debian, устанавливаем cron и убираем лишние файлы
RUN apt-get update && apt-get install -y cron && which cron && \
    rm -rf /etc/cron.*/*

# Для запуска cron создаём шелл-скрипт cron-php-apache-entrypoint, который экспортирует переменные окружения в /etc/environment
# Также позволяет запускать дополнительные команды за счёт изменения CMD при запуске контейнера. 
#     Пример:  docker run berkut174/webtlo -v `pwd`/my-script.sh:my-script.sh my-script.sh 
#     загружает my-script.sh из текущей папки в контейнер и не будет запускать php, пока my-script не завершится
# Алгоритм выполнения: 
# 1. Команды и аргументы, переданные в CMD исполняются при помощи /bin/bash
# 2. Запущенный скрипт ENTRYPOINT заменяется на "docker-php-entrypoint apache2-foreground" ради сохранения управления контейнером с помощью docker stop и т.п.
# Чтобы отказаться от старта cron и php + apache2, задайте иной ENTRYPOINT в момент запуска контейнера

# Для запуска cron необходимо иметь /crontab файл, добавим его с помощью docker compose, а стандартный положим из репозитория в /etc/crontab.
RUN mv /var/www/html/example-crontab /etc/crontab
RUN chmod +x ./cron-php-apache2-entrypoint.sh
ENTRYPOINT ["./cron-php-apache2-entrypoint.sh"]
