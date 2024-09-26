#!/bin/bash

# - エラーが発生したらすぐに停止 (set -e)
# - 宣言されていない変数の使用を禁止 (set -u)
# - パイプラインでエラーが発生した場合も全体を失敗とする (set -o pipefail)
set -eo pipefail

# ボリュームマウントを考慮して、必要な場合のみ権限を再設定
if [ "$(stat -c %U:%G /var/lib/mysql)" != "mysql:mysql" ]; then
    chown -R mysql:mysql /var/lib/mysql
fi

# 取得した所有者とグループが "mysql:mysql" と一致するかどうか
if [ "$(stat -c %U:%G /run/mysqld)" != "mysql:mysql" ]; then
    mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld
    chmod 755 /run/mysqld
fi

# データディレクトリが空の場合、MariaDBを初期化する
if [ ! -d "/var/lib/mysql/mysql" ]; then
    # データベースシステムファイルの初期化
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # 初期設定を適用するためのサーバー環境を提供
    mysqld --user=mysql --skip-networking &
    pid="$!"

    # MySQLクライアントを実行するためのコマンドライン引数
    mysql=( mysql --protocol=socket -uroot )

    # サーバーが完全に起動し、接続可能になるまで待機
    for i in {30..0}; do
        # サーバーが接続を受け付けられる状態になっているかをチェック
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
            break
        fi
        echo 'MySQL init process in progress...'
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi

    # 1.不要なユーザーの削除
    # 2.rootパスワードの設定
    # 3.新しいデータベースとユーザーの作成
    # 4.権限の設定
    "${mysql[@]}" <<-EOSQL
        SET @@SESSION.SQL_LOG_BIN=0;
        DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost');
        SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}');
        GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
        CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        GRANT ALL ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    # /docker-entrypoint-initdb.dディレクトリ内のスクリプトを実行
    for f in /docker-entrypoint-initdb.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
            *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
            *)        echo "$0: ignoring $f" ;;
        esac
        echo
    done

    # 一時的なサーバーを停止
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi
fi

# MySQLサーバーを実行
exec mysqld --user=mysql --console
