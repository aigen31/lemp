FROM php:8.3-fpm

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
install-php-extensions gmp \
intl \
xmlrpc \
gd \
zip \
mysqli \
pdo_mysql \
tidy \
xdebug

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
chmod +x wp-cli.phar && \
mv wp-cli.phar /usr/local/bin/wp

COPY /php/conf.d/example.com.ini /usr/local/etc/php/conf.d
COPY /php/php.ini-development /usr/local/etc/php/php.ini
# COPY /php/php.ini-production /usr/local/etc/php/php.ini

WORKDIR /var/www
