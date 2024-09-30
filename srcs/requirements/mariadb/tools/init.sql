-- 管理者ユーザーや一般ユーザーの設定の前に追加
SET @@SESSION.SQL_LOG_BIN=0;
DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost');
SET PASSWORD FOR 'root'@'localhost'=PASSWORD("root_password");
GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

-- WordPress用データベースの作成
CREATE DATABASE IF NOT EXISTS wordpress;
USE wordpress;

-- WordPress アプリケーション用のデータベースユーザーを作成
-- '%'はあらゆるホストからのアクセスを許可することを意味する
CREATE USER IF NOT EXISTS "wp_db_user"@"%" IDENTIFIED BY "wp_password";
-- 作成したユーザーに、WordPress用データベースへのすべての権限を付与
GRANT ALL PRIVILEGES ON wordpress.* TO "wp_db_user"@"%";
-- 権限の変更を即座に反映させます
FLUSH PRIVILEGES;
