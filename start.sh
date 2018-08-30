#!/bin/bash
if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    MYSQL_PASSWORD="password" #`pwgen -c -n -1 12`
    WORDPRESS_PASSWORD="password" #`pwgen -c -n -1 12`
    #This is so the passwords show up in logs.
    echo mysql root password: $MYSQL_PASSWORD
    echo wordpress password: $WORDPRESS_PASSWORD
    echo $MYSQL_PASSWORD > /mysql-root-pw.txt
    echo $WORDPRESS_PASSWORD > /wordpress-db-pw.txt

    # mysqladmin -u root password $MYSQL_PASSWORD
    # mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    # mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WORDPRESS_PASSWORD'; FLUSH PRIVILEGES;"
    # killall mysqld
#fi

#if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
    WORDPRESS_DB="mysql" #"wordpress"
    WORDPRESS_USER="root"
    #WORDPRESS_PASSWORD=`cat /wordpress-db-pw.txt`
    sed -e "s/database_name_here/$WORDPRESS_DB/
    s/username_here/$WORDPRESS_USER/
    s/password_here/$WORDPRESS_PASSWORD/
    /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php
    sed -i "/DB_HOST/s/'[^']*'/'mysql-quickstart'/2" /usr/share/nginx/www/wp-config.php
    sed -i "80i define('FS_METHOD','direct');" /usr/share/nginx/www/wp-config.php
    # Download nginx helper plugin
    curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
    unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins

    # Activate nginx plugin and set up pretty permalink structure once logged in
    # cat << ENDL >> /usr/share/nginx/www/wp-config.php
    # \$plugins = get_option( 'active_plugins' );
    # if ( count( \$plugins ) === 0 ) {
    # require_once(ABSPATH .'/wp-admin/includes/plugin.php');
    # \$wp_rewrite->set_permalink_structure( '/%postname%/' );
    # \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php' );
    # foreach ( \$pluginsToActivate as \$plugin ) {
    # if ( !in_array( \$plugin, \$plugins ) ) {
    #   activate_plugin( '/usr/share/nginx/www/wp-content/plugins/' . \$plugin );
    # }
    # }
    # }
ENDL

    #chown -R wordpress: /usr/share/nginx/www/
    chown www-data:www-data /usr/share/nginx/www/wp-config.php
    chown -R www-data:www-data /usr/share/nginx/www/wp-content
    chmod -R 777 /usr/share/nginx/www/wp-content
    wp --allow-root core install --url=$URL  --title=$TITLE --admin_user=$USER --admin_email=$EMAIL --admin_password=$PASSWORD

fi

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf