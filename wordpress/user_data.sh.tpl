#!/bin/bash

apt-get -y update
apt-get -y install apache2 wordpress
service apach2 start

wget http://wordpress.org/latest.tar.gz
tar xf latest.tar.gz
cp wordpress/wp-config{-sample,}.php
sed -i \
    -e "s/define('DB_NAME.*/define('DB_NAME', '${name}');/" \
    -e "s/define('DB_USER.*/define('DB_USER', '${user}');/" \
    -e "s/define('DB_PASSWORD.*/define('DB_PASSWORD', '${password}');/" \
    -e "s/define('DB_HOST.*/define('DB_HOST', '${host}');/" \
    wordpress/wp-config.php
mv wordpress /var/www/

sed -i \
    -e "s/DocumentRoot.*/DocumentRoot \/var\/www\/wordpress/" \
    /etc/apache2/sites-available/000-default.conf
service apache2 restart
