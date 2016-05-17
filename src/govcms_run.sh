#!/bin/bash
#===============================================================================
#
#    Docker Pandastix
#
#===============================================================================
VOLUME_HOME="/var/lib/mysql"

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    mysql_install_db > /dev/null 2>&1
    /govcms/govcms_db_init.sh
fi

exec supervisord -n
#===============================================================================