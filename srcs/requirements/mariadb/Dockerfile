FROM debian:stable

# gosuは、特定のユーザーやグループとしてコマンドを実行する
RUN apt-get update && apt-get install -y mariadb-server gosu && \
    # 不要なAPTキャッシュを削除してイメージのサイズを小さくする
    rm -rf /var/lib/apt/lists/* && \
    # 正しい権限を設定
    # /var/lib/mysqlはデータファイルを格納する
    # /var/run/mysqldソケットファイルを格納する
    mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# ホストマシン上の ./tools ディレクトリをコンテナ内の /docker-entrypoint-initdb.d にコピー
# このディレクトリにあるスクリプト（.sqlファイルや.shファイルなど）は
# コンテナ初回起動時に自動で実行され、データベースの初期化を行う
COPY ./tools /docker-entrypoint-initdb.d

# エントリーポイントスクリプトをコピー
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# MariaDBがリッスンする3306番ポートを開放（他のコンテナやホストから接続可能にする）
EXPOSE 3306

# コンテナ起動時にdocker-entrypoint.shスクリプトを実行
ENTRYPOINT ["docker-entrypoint.sh"]
