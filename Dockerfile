FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# Gerekli PHP eklentilerini ve bağımlılıkları kur
RUN apk add --no-cache \
    nginx \
    supervisor \
    sqlite \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    nodejs \
    npm \
    oniguruma-dev \
    postgresql-dev

# PHP eklentilerini kur
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql pdo_sqlite zip exif pcntl bcmath gd

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