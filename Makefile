DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

# 必要なファイルをコピーする
setup:
	@if [ ! -f srcs/.env ]; then \
		cp /home/yshimoma/Desktop/inception/.env srcs/.env; \
	fi

# Docker コンテナを起動
# --no-cache: ビルド時にキャッシュを使用せず、新しくイメージをビルドするオプション
# -d: コンテナがバックグラウンドで実行され、シェルがブロックされないオプション
up: setup
	$(DOCKER_COMPOSE) build --no-cache
	$(DOCKER_COMPOSE) up -d

# Docker コンテナを停止
down:
	$(DOCKER_COMPOSE) down

# Docker イメージ、ボリュームを削除
clean: down
	docker builder prune --all
	docker system prune -a --volumes
	@if docker volume inspect yshimoma-inception-project_mariadb_data > /dev/null 2>&1; then \
		docker volume rm yshimoma-inception-project_mariadb_data; \
	fi
	@if docker volume inspect yshimoma-inception-project_wordpress_data > /dev/null 2>&1; then \
		docker volume rm yshimoma-inception-project_wordpress_data; \
	fi

# 全てをリビルド
re: clean up

.PHONY: all setup up down clean re
