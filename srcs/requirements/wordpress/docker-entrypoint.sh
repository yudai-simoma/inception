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

# PHP-FPMを起動
exec php-fpm8.2 -F
