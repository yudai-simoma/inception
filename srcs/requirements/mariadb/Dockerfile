FROM debian:stable

RUN apt-get update && apt-get install -y mariadb-server gosu && \
    # 不要なAPTキャッシュを削除してイメージのサイズを小さくする
    rm -rf /var/lib/apt/lists/*

# Create mysql user and group with specific IDs
RUN getent group mysql || groupadd -r mysql --gid=999

# Check if mysql user exists, if not create it
RUN id -u mysql &>/dev/null || useradd -r -g mysql --uid=999 mysql

# Set correct permissions
RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# ホストマシン上の ./tools ディレクトリをコンテナ内の /docker-entrypoint-initdb.d にコピー
# このディレクトリにあるスクリプト（.sqlファイルや.shファイルなど）は
# コンテナ初回起動時に自動で実行され、データベースの初期化を行う
COPY ./tools /docker-entrypoint-initdb.d

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# MariaDBがリッスンする3306番ポートを開放（他のコンテナやホストから接続可能にする）
EXPOSE 3306

ENTRYPOINT ["docker-entrypoint.sh"]

# MariaDBのサーバープロセス（mysqld）をコンテナ起動時に実行
CMD ["mysqld"]
