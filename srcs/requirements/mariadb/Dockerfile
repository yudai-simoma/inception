FROM debian:stable

# gosuは、特定のユーザーやグループとしてコマンドを実行する
RUN apt-get update && apt-get install -y mariadb-server gosu && \
    # 不要なAPTキャッシュを削除してイメージのサイズを小さくする
    rm -rf /var/lib/apt/lists/*

# 特定のIDでmysqlユーザーとグループを作成
RUN getent group mysql || groupadd -r mysql --gid=999

# mysqlユーザーが存在するか確認し、存在しない場合は作成
RUN id -u mysql &>/dev/null || useradd -r -g mysql --uid=999 mysql

# 正しい権限を設定
RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

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

# MariaDBのサーバープロセス（mysqld）をコンテナ起動時に実行
CMD ["mysqld"]
