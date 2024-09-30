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

-- WordPress用データベースの作成
CREATE DATABASE IF NOT EXISTS wordpress_db;
-- 作成したデータベースを使用するように指定
USE wordpress_db;

-- WordPress アプリケーション用のデータベースユーザーを作成
-- '%'はあらゆるホストからのアクセスを許可することを意味する
CREATE USER IF NOT EXISTS "wp_db_user"@"%" IDENTIFIED BY "wp_password";
-- 作成したユーザーに、WordPress用データベースへのすべての権限を付与
GRANT ALL PRIVILEGES ON wordpress_db.* TO "wp_db_user"@"%";
-- 権限の変更を即座に反映させます
FLUSH PRIVILEGES;

-- テーブルが存在しない場合のみ、wp_users テーブルを作成
CREATE TABLE IF NOT EXISTS wp_users (
  ID bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  user_login varchar(60) NOT NULL DEFAULT '',
  user_pass varchar(255) NOT NULL DEFAULT '',
  user_nicename varchar(50) NOT NULL DEFAULT '',
  user_email varchar(100) NOT NULL DEFAULT '',
  user_url varchar(100) NOT NULL DEFAULT '',
  user_registered datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  user_activation_key varchar(255) NOT NULL DEFAULT '',
  user_status int(11) NOT NULL DEFAULT '0',
  display_name varchar(250) NOT NULL DEFAULT '',
  PRIMARY KEY  (ID),
  KEY user_login_key (user_login),
  KEY user_nicename (user_nicename),
  KEY user_email (user_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- wp_usermeta テーブルを作成 (存在しない場合のみ)
CREATE TABLE IF NOT EXISTS wp_usermeta (
  umeta_id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  user_id bigint(20) unsigned NOT NULL DEFAULT '0',
  meta_key varchar(255) DEFAULT NULL,
  meta_value longtext,
  PRIMARY KEY  (umeta_id),
  KEY user_id (user_id),
  KEY meta_key (meta_key(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- WordPress管理者ユーザーの作成
-- user_passはMD5でハッシュ化されたパスワード
INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_registered, user_status, display_name)
VALUES ('yshimoma', MD5('yshimoma_password'), 'admin_user', 'admin@example.com', NOW(), 0, 'yshimoma')
ON DUPLICATE KEY UPDATE user_login=VALUES(user_login);

-- 作成した管理者ユーザーに管理者権限を付与
-- LAST_INSERT_ID()は直前のINSERTで生成されたユーザーIDを参照します
-- 'a:1:{s:13:"administrator";b:1;}'はPHPのシリアライズされた配列で、管理者権限を表します
INSERT INTO wp_usermeta (user_id, meta_key, meta_value) 
VALUES (LAST_INSERT_ID(), 'wp_capabilities', 'a:1:{s:13:"administrator";b:1;}');

-- WordPress一般ユーザーの作成
INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_registered, user_status, display_name)
VALUES ('wp_user1', MD5('user1_password'), 'normal_user', 'user@example.com', NOW(), 0, 'Normal User1')
ON DUPLICATE KEY UPDATE user_login=VALUES(user_login);

-- 作成した一般ユーザーに購読者（subscriber）権限を付与
INSERT INTO wp_usermeta (user_id, meta_key, meta_value) 
VALUES (LAST_INSERT_ID(), 'wp_capabilities', 'a:1:{s:10:"subscriber";b:1;}');
