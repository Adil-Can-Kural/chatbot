#!/bin/bash

# Hata ayıklama için
set -e
echo "Starting Laravel application setup..."

# Container içinde beklenen dizinleri oluştur
mkdir -p /run/nginx
mkdir -p /var/log/supervisor
mkdir -p /var/log/nginx

# Composer bağımlılıklarını kur
echo "Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader

# .env dosyası yoksa, örnek dosyadan kopyala
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
fi

# Uygulama anahtarı oluştur
echo "Generating application key..."
php artisan key:generate --force

# Yapılandırma önbelleğini temizle ve yeniden oluştur
echo "Clearing and caching configuration..."
php artisan config:clear
php artisan config:cache

# Rota önbelleğini temizle ve yeniden oluştur
echo "Clearing and caching routes..."
php artisan route:clear
php artisan route:cache

# Gerekli izinleri ver
echo "Setting directory permissions..."
chmod -R 775 storage bootstrap/cache
chown -R nginx:nginx storage bootstrap/cache

# PostgreSQL veritabanı için migrationları çalıştır
echo "Running migrations..."
php artisan migrate --force

# Migration sorunlarını çözmek için manuel yöntem kullan (ihtiyaç duyulursa)
echo "Running migrations with conflict resolution if needed..."

# Migrationları çalıştır ama problemi çözecek şekilde
cat > /tmp/fix_migrations.php << 'EOF'
<?php
require_once __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Schema\Blueprint;

// Temel tabloları oluştur
$migrations = glob(__DIR__ . '/database/migrations/*.php');
usort($migrations, function($a, $b) {
    return basename($a) <=> basename($b);
});

// 2025_03_10_202007 ile başlayan migrationları atla
$filtered = array_filter($migrations, function($path) {
    return !str_contains(basename($path), '2025_03_10_202007');
});

// Migrationların durumunu kontrol et, eğer başarısız olmuşsa manuel olarak çalıştır
try {
    $tables = DB::select('SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = \'public\'');
    if (count($tables) < 5) { // Ana tablolar oluşturulmamışsa
        echo "Tables not created properly, running manual migrations...\n";
        
        foreach ($filtered as $file) {
            $migration = basename($file, '.php');
            echo "Running migration: $migration\n";
            $class = require $file;
            $class->up();
            
            // Migration kaydını ekle
            if (!str_contains($migration, '2025_03_10_202007')) {
                DB::table('migrations')->insert([
                    'migration' => $migration,
                    'batch' => 1
                ]);
            }
        }
        echo "Manual migrations completed successfully\n";
    } else {
        echo "Tables already created, skipping manual migrations\n";
    }
} catch (\Exception $e) {
    echo "Error checking tables: " . $e->getMessage() . "\n";
}
EOF

php /tmp/fix_migrations.php
echo "Migration process completed."

# NPM paketlerini yükle ve derle (eğer gerekliyse)
if [ -f package.json ]; then
    echo "Installing and building NPM packages..."
    npm ci --quiet
    npm run build
fi

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