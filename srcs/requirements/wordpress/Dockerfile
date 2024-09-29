FROM debian:stable

RUN apt-get update && \
    apt-get install -y php8.2-fpm php8.2-mysql curl \
    wget unzip net-tools vim netcat-openbsd default-mysql-client && \
    wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    mv wordpress /usr/src/wordpress && \
    # 不要になったWordPressディレクトリとtarファイルを削除し、APTのキャッシュをクリア
    rm -rf latest.zip && rm -rf /var/lib/apt/lists/* && \
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

RUN sed -i 's#listen = /run/php/php8.2-fpm.sock#listen = 9000#' /etc/php/8.2/fpm/pool.d/www.conf

# wp-config.php をコピー
COPY wp-config.php /usr/src/wordpress/wp-config.php

# エントリーポイントスクリプトをコピー
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# php-fpmのログファイルを作成し、所有者とグループを変更
RUN touch /var/log/php8.2-fpm.log && chown www-data:www-data /var/log/php8.2-fpm.log

# php-fpmがリクエストを受け付けるために、9000番ポートを開放
EXPOSE 9000

# コンテナ起動時にdocker-entrypoint.shスクリプトを実行
ENTRYPOINT ["docker-entrypoint.sh"]
