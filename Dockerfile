FROM php:8.2-fpm-alpine3.18 AS build

# Çalışma dizinini ayarla
WORKDIR /var/www/html

# Gerekli paketleri yükle
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

# PHP eklentilerini yapılandır ve yükle
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_pgsql \
        zip \
        exif \
        pcntl \
        bcmath \
        gd

# Composer'ı yükle
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Composer'ı optimize et
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/tmp

# NPM kısmını kaldırıyoruz çünkü çalışma anında npm'e ihtiyaç duymuyoruz
# ve npm@latest yükleme işlemi hata veriyor

# Uygulama dosyalarını kopyala
COPY . /var/www/html/

# Supervisor yapılandırmasını kopyala
RUN mkdir -p /etc/supervisor.d/
COPY supervisord.conf /etc/supervisor.d/supervisord.ini

# PHP ve PHP-FPM yapılandırmasını düzenle
RUN { \
    echo 'upload_max_filesize = 20M'; \
    echo 'post_max_size = 20M'; \
    echo 'max_execution_time = 300'; \
    echo 'memory_limit = 512M'; \
} > /usr/local/etc/php/conf.d/docker-fpm.ini

# Çalıştırma betiğini kopyala ve çalıştırılabilir hale getir
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# Port değişkenini ortama ekle
ENV PORT=80

# Portu dışa aç (Render.com dinamik olarak PORT değişkenini atayacak)
EXPOSE $PORT

# Başlangıç ​​komutu
CMD ["/start.sh"] 