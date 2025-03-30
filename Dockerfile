FROM richarvey/nginx-php-fpm:latest

# Çalışma dizinini ayarla
WORKDIR /var/www/html

# Gerekli dizinleri oluştur
RUN mkdir -p /var/www/html/public \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /run/nginx

# PHP eklentilerini ve gerekli paketleri yükle
RUN apk add --no-cache \
    php81-pdo \
    php81-pdo_mysql \
    php81-pdo_sqlite \
    php81-mbstring \
    php81-xml \
    php81-openssl \
    php81-json \
    php81-tokenizer \
    php81-dom \
    php81-xmlwriter \
    php81-fileinfo \
    php81-session \
    php81-curl \
    php81-zip \
    php81-soap \
    nodejs \
    npm \
    sqlite \
    supervisor

# Proje dosyalarını kopyala
COPY . /var/www/html

# nginx yapılandırması
COPY ./nginx/default.conf /etc/nginx/sites-available/default.conf
RUN ln -sf /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# Dağıtım betiğini kopyala ve çalıştırma izni ver
RUN chmod +x /var/www/html/scripts/start.sh

# İzinleri ayarla
RUN chown -R nginx:nginx /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Publish portları
EXPOSE 80 6001

# Başlatma
CMD ["/var/www/html/scripts/start.sh"] 