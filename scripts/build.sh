#!/bin/bash

# Hata ayıklama için
set -e

echo "Building Laravel application for Render.com deployment..."

# Composer bağımlılıklarını kur
echo "Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader

# NPM paketlerini yükle ve derle
if [ -f package.json ]; then
    echo "Installing and building NPM packages..."
    npm ci --quiet
    npm run build
fi

# Storage ve bootstrap/cache dizinleri için izinleri ayarla
echo "Setting directory permissions..."
chmod -R 775 storage bootstrap/cache

echo "Build completed successfully!" 