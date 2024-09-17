FROM debian:stable

RUN apt-get update && apt-get install -y php8.2-fpm php8.2-mysql wget unzip && \
    wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    mkdir -p /var/www/html && \
    cp -r wordpress/. /var/www/html/ && \
    # WordPressファイルの所有者とグループを www-data に変更（Webサーバー用ユーザー）
    chown -R www-data:www-data /var/www/html/ && \
    # 不要になったWordPressディレクトリとtarファイルを削除し、APTのキャッシュをクリア
    rm -rf wordpress latest.zip && rm -rf /var/lib/apt/lists/*

# wp-config.php をコピー
COPY wp-config.php /var/www/html/

# wp-config.php の所有者とグループを www-data に変更
RUN chown www-data:www-data /var/www/html/wp-config.php

# php-fpmがリクエストを受け付けるために、9000番ポートを開放
EXPOSE 9000

# php-fpmを起動してFastCGIリクエストを処理
CMD ["php-fpm8.2"]
