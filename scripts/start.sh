#!/bin/bash

# Composer bağımlılıklarını kur
composer install --no-dev --optimize-autoloader

# .env dosyası yoksa, örnek dosyadan kopyala
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Uygulama anahtarı oluştur
php artisan key:generate

# Yapılandırma önbelleğini temizle ve yeniden oluştur
php artisan config:clear
php artisan config:cache

# Rota önbelleğini temizle ve yeniden oluştur
php artisan route:clear
php artisan route:cache

# Gerekli izinleri ver
chmod -R 775 storage bootstrap/cache

# SQLite için veritabanı dosyası oluştur (eğer yoksa)
if [ ! -f database/database.sqlite ]; then
    mkdir -p database
    touch database/database.sqlite
fi

# Migrasyonları çalıştır
php artisan migrate --force

# NPM paketlerini yükle ve derle
npm install
npm run build

# Supervisor için yapılandırma oluştur
mkdir -p /etc/supervisor/conf.d/
cat > /etc/supervisor/conf.d/supervisord.conf << EOF
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisord.log
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
command=php /var/www/html/artisan websockets:serve
autostart=true
autorestart=true
priority=20
stdout_logfile=/var/www/html/storage/logs/websockets.log
stderr_logfile=/var/www/html/storage/logs/websockets.log
EOF

# Supervisor'ı başlat
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf 