# ベースイメージとしてDebianの安定版を使用
FROM debian:stable

# openssl は HTTPS 通信に必要な SSL/TLS 証明書の生成と管理に使用します
RUN apt-get update && \
    apt-get install -y nginx openssl vim && \
    # インストール後、キャッシュを削除してイメージサイズを削減
    rm -rf /var/lib/apt/lists/*

# ホストマシン上の ./conf ディレクトリの内容を
# コンテナ内の /etc/nginx/conf.d ディレクトリにコピー
# これにより、カスタムの Nginx 設定をコンテナに追加できます
COPY ./conf /etc/nginx/conf.d

# SSL証明書と秘密鍵を生成するスクリプトを作成
RUN mkdir -p /etc/nginx/conf.d/ssl && \
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/nginx/conf.d/ssl/nginx.key \
-out /etc/nginx/conf.d/ssl/nginx.crt \
-subj "/C=JP/ST=Tokyo/L=Tokyo/O=MyCompany/OU=IT/CN=localhost"

# コンテナが 443 ポート（HTTPS）でリッスンすることを Docker に通知
EXPOSE 443

# -g: Nginxの設定をコマンドラインから直接指定するオプション。
# daemon off;: Nginxをフォアグラウンドで動作させる設定
CMD ["nginx", "-g", "daemon off;"]
