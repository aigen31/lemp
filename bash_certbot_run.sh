#!/bin/bash

# Предложение пользователю ввести имя домена
read -p "Введите имя домена для сертификации: " domain_name

# Запуск сухой попытки создания сертификата
docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ --dry-run -d $domain_name

# Проверка успешности сухой попытки создания сертификата
read -p "Сертификация выполнена успешно. Хотите продолжить создание сертификата? (y/n): " choice

# Обработка выбора пользователя
if [ "$choice" = "y" ] || [ "$choice" = "yes" ]; then
    docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d $domain_name
elif [ "$choice" = "n" ] || [ "$choice" = "no" ]; then
    echo "Создание сертификата отменено."
else
    echo "Неправильный ввод. Пожалуйста, введите 'y/yes' или 'n/no'."
fi