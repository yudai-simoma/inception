#!/bin/bash
set -eo pipefail

# MySQLデータディレクトリとソケットディレクトリの準備
mkdir -p /var/lib/mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld

# データディレクトリが空の場合、MariaDBを初期化する
if [ ! -d "/var/lib/mysql/mysql" ]; then
    # 初期化コマンドを実行
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql

    # 一時的な設定ファイルを作成
    cat > /tmp/init.sql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='' OR User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # 一時的なMariaDBサーバーを起動し、初期化SQLを実行
    mysqld --user=mysql --bootstrap --skip-networking=0 < /tmp/init.sql
    rm -f /tmp/init.sql
fi

# /docker-entrypoint-initdb.dディレクトリ内のスクリプトを実行
echo "Executing scripts in /docker-entrypoint-initdb.d..."
for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
        *.sh)
            echo "$0: running $f"
            . "$f"
            ;;
        *.sql)
            echo "$0: running $f"
            mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" < "$f"
            ;;
        *.sql.gz)
            echo "$0: running $f"
            gunzip -c "$f" | mysql -uroot -p"${MYSQL_ROOT_PASSWORD}"
            ;;
        *)
            echo "$0: ignoring $f"
            ;;
    esac
    echo
done

# MySQLサーバーを実行
exec mysqld --user=mysql --console
