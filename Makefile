DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

# 必要なファイルをコピーする
setup:
	@if [ ! -f srcs/.env ]; then \
		cp /path/to/your/.env srcs/.env; \
	fi
	@if [ ! -f srcs/requirements/nginx/conf/ssl/nginx.crt ]; then \
		mkdir -p srcs/requirements/nginx/conf/ssl; \
		cp /path/to/your/nginx.crt srcs/requirements/nginx/conf/ssl/nginx.crt; \
	fi
	@if [ ! -f srcs/requirements/nginx/conf/ssl/nginx.key ]; then \
		mkdir -p srcs/requirements/nginx/conf/ssl; \
		cp /path/to/your/nginx.key srcs/requirements/nginx/conf/ssl/nginx.key; \
	fi
	@if [ ! -f srcs/requirements/wordpress/wp-config.php ]; then \
		cp /path/to/your/nginx.key srcs/requirements/wordpress/wp-config.php; \
	fi

# Docker コンテナを起動
up: setup
	$(DOCKER_COMPOSE) up -d

# Docker コンテナを停止
down:
	$(DOCKER_COMPOSE) down

# Docker コンテナ、イメージ、ボリュームを削除
clean: down
	docker system prune -a --volumes

# 全てをリビルド
re: clean up

.PHONY: all setup up down clean re
