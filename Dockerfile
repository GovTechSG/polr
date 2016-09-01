FROM php:5.6-apache

WORKDIR /usr/app/src
ENV COMPOSER_COMMIT e67dc80d23742dd8ad67fa63135d7f8fdf2e2fb6

RUN set -x \
    && a2enmod rewrite \
    && apt-get update \
    && apt-get install -y git \
                          zip \
                          zlib1g-dev
RUN set -x \
    && pecl install zip \
    && docker-php-ext-enable zip \
    && curl "https://raw.githubusercontent.com/composer/getcomposer.org/${COMPOSER_COMMIT}/web/installer" | php

COPY composer.json composer.lock /usr/app/src/
RUN php composer.phar install --no-dev --no-autoloader

COPY . /usr/app/src/
RUN set -x \
    && php composer.phar dump-autoload -o --no-dev \
    && sed -i 's#/var/www/#/usr/app/src/public/#g' $APACHE_CONFDIR/conf-available/docker-php.conf

EXPOSE 80
