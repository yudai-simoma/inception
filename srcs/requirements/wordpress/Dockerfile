# ベースイメージとしてDebianの安定版を使用
FROM debian:stable

# 必要なパッケージをインストールし、WordPressとwp-cliをセットアップ
RUN apt-get update && \
    apt-get install -y php8.2-fpm php8.2-mysql curl wget unzip \
                       net-tools vim netcat-openbsd default-mysql-client && \
    # WordPressをダウンロードして展開
    wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    mv wordpress /usr/src/wordpress && \
    rm latest.zip && \
    # APTキャッシュのクリアでイメージサイズを削減
    rm -rf /var/lib/apt/lists/* && \
    # wp-cliのインストール
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# php-fpmのソケットをTCPポート9000に変更（WordPressと通信するため）
RUN sed -i 's#listen = /run/php/php8.2-fpm.sock#listen = 9000#' /etc/php/8.2/fpm/pool.d/www.conf

# WordPressの設定ファイルをコンテナにコピー
COPY wp-config.php /usr/src/wordpress/wp-config.php

# エントリーポイントスクリプトをコンテナにコピーし、実行権限を付与
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# php-fpmのログファイルを作成し、所有権を変更
RUN touch /var/log/php8.2-fpm.log && \
    chown www-data:www-data /var/log/php8.2-fpm.log

# php-fpmのポート9000を外部からのアクセスに開放
EXPOSE 9000

# コンテナ起動時にエントリーポイントスクリプトを実行
ENTRYPOINT ["docker-entrypoint.sh"]
