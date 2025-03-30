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

# Betik dosyalarını manuel olarak oluştur
RUN echo '#!/bin/bash\n\
# Hata ayıklama için\n\
set -e\n\
echo "Building Laravel application for Render.com deployment..."\n\
# Composer bağımlılıklarını kur\n\
echo "Installing Composer dependencies..."\n\
composer install --no-dev --optimize-autoloader\n\
# NPM paketlerini yükle ve derle\n\
if [ -f package.json ]; then\n\
    echo "Installing and building NPM packages..."\n\
    npm ci --quiet\n\
    npm run build\n\
fi\n\
# Storage ve bootstrap/cache dizinleri için izinleri ayarla\n\
echo "Setting directory permissions..."\n\
chmod -R 775 storage bootstrap/cache\n\
echo "Build completed successfully!"\n\
' > /var/www/html/scripts/build.sh

RUN echo '#!/bin/bash\n\
# Hata ayıklama için\n\
set -e\n\
echo "Starting Laravel application setup..."\n\
# Container içinde beklenen dizinleri oluştur\n\
mkdir -p /run/nginx\n\
mkdir -p /var/log/supervisor\n\
mkdir -p /var/log/nginx\n\
# Tüm uygulama dizinini listele (debug için)\n\
ls -la /var/www/html/\n\
# Ağ bağlantılarını test et\n\
echo "Testing network connectivity..."\n\
echo "Hostname: $DB_HOST"\n\
echo "Trying to resolve host..."\n\
nslookup $DB_HOST || echo "DNS resolution failed!"\n\
# Veritabanı bağlantısını test et\n\
echo "Testing database connection..."\n\
if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ] && [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ]; then\n\
  echo "Testing connection to $DB_HOST:$DB_PORT..."\n\
  nc -zv $DB_HOST $DB_PORT || echo "Connection failed!"\n\
fi\n\
# Composer bağımlılıklarını kur\n\
echo "Installing Composer dependencies..."\n\
composer install --no-dev --optimize-autoloader\n\
# .env dosyası yoksa, örnek dosyadan kopyala\n\
if [ ! -f .env ]; then\n\
    echo "Creating .env file from example..."\n\
    cp .env.example .env\n\
    # .env dosyasını manuel olarak yapılandır\n\
    echo "Configuring .env file manually..."\n\
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=$DB_CONNECTION/" .env\n\
    sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" .env\n\
    sed -i "s/DB_PORT=.*/DB_PORT=$DB_PORT/" .env\n\
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" .env\n\
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" .env\n\
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env\n\
fi\n\
# Uygulama anahtarı oluştur\n\
echo "Generating application key..."\n\
php artisan key:generate --force\n\
# PostgreSQL veritabanı için migrationları çalıştır\n\
echo "Running migrations..."\n\
php artisan migrate --force\n\
# Supervisor için yapılandırma oluştur\n\
echo "Configuring Supervisor..."\n\
mkdir -p /etc/supervisor/conf.d/\n\
cat > /etc/supervisor/conf.d/supervisord.conf << EOF\n\
[supervisord]\n\
nodaemon=true\n\
user=root\n\
logfile=/var/log/supervisor/supervisord.log\n\
pidfile=/var/run/supervisord.pid\n\
\n\
[program:nginx]\n\
command=/usr/sbin/nginx -g "daemon off;"\n\
autostart=true\n\
autorestart=true\n\
priority=10\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:php-fpm]\n\
command=/usr/sbin/php-fpm8 -F\n\
autostart=true\n\
autorestart=true\n\
priority=5\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:websockets]\n\
command=php /var/www/html/artisan websockets:serve --host=0.0.0.0 --port=6001\n\
autostart=true\n\
autorestart=true\n\
priority=20\n\
stdout_logfile=/var/log/supervisor/websockets.log\n\
stderr_logfile=/var/log/supervisor/websockets_error.log\n\
EOF\n\
echo "Starting Supervisor..."\n\
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf\n\
' > /var/www/html/scripts/start.sh

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