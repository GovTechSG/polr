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
    && { \
          echo '<FilesMatch \.php$>'; \
          echo '\tSetHandler application/x-httpd-php'; \
          echo '</FilesMatch>'; \
          echo; \
          echo 'DirectoryIndex disabled'; \
          echo 'DirectoryIndex index.php index.html'; \
          echo; \
          echo '<Directory /usr/app/src/public/>'; \
          echo '\tRequire all granted'; \
          echo '\tOptions Indexes FollowSymLinks'; \
          echo '\tAllowOverride All'; \
          echo '\tOrder allow,deny'; \
          echo '\tAllow from all'; \
          echo '</Directory>'; \
          } | tee "$APACHE_CONFDIR/conf-available/polr.conf" \
    && a2enconf polr \
    && sed -i 's#/var/www/html#/usr/app/src/public/#g' "${APACHE_CONFDIR}/sites-enabled/000-default.conf" \
    && . "$APACHE_ENVVARS" \
    && chown -R "$APACHE_RUN_USER:$APACHE_RUN_GROUP" .
