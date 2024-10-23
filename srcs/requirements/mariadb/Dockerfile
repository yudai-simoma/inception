# ベースイメージとしてDebianの安定版を使用
FROM debian:stable

# gosuは、特定のユーザーやグループとしてコマンドを実行する
RUN apt-get update && \
    apt-get install -y mariadb-server gosu net-tools gettext && \
    # 不要なAPTキャッシュを削除してイメージのサイズを小さくする
    rm -rf /var/lib/apt/lists/* \
    rm -rf /var/lib/mysql/*

# ホストマシン上の ./tools ディレクトリをコンテナ内の /docker-entrypoint-initdb.d にコピー
# このディレクトリにあるスクリプト（.sqlファイルや.shファイルなど）はエントリポイントで実行する
COPY ./tools /docker-entrypoint-initdb.d

# エントリーポイントスクリプトをコピー
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# MariaDBがリッスンする3306番ポートを開放（他のコンテナやホストから接続可能にする）
EXPOSE 3306

# コンテナ起動時にdocker-entrypoint.shスクリプトを実行
ENTRYPOINT ["docker-entrypoint.sh"]
