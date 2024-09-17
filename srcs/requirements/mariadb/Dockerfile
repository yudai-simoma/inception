FROM debian:stable

RUN apt-get update && apt-get install -y mariadb-server && \
    # 不要なAPTキャッシュを削除してイメージのサイズを小さくする
    rm -rf /var/lib/apt/lists/*

# ホストマシン上の ./tools ディレクトリをコンテナ内の /docker-entrypoint-initdb.d にコピー
# このディレクトリにあるスクリプト（.sqlファイルや.shファイルなど）は
# コンテナ初回起動時に自動で実行され、データベースの初期化を行う
COPY ./tools /docker-entrypoint-initdb.d

# MariaDBがリッスンする3306番ポートを開放（他のコンテナやホストから接続可能にする）
EXPOSE 3306

# MariaDBのサーバープロセス（mysqld）をコンテナ起動時に実行
CMD ["mysqld"]
