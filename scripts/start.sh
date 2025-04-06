#!/bin/bash
set -e
echo "Starting Laravel application setup..."

mkdir -p /run/nginx /var/log/supervisor /var/log/nginx

echo "Environment variables (Check if Render injected them):"
printenv | grep DB_ # Veya ilgili değişkenler
printenv | grep PUSHER_ # Veya ilgili değişkenler
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

# Render Ortam Değişkenlerini .env dosyasına yaz
echo "Updating .env with Render environment variables..."
echo "DB_HOST from env var: [${DB_HOST}]" # Debug için eklendi

# Bireysel DB_* değişkenlerini .env dosyasına yaz
# Render'ın bu değişkenleri sağladığından emin olun!
sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=${DB_CONNECTION:-pgsql}|g" .env
sed -i "s|^DB_HOST=.*|DB_HOST=${DB_HOST}|g" .env
sed -i "s|^DB_PORT=.*|DB_PORT=${DB_PORT:-5432}|g" .env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_DATABASE}|g" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USERNAME}|g" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|g" .env

# Pusher değişkenlerini de güncelle
sed -i "s|^PUSHER_APP_ID=.*|PUSHER_APP_ID=${PUSHER_APP_ID}|g" .env
sed -i "s|^PUSHER_APP_KEY=.*|PUSHER_APP_KEY=${PUSHER_APP_KEY}|g" .env
sed -i "s|^PUSHER_APP_SECRET=.*|PUSHER_APP_SECRET=${PUSHER_APP_SECRET}|g" .env
sed -i "s|^PUSHER_HOST=.*|PUSHER_HOST=${PUSHER_HOST}|g" .env
sed -i "s|^PUSHER_PORT=.*|PUSHER_PORT=${PUSHER_PORT:-443}|g" .env
sed -i "s|^PUSHER_SCHEME=.*|PUSHER_SCHEME=${PUSHER_SCHEME:-https}|g" .env

# APP_URL gibi diğer önemli değişkenler
sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|g" .env
sed -i "s|^APP_ENV=.*|APP_ENV=${APP_ENV:-production}|g" .env
sed -i "s|^APP_DEBUG=.*|APP_DEBUG=${APP_DEBUG:-false}|g" .env

# Uygulama anahtarı yoksa veya boşsa oluştur (varsa dokunma)
if ! grep -q "^APP_KEY=.\+" .env; then
    echo "Generating application key as it was empty..."
php artisan key:generate --force
fi

# Önce paketleri keşfet
echo "Discovering packages..."
php artisan package:discover --ansi

# Sonra tüm cache'leri temizle
echo "Clearing all caches..."
php artisan optimize:clear
# php artisan cache:clear # optimize:clear bunu zaten yapmalı
# php artisan config:clear # optimize:clear bunu zaten yapmalı
# php artisan route:clear # optimize:clear bunu zaten yapmalı
# php artisan view:clear # optimize:clear bunu zaten yapmalı

# Gerekli cache'leri yeniden oluştur
echo "Generating caches..."
php artisan config:cache
php artisan route:cache
# php artisan view:cache # İhtiyaç duyulursa

# Migration'dan önce DNS çözümlemesini test et
echo "Testing DNS resolution for DB_HOST: [${DB_HOST}]"
nslookup ${DB_HOST} || echo "DNS lookup failed for DB_HOST!"
sleep 2 # Kısa bir ek bekleme

echo "Running migrations..."
# --force genellikle production ortamında otomatik onay için kullanılır
php artisan migrate --force || echo "Migration failed or already up-to-date."

# İzinleri ayarla
echo "Setting proper permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Setup completed successfully. Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor.d/supervisord.ini