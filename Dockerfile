FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# Gerekli PHP eklentilerini ve bağımlılıkları kur
RUN apk add --no-cache \
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
    dos2unix

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

# Scripts dizinini önce kopyala
COPY ./scripts /var/www/html/scripts/

# Gerekli izinleri ayarla ve satır sonlarını düzelt
RUN chmod +x /var/www/html/scripts/build.sh && \
    chmod +x /var/www/html/scripts/start.sh && \
    dos2unix /var/www/html/scripts/*.sh

# Kalan uygulama kodlarını kopyala
COPY . /var/www/html/

# Nginx konfigürasyonu
COPY ./nginx/default.conf /etc/nginx/http.d/default.conf

# Expose ports
EXPOSE 80
EXPOSE 6001

# Start command
CMD ["/var/www/html/scripts/start.sh"] 