#!/bin/bash

# Hata ayıklama için
set -e
echo "Starting Laravel application setup..."

# Container içinde beklenen dizinleri oluştur
mkdir -p /run/nginx
mkdir -p /var/log/supervisor
mkdir -p /var/log/nginx

# Çevre değişkenlerini görüntüle
echo "Environment variables:"
echo "DB_CONNECTION: $DB_CONNECTION"
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_DATABASE: $DB_DATABASE"
echo "DB_USERNAME: $DB_USERNAME"

# Tüm uygulama dizinini listele (debug için)
ls -la /var/www/html/

# Ağ bağlantılarını test et
echo "Testing network connectivity..."
echo "Trying to resolve host..."
nslookup dpg-cvkkl6l6ubrc73fq9b6g-a || echo "DNS resolution failed!"

# Veritabanı bağlantısını test et
echo "Testing database connection..."
echo "Testing connection to dpg-cvkkl6l6ubrc73fq9b6g-a:5432..."
nc -zv dpg-cvkkl6l6ubrc73fq9b6g-a 5432 || echo "Connection failed!"

# Composer bağımlılıklarını kur
echo "Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader

# .env dosyası yoksa, örnek dosyadan kopyala
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
fi

# .env dosyasını manuel olarak yapılandır
echo "Configuring .env file manually..."
sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=pgsql|" .env
sed -i "s|DB_HOST=.*|DB_HOST=dpg-cvkkl6l6ubrc73fq9b6g-a|" .env
sed -i "s|DB_PORT=.*|DB_PORT=5432|" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=chat_ake6|" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=chat_ake6_user|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=5mijBS3BEa5bXxFKj0DgF0cUsQOBLkGP|" .env

# Özel veritabanı yapılandırma dosyasını kopyala
echo "Copying custom database configuration..."
cp /var/www/html/database_config.php /var/www/html/config/database.custom.php
cp /var/www/html/db_override.php /var/www/html/bootstrap/db_override.php

# Laravel bootstrap dosyasını düzenle
if [ -f /var/www/html/bootstrap/app.php ]; then
    echo "Modifying bootstrap/app.php to load database override..."
    sed -i "/^return \$app;/i // Load database override\\nrequire_once __DIR__ . '/db_override.php';" /var/www/html/bootstrap/app.php
fi

# Config dosyalarını temizle
php artisan config:clear

# Uygulama anahtarı oluştur
echo "Generating application key..."
php artisan key:generate --force

# PostgreSQL veritabanı için migrationları çalıştır
echo "Running migrations..."
php artisan migrate --force

# Supervisor için yapılandırma oluştur
echo "Configuring Supervisor..."
mkdir -p /etc/supervisor/conf.d/
cat > /etc/supervisor/conf.d/supervisord.conf << EOF
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
priority=10
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:php-fpm]
command=/usr/sbin/php-fpm8 -F
autostart=true
autorestart=true
priority=5
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:websockets]
command=php /var/www/html/artisan websockets:serve --host=0.0.0.0 --port=6001
autostart=true
autorestart=true
priority=20
stdout_logfile=/var/log/supervisor/websockets.log
stderr_logfile=/var/log/supervisor/websockets_error.log
EOF

echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf 