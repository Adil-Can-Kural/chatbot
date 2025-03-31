#!/bin/bash

# Hata ayıklama için
set -e

echo "Building Laravel application for Render.com deployment..."

# Gerekli dizinleri oluştur
mkdir -p storage/logs
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/framework/cache
mkdir -p bootstrap/cache

# Composer cache dizinlerini oluştur
echo "Creating Composer cache directories..."
mkdir -p ~/.composer/cache/vcs
mkdir -p ~/.composer/cache/repo
chmod -R 777 ~/.composer

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

# Gerekli dizinleri ve dosyaları kontrol et
echo "Checking for required directories and files..."
if [ ! -d "vendor" ]; then
    echo "ERROR: vendor directory doesn't exist!"
    exit 1
fi

if [ ! -f "vendor/autoload.php" ]; then
    echo "ERROR: vendor/autoload.php doesn't exist!"
    exit 1
fi

# Storage ve bootstrap/cache dizinleri için izinleri ayarla
echo "Setting directory permissions..."
chmod -R 777 storage
chmod -R 777 bootstrap/cache

# nginx ve supervisor dizinlerini oluştur
mkdir -p /run/nginx
mkdir -p /var/log/supervisor
mkdir -p /var/log/nginx
chmod -R 777 /run/nginx
chmod -R 777 /var/log/supervisor
chmod -R 777 /var/log/nginx

# Laravel cache'i temizle
echo "Clearing Laravel cache..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

echo "Build completed successfully!" 