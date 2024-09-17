FROM debian:stable

# openssl は HTTPS 通信に必要な SSL/TLS 証明書の生成と管理に使用します
RUN apt-get update && apt-get install -y nginx openssl && \
    # インストール後、キャッシュを削除してイメージサイズを削減
    rm -rf /var/lib/apt/lists/*

# ホストマシン上の ./conf ディレクトリの内容を
# コンテナ内の /etc/nginx/conf.d ディレクトリにコピー
# これにより、カスタムの Nginx 設定をコンテナに追加できます
COPY ./conf /etc/nginx/conf.d

# コンテナが 443 ポート（HTTPS）でリッスンすることを Docker に通知
EXPOSE 443

# nginx をフォアグラウンドで実行し、コンテナのメインプロセスとします
CMD ["nginx", "-g", "daemon off;"]