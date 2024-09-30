#!/bin/bash

set -euo pipefail

# WordPressのソースファイルが存在するか確認
echo "WordPressのソースファイルを確認しています..."
if [ ! -d "/usr/src/wordpress" ]; then
    echo "エラー: /usr/src/wordpressにWordPressのソースファイルが見つかりません"
    exit 1
fi

# /var/www/htmlディレクトリが存在しない場合は作成
if [ ! -d "/var/www/html" ]; then
    echo "/var/www/htmlディレクトリを作成しています..."
    mkdir -p /var/www/html
    chown www-data:www-data /var/www/html
fi

# wp-config.phpが存在しない場合、WordPressファイルをコピー
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPressファイルを/var/www/htmlにコピーしています..."
    cp -r /usr/src/wordpress/* /var/www/html/
    echo "パーミッションを設定しています..."
    chown -R www-data:www-data /var/www/html
else
    echo "WordPressファイルは既に存在します。コピーをスキップします。"
fi

# MariaDBの接続準備を待つ (データベースホストに接続可能か確認)
echo "データベース接続を待機しています $WORDPRESS_DB_HOST:3306..."
while ! nc -z -v -w30 "$WORDPRESS_DB_HOST" 3306; do
  echo "データベース接続を待機しています..."
  sleep 5
done

# MariaDBが起動するまで待機（最大5分）
counter=0
max_attempts=300  # 5分間待機
echo "MariaDBの準備が整うのを待っています..."
while ! mysql -h"${WORDPRESS_DB_HOST}" -u"${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
    counter=$((counter + 1))
    echo "MariaDBの準備が整うのを待っています... ${counter}秒経過"
    if [ $counter -ge $max_attempts ]; then
        echo "エラー: MariaDBが指定時間内に準備完了しませんでした"
        exit 1
    fi
done

# WordPressがインストールされていない場合はインストール
if ! wp core is-installed --path=/var/www/html --allow-root; then
    echo "WordPressをインストールしています..."
    # WordPressのインストール処理
    wp core install --path=/var/www/html \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email --allow-root
    echo "WordPressのインストールが完了しました。"
    
    # 一般ユーザーの追加
    echo "一般ユーザー 'wp_user1' を追加しています..."
    wp user create wp_user1 user@example.com \
        --role=subscriber \
        --user_pass=user1_password \
        --display_name="Normal User1" \
        --path=/var/www/html \
        --allow-root
    echo "一般ユーザー 'wp_user1' の追加が完了しました。"
else
    echo "WordPressは既にインストールされています。インストールをスキップします。"
fi

# MariaDBが準備できたら、PHP-FPMを起動
echo "MariaDBの準備が整いました。PHP-FPMを起動しています..."
exec php-fpm8.2 -F
