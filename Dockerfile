FROM ubuntu:15.10

MAINTAINER Oleksandr Koshevenko <aeroflot.ua@gmail.com>

#-----This variebles may be changed-------------------
ENV MADMF "Oleksandr"
ENV MADML "Koshevenko"
ENV MADMEMAIL "aeroflot.ua@gmail.com"
ENV MADMUSER "admin"
ENV MADMPASS "Magento123"
#-----------------------------------------------------

#-----MySQL installation------------------------------
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN mkdir /docker-entrypoint-initdb.d
# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
RUN apt-get update && apt-get install -y perl python-software-properties software-properties-common pwgen --no-install-recommends && rm -rf /var/lib/apt/lists/*
# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5

ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.6.29-1ubuntu15.10

RUN echo "deb http://repo.mysql.com/apt/ubuntu/ wily mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
    echo mysql-community-server mysql-community-server/data-dir select ''; \
    echo mysql-community-server mysql-community-server/root-pass password ''; \
    echo mysql-community-server mysql-community-server/re-root-pass password ''; \
    echo mysql-community-server mysql-community-server/remove-test-db select false; \
    } | debconf-set-selections \
    && apt-get update && apt-get install -y curl wget mc git mysql-server="${MYSQL_VERSION}" && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
    && echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
    && mv /tmp/my.cnf /etc/mysql/my.cnf

RUN service mysql start && mysql -e 'CREATE DATABASE magento;'

# Set frontend to noninteractive mode
ENV DEBIAN_FRONTEND noninteractive

#-----Install Nginx, PHP7.0 and related------------
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
RUN apt-add-repository ppa:ondrej/php-7.0 && apt-get update
ADD start.sh /

RUN apt-get install -y nginx php7.0 php7.0-common php7.0-dev php7.0-fpm php7.0-cli php7.0-mcrypt php7.0-intl php7.0-xsl php7.0-gd php7.0-curl php7.0-imap php7.0-json php7.0-opcache php7.0-mysql libpcre3-dev

#-----Deploing Magento2+SampleData---------------
# Wiping the /var/www directory
#
#RUN apt-get -y install sudo && adduser magento -s /sbin/nologin && echo "magento    ALL = NOPASSWD: ALL" >> /etc/sudoers
RUN rm -rf /var/www/*
WORKDIR /var/www
RUN usermod -u 1000 www-data

# Adding custom vhost to set AllowOverride to All
RUN rm -rf /etc/nginx/sites-available/default
RUN rm -rf /etc/nginx/sites-enabled/default
ADD m2.demo.conf /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/m2.demo.conf /etc/nginx/sites-enabled/m2.demo.conf

# Starting MySQL, creating db & deploying samle data
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer
ADD auth.json /root
ADD composer.json /root
RUN cd /var/www && git clone https://github.com/magento/magento2.git && cd /var/www/magento2 && composer install && chown -R www-data:www-data /var/www
RUN service mysql start && \
    php /var/www/magento2/bin/magento setup:install --db-name=magento --db-user=root --admin-firstname=$MADMF --admin-lastname=$MADML --admin-email=$MADMEMAIL --admin-user=$MADMUSER --admin-password=$MADMPASS && chown -R www-data:www-data /var/www && \
    cd /var/www && git clone https://github.com/magento/magento2-sample-data.git && php /var/www/magento2-sample-data/dev/tools/build-sample-data.php --ce-source="/var/www/magento2" && chown -R www-data:www-data /var/www && \
    php /var/www/magento2/bin/magento setup:upgrade && chown -R www-data:www-data /var/www

#RUN cd /var/www && git clone https://github.com/magento/magento2-sample-data.git && cd /var/www/magento2-sample-data/dev/tools && php build-sample-data.php --ce-source="/var/www/magento2"
#RUN cd /var/www/magento2 && find . -type d -exec chmod 770 {} \; && find . -type f -exec chmod 660 {} \; && chown -R www-data:www-data /var/www
#RUN cd /var/www/magento2/var && rm -rf cache/* page_cache/* generation/* 
#RUN service mysql start && php /var/www/magento2/bin/magento setup:upgrade && php /var/www/magento2/bin/magento setup:di:compile
#RUN chown -R www-data:www-data /var/www && cd /var/www/magento2 && \
#    find . -type d -exec chmod 770 {} \; && find . -type f -exec chmod 660 {} \; && chmod u+x bin/magento    

# Exposeing port 80
EXPOSE 80

# Starting the Apache & MySQL service on container boot 
#

CMD ["/start.sh"]

