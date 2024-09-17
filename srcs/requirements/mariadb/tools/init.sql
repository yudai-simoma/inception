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

-- WordPress管理者ユーザーの作成
-- user_passはMD5でハッシュ化されたパスワード
INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_registered, user_status, display_name)
VALUES ('yshimoma', 'yshimoma_password', 'admin_user', 'admin@example.com', NOW(), 0, 'yshimoma');

-- 作成した管理者ユーザーに管理者権限を付与
-- LAST_INSERT_ID()は直前のINSERTで生成されたユーザーIDを参照します
-- 'a:1:{s:13:"administrator";b:1;}'はPHPのシリアライズされた配列で、管理者権限を表します
INSERT INTO wp_usermeta (user_id, meta_key, meta_value) 
VALUES (LAST_INSERT_ID(), 'wp_capabilities', 'a:1:{s:13:"administrator";b:1;}');

-- WordPress一般ユーザーの作成
INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_registered, user_status, display_name)
VALUES ('wp_user1', 'user1_password', 'normal_user', 'user@example.com', NOW(), 0, 'Normal User1');

-- 作成した一般ユーザーに購読者（subscriber）権限を付与
INSERT INTO wp_usermeta (user_id, meta_key, meta_value) 
VALUES (LAST_INSERT_ID(), 'wp_capabilities', 'a:1:{s:10:"subscriber";b:1;}');
