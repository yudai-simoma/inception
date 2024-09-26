DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

# 必要なファイルをコピーする
setup:
	@if [ ! -f srcs/.env ]; then \
		cp /home/yshimoma/Desktop/inception/.env srcs/.env; \
	fi
	@if [ ! -f srcs/requirements/nginx/conf/ssl/nginx.crt ]; then \
		mkdir -p srcs/requirements/nginx/conf/ssl; \
		cp /home/yshimoma/Desktop/inception/nginx.crt srcs/requirements/nginx/conf/ssl/nginx.crt; \
	fi
	@if [ ! -f srcs/requirements/nginx/conf/ssl/nginx.key ]; then \
		mkdir -p srcs/requirements/nginx/conf/ssl; \
		cp /home/yshimoma/Desktop/inception/nginx.key srcs/requirements/nginx/conf/ssl/nginx.key; \
	fi
	@if [ ! -f srcs/requirements/wordpress/wp-config.php ]; then \
		cp /home/yshimoma/Desktop/inception/wp-config.php srcs/requirements/wordpress/wp-config.php; \
	fi

# Docker コンテナを起動
up: setup
	docker compose -f srcs/docker-compose.yml build --no-cache
	$(DOCKER_COMPOSE) up -d

# Docker コンテナを停止
down:
	$(DOCKER_COMPOSE) down

# Docker コンテナ、イメージ、ボリュームを削除
clean: down
	docker system prune -a --volumes
	@if docker volume inspect srcs_mariadb_data > /dev/null 2>&1; then \
		docker volume rm srcs_mariadb_data; \
	fi
	@if docker volume inspect srcs_wordpress_data > /dev/null 2>&1; then \
		docker volume rm srcs_wordpress_data; \
	fi
	@if docker volume inspect srcs_wordpress_files > /dev/null 2>&1; then \
		docker volume rm srcs_wordpress_files; \
	fi

# 全てをリビルド
re: clean up

.PHONY: all setup up down clean re
