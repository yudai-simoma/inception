#!/bin/bash

# - エラーが発生したらすぐに停止 (set -e)
# - 宣言されていない変数の使用を禁止 (set -u)
# - パイプラインでエラーが発生した場合も全体を失敗とする (set -o pipefail)
set -eo pipefail

# MariaDB設定ファイルのパス
CONFIG_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"

# bind-addressを0.0.0.0に変更
echo "bind-addressを0.0.0.0に変更します"
sed -i "s/^bind-address\s*=.*$/bind-address = 0.0.0.0/" "$CONFIG_FILE"

# ディレクトリの権限を設定
# /var/lib/mysqlはデータファイルを格納する
# /run/mysqldソケットファイルを格納する
echo "/var/lib/mysql と /run/mysqld の権限をチェックおよび設定します"
mkdir -p /var/lib/mysql /run/mysqld /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld /var/run/mysqld
chmod 755 /run/mysqld /var/run/mysqld

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

    # /docker-entrypoint-initdb.dディレクトリ内のスクリプトを実行
    echo "初期化スクリプトを実行しています..."
    # SQLファイルに環境変数を置換して適用
    envsubst < /docker-entrypoint-initdb.d/init-template.sql > /docker-entrypoint-initdb.d/init.sql
    # 置換したSQLスクリプトを実行
    echo "SQLスクリプトを実行中: /docker-entrypoint-initdb.d/init.sql"
    if "${mysql[@]}" < /docker-entrypoint-initdb.d/init.sql; then
        echo "SQLスクリプト /docker-entrypoint-initdb.d/init.sql の実行に成功しました"
    else
        echo "エラー: SQLスクリプト /docker-entrypoint-initdb.d/init.sql の実行に失敗しました"
    fi
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
