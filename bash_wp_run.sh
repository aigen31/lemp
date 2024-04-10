#!/bin/bash

# Запрашиваем путь установки Wordpress у пользователя
echo "Введите путь для установки Wordpress: "
read path

# Спрашиваем пользователя, хочет ли он установить Wordpress
echo "Установить Wordpress? (y/n): "
read install_wp

if [ "$install_wp" = "y" ]; then
    wp core download --path="$path" --locale=ru_RU
    sudo chown -R www-data:www-data "$path"
    find "$path" -type d -exec chmod 755 {} \;
    find "$path" -type f -exec chmod 644 {} \;

    # Подключение к базе данных
    echo "Введите имя базы данных: "
    read dbname
    echo "Введите имя пользователя базы данных: "
    read dbuser
    echo "Введите пароль пользователя базы данных: "
    read -s dbpass
    echo "Введите хост базы данных: "
    read dbhost

    wp config --allow-root create --dbname="$dbname" --dbuser="$dbuser" --dbpass="$dbpass" --dbhost="$dbhost" --path="$path" --skip-check
fi

# Установка плагинов
echo "Установить плагины? (y/n): "
read install_plugins

if [ "$install_plugins" = "y" ]; then
    wp plugin --allow-root install --path="$path" cyr2lat fast-velocity-minify kama-spamblock tiny-compress-images wp-mail-smtp wordpress-seo svg-support w3-total-cache --activate
    wp plugin --allow-root uninstall --path="$path" hello-dolly akismet
fi

exit 0
