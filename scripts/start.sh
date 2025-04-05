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

# .env dosyasını kontrol et ve yoksa oluştur
if [ ! -f .env ]; then
    echo ".env file not found. Copying from .env.example..."
    cp .env.example .env
    # .env dosyası yeni oluşturulduysa, key generate kesinlikle çalışmalı
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Uygulama anahtarı yoksa veya boşsa oluştur (varsa dokunma)
if ! grep -q "^APP_KEY=.\+" .env; then
    echo "Generating application key as it was empty..."
    php artisan key:generate --force
fi

# Composer script'lerini manuel olarak çalıştır (paketleri keşfet)
echo "Discovering packages..."
php artisan package:discover --ansi

# Runtime'da cache'leri temizle ve oluştur
echo "Clearing and generating caches..."
php artisan config:clear
php artisan route:clear
# php artisan view:clear # İhtiyaç varsa
php artisan cache:clear

php artisan config:cache
php artisan route:cache
# php artisan view:cache # İhtiyaç varsa

echo "Running migrations..."
# --force genellikle production ortamında otomatik onay için kullanılır
php artisan migrate --force || echo "Migration failed or already up-to-date."

# İzinleri ayarla
echo "Setting proper permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Setup completed successfully. Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor.d/supervisord.ini