#!/bin/bash

# Hata ayıklama için
set -e

echo "Building Laravel application for Render.com deployment..."

# Composer bağımlılıklarını kur
echo "Installing Composer dependencies..."
COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Composer cache'i temizle
echo "Clearing Composer cache..."
composer clear-cache

# Composer autoload dosyalarını optimize et
echo "Optimizing Composer autoloader..."
composer dump-autoload --optimize --no-dev

# NPM paketlerini yükle ve derle
if [ -f package.json ]; then
    echo "Installing and building NPM packages..."
    npm ci --quiet
    npm run build
fi

# Storage ve bootstrap/cache dizinleri için izinleri ayarla
echo "Setting directory permissions..."
chmod -R 775 storage bootstrap/cache

# Laravel cache'i temizle
echo "Clearing Laravel cache..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

echo "Build completed successfully!" 