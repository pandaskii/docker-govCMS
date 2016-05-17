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
RUN rm /var/lib/mysql/*logfile*	
COPY config/my.cnf /etc/mysql/

# OS update and upgrade
RUN apt-get update && apt-get install -y openssh-server apache2 supervisor \
    openssl htop curl wget postfix sudo rsync git-core unzip nano \
    php5 php5-cli php5-gd php5-mcrypt libapache2-mod-php5 php-pear php5-curl \
    php5-mysql \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor
COPY config/php.ini /etc/php5/apache2/

# Configure apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite
RUN a2enmod ssl
COPY config/govcms.conf /etc/apache2/sites-available/
RUN a2dissite 000-default
RUN a2ensite govcms

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
	&& chown -R www-data:www-data /var/www

##################### ADD SUPPORT FILES #####################
ADD src/govcms_supervisor.conf /etc/supervisor/conf.d/govcms_supervisor.conf
ADD src/govcms_db_init.sh /govcms/govcms_db_init.sh
ADD src/govcms_run.sh govcms_run.sh

# Give the execution permissions
RUN chmod +x /govcms/*.sh	

#####################  INSTALLATION END  #####################

# Expose port
EXPOSE 22
EXPOSE 80
EXPOSE 443
EXPOSE 3306

# Execut the pandastix_docker_run.sh
CMD ["govcms_run.sh"]