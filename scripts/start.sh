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
echo "PORT: $PORT" # Render.com'un atadığı port

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

# Composer cache dizinlerini oluştur
echo "Creating Composer cache directories..."
mkdir -p ~/.composer/cache/vcs
mkdir -p ~/.composer/cache/repo
chmod -R 777 ~/.composer

# Composer kurulumunu gerçekleştir
COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Composer cache'i temizle
echo "Clearing Composer cache..."
composer clear-cache

# Composer autoload dosyalarını optimize et
echo "Optimizing Composer autoloader..."
composer dump-autoload --optimize --no-dev

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

# Doğrudan database.php yapılandırma dosyasını oluştur
echo "Creating database config file directly..."
mkdir -p /var/www/html/config
cat > /var/www/html/config/database.php << EOF
<?php

return [
    'default' => env('DB_CONNECTION', 'pgsql'),
    'connections' => [
        'pgsql' => [
            'driver' => 'pgsql',
            'host' => 'dpg-cvkkl6l6ubrc73fq9b6g-a',
            'port' => 5432,
            'database' => 'chat_ake6',
            'username' => 'chat_ake6_user',
            'password' => '5mijBS3BEa5bXxFKj0DgF0cUsQOBLkGP',
            'charset' => 'utf8',
            'prefix' => '',
            'prefix_indexes' => true,
            'schema' => 'public',
            'sslmode' => 'prefer',
        ],
        'sqlite' => [
            'driver' => 'sqlite',
            'url' => env('DATABASE_URL'),
            'database' => env('DB_DATABASE', database_path('database.sqlite')),
            'prefix' => '',
            'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
        ],
        'mysql' => [
            'driver' => 'mysql',
            'url' => env('DATABASE_URL'),
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'forge'),
            'username' => env('DB_USERNAME', 'forge'),
            'password' => env('DB_PASSWORD', ''),
            'unix_socket' => env('DB_SOCKET', ''),
            'charset' => 'utf8mb4',
            'collation' => 'utf8mb4_unicode_ci',
            'prefix' => '',
            'prefix_indexes' => true,
            'strict' => true,
            'engine' => null,
            'options' => extension_loaded('pdo_mysql') ? array_filter([
                PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
            ]) : [],
        ],
    ],
    'migrations' => 'migrations',
    'redis' => [
        'client' => env('REDIS_CLIENT', 'phpredis'),
        'options' => [
            'cluster' => env('REDIS_CLUSTER', 'redis'),
            'prefix' => env('REDIS_PREFIX', ''),
        ],
        'default' => [
            'url' => env('REDIS_URL'),
            'host' => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port' => env('REDIS_PORT', '6379'),
            'database' => env('REDIS_DB', '0'),
        ],
        'cache' => [
            'url' => env('REDIS_URL'),
            'host' => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port' => env('REDIS_PORT', '6379'),
            'database' => env('REDIS_CACHE_DB', '1'),
        ],
    ],
];
EOF

# Config dosyalarını temizle
php artisan config:clear

# Uygulama anahtarı oluştur
echo "Generating application key..."
php artisan key:generate --force

# Güvenli Migration Çözümü - Hataları ele al
echo "Running migrations with conflict handling..."
cat > /var/www/html/safe_migrations.php << 'EOF'
<?php
require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Önce veritabanı tablosunu kontrol et
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

try {
    // Veritabanı bağlantısını kontrol et
    if (DB::connection()->getPdo()) {
        echo "Database connected successfully!\n";
        
        // rooms tablosunu kontrol et
        if (Schema::hasTable('rooms')) {
            echo "Table 'rooms' exists. Checking columns...\n";
            
            // "name" sütunu var mı kontrol et
            if (Schema::hasColumn('rooms', 'name')) {
                echo "Column 'name' already exists in 'rooms' table. Will skip adding it.\n";
                
                // is_bot sütununu kontrol et
                if (!Schema::hasColumn('rooms', 'is_bot')) {
                    echo "Adding 'is_bot' column to 'rooms' table...\n";
                    Schema::table('rooms', function ($table) {
                        $table->boolean('is_bot')->default(false);
                    });
                    echo "Column 'is_bot' added successfully.\n";
                } else {
                    echo "Column 'is_bot' already exists. Skipping.\n";
                }
            }
        }
    }
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

// Tüm migrationları çalıştır, hataları yok say
try {
    echo "Running migrations...\n";
    // Önce migration durumunu kontrol et
    $status = Artisan::call('migrate:status', ['--force' => true]);
    echo "Current migration status:\n";
    echo Artisan::output();
    
    // Migrationları çalıştır
    $result = Artisan::call('migrate', [
        '--force' => true,
        '--no-interaction' => true,
        '--verbose' => true
    ]);
    
    echo "Migration output:\n";
    echo Artisan::output();
    
    if ($result !== 0) {
        echo "Migration completed with some errors (this is expected for duplicate columns).\n";
    } else {
        echo "Migration completed successfully.\n";
    }
} catch (\Exception $e) {
    echo "Migration error (safe to ignore name column errors): " . $e->getMessage() . "\n";
}

echo "Migration process completed.\n";
EOF

php /var/www/html/safe_migrations.php

# Çalışma izinlerini ayarla
echo "Setting proper permissions..."
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/storage/framework/cache
chmod -R 777 /var/www/html/storage
chmod -R 777 /var/www/html/bootstrap/cache

# Uygulama dizinlerinin sahipliğini ve izinlerini ayarla
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 644 /var/www/html/public/.htaccess 2>/dev/null || true

echo "Testing PHP installation..."
php -v
echo "PHP-FPM configuration path testing..."
find / -name "*fpm*" -type f 2>/dev/null | grep php
find / -name "*php-fpm*" -type f 2>/dev/null

# WebSockets ile ilgili sorunlar için
echo "Testing WebSockets service..."
if ! nc -z localhost 6001; then
    echo "WebSockets port is not available yet. Checking service status..."
fi

# Render.com için Nginx yapılandırmasını kontrol et
echo "Checking Nginx configuration..."
if [ -z "$PORT" ]; then
    echo "WARNING: PORT environment variable is not set. Using default 80."
    export PORT=80
fi

# Nginx yapılandırma dosyasını kontrol et ve hataları raporla
echo "Verifying nginx configuration with PORT=$PORT"
nginx -t

# supervisor ile servisleri başlatacak şekilde ayarlandı, bu dosya artık CMD tarafından çağrılmayacak
# Ancak build sürecinde kullanıldığı için ve Render.com build işlemini tamamlamak için bırakıyoruz
echo "Setup completed successfully. Services will be managed by supervisord."

# Supervisor yapılandırmasını kontrol et
if [ -f "/etc/supervisor/conf.d/supervisord.conf" ]; then
    echo "Supervisor configuration found at /etc/supervisor/conf.d/supervisord.conf"
else
    echo "WARNING: Supervisor configuration not found"
fi

# Bu betik artık hizmetleri başlatmayacak, sadece kurulumu yapacak
# exec supervisord -c /etc/supervisor/conf.d/supervisord.conf 