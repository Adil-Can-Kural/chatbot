FROM richarvey/nginx-php-fpm:latest

COPY . /var/www/html
WORKDIR /var/www/html

# İzinleri ayarla
RUN chown -R nginx:nginx /var/www/html

# PHP eklentilerini ve gerekli paketleri yükle
RUN apk add --no-cache \
    php81-pdo \
    php81-pdo_mysql \
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
    supervisor

# nginx yapılandırması
COPY ./nginx/default.conf /etc/nginx/sites-available/default.conf

# Dağıtım betiğini kopyala ve çalıştırma izni ver
COPY ./scripts/start.sh /var/www/html/scripts/start.sh
RUN chmod +x /var/www/html/scripts/start.sh

# Başlatma
CMD ["/var/www/html/scripts/start.sh"] 