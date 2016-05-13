#
# This Dockerfile sets up a govCMS "remote server" using Apache
#
# Pandastix studio 2016
#

# docker run --env AUTHORIZED_KEYS='server master ssh key'

################## INIT DOCKER INSTALLATION ##################

FROM ubuntu:trusty
MAINTAINER Joseph Zhao <joseph.zhao@xing.net.au>

# SET UP ENV
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
ENV COMPOSER_PROCESS_TIMEOUT 900

# MySQL.
ENV MYSQL_MAJOR 5.5
ENV MYSQL_USER mysql
ENV MYSQL_ROOT_PASSWORD root
ENV MYSQL_DATADIR /var/lib/mysql

# govCMS.
ENV GOVCMS_VERSION 7.x-2.0
ENV GOVCMS_MD5 2c6558fde26e08821dc58bb21a11d3d7

# Configure no init scripts to run on package updates.
ADD config/policy-rc.d /usr/sbin/policy-rc.d

####################   LAMP INSTALLATION   ####################

# INSTALL MySQL
# set installation parameters to prevent the installation script from asking
RUN { \
		echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASSWORD"; \
		echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"; \
	} | debconf-set-selections \
	&& apt-get update && apt-get install -y mysql-server

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
	&& echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
	&& mv /tmp/my.cnf /etc/mysql/my.cnf

# OS update and upgrade
RUN apt-get install -y supervisor openssl htop curl wget postfix sudo rsync git-core unzip nano \
    python-software-properties apache2 php5 php5-cli php5-gd php5-mcrypt libapache2-mod-php5 php-pear \
    php5-mysql \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get autoclean

# Configure apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN a2dismod mpm_event && a2enmod mpm_prefork && a2enmod rewrite

####################   SUPPORT LIBRARY   ####################

# INSTALL COMPOSER
RUN bash -c "curl -sS 'https://getcomposer.org/installer' | php -- --install-dir=/usr/local/bin --filename=composer"
RUN chmod a+x /usr/local/bin/composer

# INSTALL DRUSH
RUN wget http://files.drush.org/drush.phar
RUN chmod +x drush.phar
RUN sudo mv drush.phar /usr/local/bin/drush
RUN drush init	-y

#################### govCMS distribution ####################

WORKDIR /var/www/govcms
RUN rm -rf /var/www/html/ && ln -sfn /var/www/govcms /var/www/html

RUN curl -fSL "https://ftp.drupal.org/files/projects/govcms-${GOVCMS_VERSION}-core.tar.gz" -o govcms.tar.gz \
	&& echo "${GOVCMS_MD5} *govcms.tar.gz" | md5sum -c - \
	&& tar -xz --strip-components=1 -f govcms.tar.gz \
	&& rm govcms.tar.gz \
	&& chown -R www-data:www-data sites/default

##################### ADD SUPPORT FILES #####################

ADD src/pandastix_docker_apache.sh /pandastix_docker_apache.sh
ADD src/pandastix_docker_mysql.sh /pandastix_docker_mysql.sh
ADD src/pandastix_docker_db.sh /pandastix_docker_db.sh
ADD src/pandastix_docker_drush.sh /pandastix_docker_drush.sh
ADD src/pandastix_docker_supervisor.conf /etc/supervisor/conf.d/pandastix_docker_supervisor.conf
ADD src/pandastix_docker_run.sh /pandastix_docker_run.sh

# Give the execution permissions
RUN chmod +x /*.sh	

#####################  INSTALLATION END  #####################

# Expose port
EXPOSE 22
EXPOSE 80
EXPOSE 443
EXPOSE 3306

# Execut the pandastix_docker_run.sh
CMD ["/pandastix_docker_run.sh"]