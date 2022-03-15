# โหลด baseImage PHP 8.0.3
FROM php:8.0.3-fpm-buster

# ติดตั้ง Extension BCMath และ pdo_mysql สำหรับ Laravel 7,8,9,10
RUN docker-php-ext-install bcmath pdo_mysql

# สั่ง update image และติดตั้ง git zip และ unzip package
RUN apt-get update
RUN apt-get install -y git zip unzip

# ติดตั้ง NodeJS
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - 
RUN apt-get install -y nodejs

# ติดต้ง composer:latest ไว้ที่ /usr/bin/composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# php port
EXPOSE 9000