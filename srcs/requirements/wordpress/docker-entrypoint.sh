#!/bin/bash

set -euo pipefail

echo "Checking for WordPress source files..."
if [ ! -d "/usr/src/wordpress" ]; then
    echo "Error: WordPress source files not found in /usr/src/wordpress"
    exit 1
fi

# /var/www/htmlが存在しない場合は作成
if [ ! -d "/var/www/html" ]; then
    echo "Creating /var/www/html directory..."
    mkdir -p /var/www/html
    chown www-data:www-data /var/www/html
fi

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Copying WordPress files to /var/www/html..."
    cp -r /usr/src/wordpress/* /var/www/html/
    echo "Setting permissions..."
    chown -R www-data:www-data /var/www/html
else
    echo "WordPress files already exist. Skipping copy."
fi

# ネットワークの準備を待つ
until nc -z -v -w30 $WORDPRESS_DB_HOST 3306
do
  echo "Waiting for database connection..."
  sleep 5
done

# MariaDBが起動するまで待機
counter=0
max_attempts=600  # 10分間待機
while ! mysql -h"${WORDPRESS_DB_HOST}" -u"${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
    counter=$((counter + 1))
    echo "Waiting for MariaDB to be ready... ${counter}s elapsed"
    if [ $counter -ge $max_attempts ]; then
        echo "Error: MariaDB did not become ready in time"
        exit 1
    fi
done

# WordPressがインストールされていない場合はインストール
if ! wp core is-installed --path=/var/www/html --allow-root; then
    echo "Installing WordPress..."
    wp core install --path=/var/www/html --url="https://yshimoma.42.fr" --title="yshimomaInceptionSite" --admin_user="yshimoma" --admin_password="ysimoma_password" --admin_email="admin@example.com" --skip-email --allow-root
fi

echo "MariaDB is ready. Starting PHP-FPM..."
exec php-fpm8.2 -F
