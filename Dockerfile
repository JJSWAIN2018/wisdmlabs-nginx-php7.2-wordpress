FROM ubuntu:16.04 
MAINTAINER Janmejaya Swain<janmejaya.swain@wisdmlabs.com> 

# Keep upstart from complaining
# RUN dpkg-divert --local --rename --add /sbin/initctl
# RUN ln -sf /bin/true /sbin/initctl
# RUN mkdir /var/run/sshd
# RUN mkdir /run/php

# Let the conatiner know that there is no tty
#ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install nginx
RUN apt-get clean && apt-get update && apt-get install -y locales
RUN apt-get -y install language-pack-en
#RUN locale-gen en_US.UTF-8 && export LANG=en_US.UTF-8
RUN apt-get install -y python-software-properties software-properties-common
RUN apt-get update 
#RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C
#RUN GPG_KEYS=E5267A6C
RUN LC_ALL=C.UTF-8 add-apt-repository -y  ppa:ondrej/php 
RUN apt-get update
RUN apt-get -y install php7.2
# Basic Requirements
# RUN apk add nginx 
# RUN apk add python-software-properties
# RUN apk add software-properties-common
# RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 
# RUN add-apk-repository ppa:ondrej/nginx 
# RUN apk update
# RUN apk install php7.2


# RUN apt-get -y install pwgen python-setuptools curl git nano sudo unzip openssh-server openssl
# RUN apt-get -y install  mysql-client nginx php-fpm 
# RUN apt-get update && apt-get -y upgrade && apt-get -y install software-properties-common add-apt-repository ppa:ondrej/nginx
# RUN apt-get update && apt-get -y install php7.2
# # RUN apt-get update && apt-get -y install language-pack-en \
# #     && apt-get -y install python-software-properties software-properties-common \
# #     && add-apt-repository ppa:ondrej/nginx--mainline && apt-get update && apt-get -y install php7.2
RUN apt-get -y install  mysql-client nginx php7.2-fpm
RUN apt-get -y --no-install-recommends install python3 pwgen vim php7.2-cli php7.2-common  php7.2-curl \
        php7.2-json php7.2-opcache  php7.2-readline php7.2-xml  php7.2-zip php7.2-fpm  \
        php7.2-intl php7.2-gd php7.2-mbstring php7.2-soap php7.2-bcmath php7.2-curl php7.2-ldap python-setuptools curl git unzip
RUN apt-get update && apt-get -y install php7.2-mysqli
#Wordpress Requirements
#RUN apt-get -y install php-xml php-mbstring php-bcmath php-zip  php-curl php-gd php-intl php-pear php-imagick php-imap php-mcrypt php-memcache php-apcu php-pspell php-recode php-tidy php-xmlrpc

# mysql config
#RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# nginx config
#RUN sed -i -e"s/user\s*www-data;/user wordpress www-data;/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.2/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.2/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.2/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.2/fpm/pool.d/www.conf
#RUN sed -i -e "s/user\s*=\s*www-data/user = wordpress/g" /etc/php/7.0/fpm/pool.d/www.conf
# replace # by ; RUN find /etc/php/7.0/mods-available/tmp -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;
RUN mkdir -p /var/run/php && cd /var/run/php && touch php7.2-fpm.sock
RUN chown www-data:www-data /var/run/php/php7.2-fpm.sock
# nginx site conf
ADD ./nginx-site.conf /etc/nginx/sites-available/default

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

# Add system user for Wordpress
# RUN useradd -m -d /home/wordpress -p $(openssl passwd -1 'wordpress') -G root -s /bin/bash wordpress \
#     && usermod -a -G www-data wordpress \
#     && usermod -a -G sudo wordpress \
#     && ln -s /usr/share/nginx/www /home/wordpress/www

# Install Wordpress
# ADD http://wordpress.org/latest.tar.gz /usr/share/nginx/latest.tar.gz
# RUN cd /usr/share/nginx/ \
#     && tar xvf latest.tar.gz \
#     && rm latest.tar.gz

# RUN mv /usr/share/nginx/wordpress /usr/share/nginx/www \
#     && chown -R wordpress:www-data /usr/share/nginx/www \
#     && chmod -R 775 /usr/share/nginx/www

ADD https://wordpress.org/latest.tar.gz /usr/share/nginx/latest.tar.gz
RUN cd /usr/share/nginx/ && tar xvf latest.tar.gz && rm latest.tar.gz
RUN mv /usr/share/nginx/wordpress /usr/share/nginx/www
RUN chown -R www-data:www-data /usr/share/nginx/www
RUN chmod -R 775 /usr/share/nginx/www

#Installation of wp-cli 
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp 
WORKDIR /usr/share/nginx/www 

# Wordpress Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

#NETWORK PORTS
# private expose
#EXPOSE 9011
#EXPOSE 3306
EXPOSE 80
#EXPOSE 22

# volume for mysql database and wordpress install
VOLUME ["/var/lib/mysql", "/usr/share/nginx/www", "/var/run/sshd"]

#CMD ["/bin/bash", "/start.sh"]
ENTRYPOINT ["/bin/bash"]
CMD ["/start.sh","sleep infinity"]
