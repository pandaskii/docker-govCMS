#!/bin/bash
#===============================================================================
#
#    Docker Pandastix
#
#===============================================================================
echo "Creating Database"
mysql -h localhost -u root <<EOF
CREATE DATABASE `govcms` CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL ON `govcms`.* TO `govcms`@localhost IDENTIFIED BY 'govcms';
FLUSH PRIVILEGES;
EOF
#===============================================================================