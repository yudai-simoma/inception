#!/bin/bash

# - エラーが発生したらすぐに停止 (set -e)
# - 宣言されていない変数の使用を禁止 (set -u)
# - パイプラインでエラーが発生した場合も全体を失敗とする (set -o pipefail)
set -eo pipefail

echo "MariaDB エントリーポイントスクリプトを開始します"
echo "Host: ${WORDPRESS_DB_HOST}"
echo "User: ${WORDPRESS_DB_USER}"
echo "Database: ${WORDPRESS_DB_NAME}"

# MariaDB設定ファイルのパス
CONFIG_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"

# bind-addressを0.0.0.0に変更
echo "bind-addressを0.0.0.0に変更します"
sed -i "s/^bind-address\s*=.*$/bind-address = 0.0.0.0/" "$CONFIG_FILE"

# ボリュームマウントを考慮して、必要な場合のみ権限を再設定
echo "/var/lib/mysql の権限をチェックおよび設定します"
if [ "$(stat -c %U:%G /var/lib/mysql)" != "mysql:mysql" ]; then
    echo "/var/lib/mysql の所有権を mysql:mysql に変更します"
    chown -R mysql:mysql /var/lib/mysql
fi

# 取得した所有者とグループが "mysql:mysql" と一致するかどうか
echo "/run/mysqld の権限をチェックおよび設定します"
if [ ! -d "/run/mysqld" ] || [ "$(stat -c %U:%G /run/mysqld)" != "mysql:mysql" ]; then
    echo "/run/mysqld を作成し、権限を設定します"
    mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld
    chmod 755 /run/mysqld
fi

# データディレクトリが空の場合、MariaDBを初期化する
if [ ! -d "/var/lib/mysql/mysql" ]; then
    # データベースシステムファイルの初期化
    echo "MariaDBデータベースを初期化します"
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    echo "データベースの初期化が完了しました"

    # 初期設定を適用するためのサーバー環境を提供
    echo "一時的なMariaDBサーバーを起動します"
    mysqld_safe --skip-networking --datadir=/var/lib/mysql &
    pid="$!"

    # MySQLクライアントを実行するためのコマンドライン引数
    mysql=( mysql --protocol=socket -uroot )

    # サーバーが接続を受け付けられる状態になっているかをチェック
    echo "MariaDBが利用可能になるのを待機しています"
    for i in {1..300}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
            echo "MariaDBが利用可能になりました"
            break
        fi
        echo "MySQL初期化プロセス実行中... ($i/300)" # ここも300に修正
        sleep 1
    done

    if [ "$i" -eq 300 ]; then
        echo >&2 'MySQL初期化プロセスに失敗しました。'
        echo >&2 'サーバーログを確認してください:'
        if [ -f "/var/log/mysql/error.log" ]; then
            cat >&2 /var/log/mysql/error.log
        else
            echo >&2 "エラーログファイルが見つかりません。"
            echo >&2 "以下のコマンドでログを確認してください: journalctl -xe"
        fi
        exit 1
    fi

    # 1.不要なユーザーの削除
    # 2.rootパスワードの設定
    # 3.新しいデータベースとユーザーの作成
    # 4.権限の設定
    echo "MariaDBを設定しています"
    "${mysql[@]}" <<-EOSQL
        SET @@SESSION.SQL_LOG_BIN=0;
        DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost');
        SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}');
        GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

         # ここでwp_db_userを作成し、権限を付与する
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

        FLUSH PRIVILEGES;
EOSQL
    echo "MariaDBの設定が完了しました"

    # /docker-entrypoint-initdb.dディレクトリ内のスクリプトを実行
    echo "初期化スクリプトを実行しています..."
    for f in /docker-entrypoint-initdb.d/*; do
        case "$f" in
            *.sql)
                echo "SQLスクリプトを実行中: $f"
                if "${mysql[@]}" < "$f"; then
                    echo "SQLスクリプト $f の実行に成功しました"
                else
                    echo "エラー: SQLスクリプト $f の実行に失敗しました"
                fi
                ;;
        esac
        echo
    done
    echo "初期化スクリプトの実行が完了しました"

    echo "一時的なMariaDBサーバーを停止します"
    if ! mysqladmin -uroot shutdown; then
        echo >&2 'MariaDBサーバーの停止に失敗しました'
        exit 1
    fi

    echo "サーバーの停止を待機しています"
    wait "$pid"
else
    echo "MariaDBデータベースは既に初期化されています。初期化をスキップします"
fi

echo "MariaDBサーバーを起動します"
exec mysqld --user=mysql --console
