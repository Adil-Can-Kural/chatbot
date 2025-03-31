FROM php:8.2-fpm-alpine3.18

WORKDIR /var/www/html

# Gerekli PHP eklentilerini ve bağımlılıkları kur
RUN apk update && apk add --no-cache \
    nginx \
    supervisor \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libwebp-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    nodejs \
    npm \
    oniguruma-dev \
    postgresql-dev \
    bash \
    bind-tools \
    netcat-openbsd

# GD konfigürasyonu ve PHP eklentilerinin kurulumu
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_pgsql \
        zip \
        exif \
        pcntl \
        bcmath \
        gd

# PHP-FPM için sembolik bağlantılar oluştur (path sorunlarını çözmek için)
RUN ln -sf /usr/local/sbin/php-fpm /usr/sbin/php-fpm && \
    ln -sf /usr/local/sbin/php-fpm /usr/sbin/php-fpm8 && \
    ln -sf /usr/local/bin/php /usr/bin/php

# Composer kur
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Scripts dizinini oluştur
RUN mkdir -p /var/www/html/scripts

# Önce betik dosyalarını kopyala
COPY scripts /var/www/html/scripts/

# Gerekli izinleri ayarla
RUN chmod +x /var/www/html/scripts/build.sh && \
    chmod +x /var/www/html/scripts/start.sh

# composer.json ve composer.lock dosyalarını kopyala
COPY composer.json composer.lock ./

# Composer bağımlılıklarını yükle
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Kalan uygulama kodlarını kopyala
COPY . /var/www/html/

# Dizinlere gerekli izinleri ver
RUN mkdir -p /var/www/html/storage/logs \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/framework/cache \
    && chmod -R 777 /var/www/html/storage \
    && chmod -R 777 /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html

# Nginx konfigürasyonu
COPY ./nginx/default.conf /etc/nginx/http.d/default.conf

# Supervisor konfigürasyonu
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Supervisor dizinlerini oluştur
RUN mkdir -p /var/log/supervisor /var/log/nginx /run/nginx \
    && chmod -R 777 /var/log/supervisor \
    && chmod -R 777 /var/log/nginx \
    && chmod -R 777 /run/nginx

# Expose ports
EXPOSE 80
EXPOSE 6001

# Başlangıç komutu
CMD ["/bin/bash", "/var/www/html/scripts/start.sh"] 