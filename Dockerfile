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
    postgresql-dev

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

# Uygulama kodlarını kopyala
COPY . .

# Nginx konfigürasyonu
COPY ./nginx/default.conf /etc/nginx/http.d/default.conf

# Gerekli izinleri ayarla
RUN chmod +x /var/www/html/scripts/build.sh
RUN chmod +x /var/www/html/scripts/start.sh

# Expose ports
EXPOSE 80
EXPOSE 6001

# Start command
CMD ["/var/www/html/scripts/start.sh"] 