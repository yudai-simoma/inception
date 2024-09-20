#!/bin/bash
set -eo pipefail

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
    set -- mysqld "$@"
fi

# skip setup if they want an option that stops mysqld
wantHelp=
for arg; do
    case "$arg" in
        -'?'|--help|--print-defaults|-V|--version)
            wantHelp=1
            break
            ;;
    esac
done

if [ "$1" = 'mysqld' -a -z "$wantHelp" ]; then
    # Get config
    DATADIR="/var/lib/mysql"

    if [ ! -d "$DATADIR/mysql" ]; then
        if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
            echo >&2 'error: database is uninitialized and password option is not specified '
            echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD or MYSQL_RANDOM_ROOT_PASSWORD'
            exit 1
        fi

        mkdir -p "$DATADIR"
        chown -R mysql:mysql "$DATADIR"

        echo 'Initializing database'
        mysql_install_db --user=mysql --datadir="$DATADIR" --rpm
        echo 'Database initialized'

        # Start mysqld to config it
        mysqld --user=mysql --datadir="$DATADIR" --skip-networking &
        pid="$!"

        mysql=( mysql --protocol=socket -uroot )

        for i in {30..0}; do
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

        # Set root password and create users
        if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
            echo "Setting root password"
            "${mysql[@]}" <<-EOSQL
                SET @@SESSION.SQL_LOG_BIN=0;
                ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOSQL
        fi

        if [ "$MYSQL_DATABASE" ]; then
            echo "Creating database: $MYSQL_DATABASE"
            "${mysql[@]}" <<-EOSQL
                CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
EOSQL
        fi

        if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
            echo "Creating user: $MYSQL_USER"
            "${mysql[@]}" <<-EOSQL
                CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
EOSQL

            if [ "$MYSQL_DATABASE" ]; then
                echo "Granting privileges to user: $MYSQL_USER on $MYSQL_DATABASE"
                "${mysql[@]}" <<-EOSQL
                    GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
EOSQL
            fi
        fi

        echo
        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sh)     echo "$0: running $f"; . "$f" ;;
                *.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
                *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
                *)        echo "$0: ignoring $f" ;;
            esac
            echo
        done

        # Stop temporary mysqld
        if ! kill -s TERM "$pid" || ! wait "$pid"; then
            echo >&2 'MySQL init process failed.'
            exit 1
        fi

        echo
        echo 'MySQL init process done. Ready for start up.'
        echo
    fi

    chown -R mysql:mysql "$DATADIR"
fi

exec "$@"