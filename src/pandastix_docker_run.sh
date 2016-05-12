#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    mysql_install_db > /dev/null 2>&1
    /pandastix_docker_db.sh
fi

exec supervisord -n