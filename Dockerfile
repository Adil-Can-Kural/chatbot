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

# Composer kur
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Scripts dizinini oluştur
RUN mkdir -p /var/www/html/scripts

# Betik ve konfigürasyon dosyalarını kopyala
COPY scripts/build.sh /var/www/html/scripts/
COPY scripts/start.sh /var/www/html/scripts/
COPY database_config.php /var/www/html/
COPY db_override.php /var/www/html/

# Gerekli izinleri ayarla
RUN chmod +x /var/www/html/scripts/build.sh && \
    chmod +x /var/www/html/scripts/start.sh && \
    ls -la /var/www/html/scripts/

# Kalan uygulama kodlarını kopyala
COPY . /var/www/html/

# Nginx konfigürasyonu
COPY ./nginx/default.conf /etc/nginx/http.d/default.conf

# Expose ports
EXPOSE 80
EXPOSE 6001

# Start command
CMD ["/bin/bash", "/var/www/html/scripts/start.sh"] 