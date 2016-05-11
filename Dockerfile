#
# This Dockerfile sets up a govCMS "remote server" using Apache
#
# Pandastix studio 2016
#

# docker run --env AUTHORIZED_KEYS='server master ssh key'

################## INIT DOCKER INSTALLATION ##################

FROM php:5.6-apache

MAINTAINER Joseph Zhao <joseph.zhao@pandastix.com>

# Set up ENV
ENV TERM xterm

ENV COMPOSER_PROCESS_TIMEOUT 900

ENV MYSQL_MAJOR 5.5
ENV MYSQL_USER mysql
ENV MYSQL_ROOT_PASSWORD root
ENV MYSQL_DATADIR /var/lib/mysql

ENV GOVCMS_VERSION 7.x-2.0
ENV GOVCMS_MD5 2c6558fde26e08821dc58bb21a11d3d7

####################   BEGIN INSTALLATION ####################

RUN a2enmod rewrite

# install the PHP extensions we need
RUN apt-get update && apt-get install -y python-software-properties libpng12-dev libjpeg-dev libpq-dev \
    git-core unzip openssl htop curl wget sudo rsync nano \
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mbstring pdo pdo_mysql pdo_pgsql zip

RUN apt-get autoclean

# INSTALL COMPOSER
RUN bash -c "curl -sS 'https://getcomposer.org/installer' | php -- --install-dir=/usr/local/bin --filename=composer"
RUN chmod a+x /usr/local/bin/composer

# INSTALL DRUSH
RUN wget http://files.drush.org/drush.phar
RUN chmod +x drush.phar
RUN sudo mv drush.phar /usr/local/bin/drush
RUN drush init	-y

WORKDIR /var/www/govcms
RUN rmdir /var/www/html/ && ln -sfn /var/www/govcms /var/www/html

RUN curl -fSL "https://ftp.drupal.org/files/projects/govcms-${GOVCMS_VERSION}-core.tar.gz" -o govcms.tar.gz \
	&& echo "${GOVCMS_MD5} *govcms.tar.gz" | md5sum -c - \
	&& tar -xz --strip-components=1 -f govcms.tar.gz \
	&& rm govcms.tar.gz \
	&& chown -R www-data:www-data sites/default


