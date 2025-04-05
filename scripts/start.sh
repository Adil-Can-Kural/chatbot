#!/bin/bash
set -e
echo "Starting Laravel application setup..."

mkdir -p /run/nginx /var/log/supervisor /var/log/nginx

echo "Environment variables (Check if Render injected them):"
printenv | grep DB_ # Veya ilgili değişkenler
echo "PORT: $PORT"

if [ -z "$PORT" ]; then
    echo "PORT variable not set, using default 80"
    export PORT=80
fi
echo "PORT detected: $PORT"

cp /var/www/html/nginx/default.conf /etc/nginx/http.d/default.conf
sed -i "s|listen 80|listen $PORT|g" /etc/nginx/http.d/default.conf

echo "Checking Nginx configuration..."
nginx -t || { echo "Nginx configuration error!"; exit 1; }

echo "Current working directory: $(pwd)"
ls -la # vendor dizini build'de oluşmuş olmalı

# Anahtar yoksa oluştur (ilk deploy için önemli)
if [ ! -f .env ] || ! grep -q "^APP_KEY=.*" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# İzinleri ayarla (Yine de yapmak iyi olabilir)
echo "Setting proper permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# **EĞER MIGRATION RUNTIME'DA ÇALIŞACAKSA (Build'de değilse)**
# echo "Running migrations..."
# php artisan migrate --force || echo "Migration failed or already up-to-date."

echo "Setup completed successfully. Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor.d/supervisord.ini