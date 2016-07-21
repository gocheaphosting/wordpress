#!/bin/bash
# this script create a domain, installs the latest wordpress
# creates the ftp user and MySQL database.
# Author: Johnny Chavez
# Script:  wp_install.sh
# date: 21 July 2016
# version: 0.1.0

if [ "$(whoami)" != 'root' ]; then
        echo "You have no permission to run $0 as non-root user. Use sudo or switch to root user!!!"
        exit 1;
fi
##############################################################################
#
#                 This creates a domain
#
##############################################################################

ROOT="/var/www/vhosts"

if [ ! -d "$ROOT" ]; then
  mkdir -p $ROOT
fi

#
echo " Enter the domain name: "
read DOMAIN
#


if [  -d "$ROOT/$DOMAIN" ]; then
  echo $DOMAIN already exist
  exit 1
fi

DOCROOT="$ROOT/$DOMAIN/"
mkdir -p $DOCROOT

if [ ! -d "$ROOT" ]; then
  mkdir -p $ROOT
fi

echo "<VirtualHost *:80>
     ServerName $DOMAIN
     ServerAlias www.$DOMAIN
     DocumentRoot $DOCROOT
     ErrorLog /var/log/httpd/$DOMAIN-error.log
     CustomLog /var/log/httpd/$DOMAIN-access.log common
       <Directory $DOCROOT>
          AllowOverride All
       </Directory>
</VirtualHost>" > /etc/httpd/vhost.d/$DOMAIN.conf

##############################################################################
#
#     This creates a ftpuser for the domain with random password
#
##############################################################################

function ftp_user(){
if [ $(id -u) -eq 0 ]; then

PASS=$(openssl rand 12 -base64)

echo "Please enter FTP user for this domain: "
read ftpuser

egrep "^$ftpuser" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
echo "$ftpuser exists!"
exit 1
else

useradd -d $DOCROOT -s /sbin/nologin  $ftpuser
echo $PASS |passwd $ftpuser --stdin
#
chown -R $ftpuser:$ftpuser $DOCROOT
chmod 765 $DOCROOT
echo "------------------------------------------------------------------------------------ "
echo " The domain $DOMAIN  has been created successfully "
echo " The user $ftpuser has been created with the following: "
echo " The home directory is $DOCROOT"
echo " username: $ftpuser"
echo " password: $PASS"
echo "------------------------------------------------------------------------------------ "
fi
fi
}
echo " "
echo " "

##############################################################################
#
#                 This creates a database and  user 
#
##############################################################################

MYSQL=`which mysql`

function db_connect(){
echo -n "Enter the MySQL root password: "
read -s rootpw
echo -n "Enter database name to be created: "
read dbname
echo -n "Enter database username for new database: "
read dbuser
echo -n "Enter database user password: "
read dbpw

Q1="CREATE DATABASE IF NOT EXISTS '$dbname';"
Q2="GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpw';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

#DB="create database $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpw';FLUSH PRIVILEGES;"
$MYSQL mysql -u root -p$rootpw -e "$SQL"
}

function db1_connect(){
echo -n "Enter database name to be created: "
read dbname
echo -n "Enter database username for new database: "
read dbuser
echo -n "Enter database user password: "
read dbpw
#
Q1="CREATE DATABASE IF NOT EXISTS ${dbname};"
Q2="GRANT ALL PRIVILEGES ON ${dbname}.* TO ${dbuser}@localhost IDENTIFIED BY '${dbpw}';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

$MYSQL -e "$SQL"
}

if [ -e "/root/.my.cnf" ];then
   db1_connect
else
   db_connect
fi


if [ $? != "0" ]; then
 echo "[Error]: Database creation failed"
 exit 1
else
 echo "------------------------------------------"
 echo " Database has been created successfully "
 echo "------------------------------------------"
 echo " DB Info: "
 echo ""
 echo " DB Name: $dbname"
 echo " DB User: $dbuser"
 echo " DB Pass: $dbpw"
 echo ""
 echo "------------------------------------------"
fi
##############################################################################
#
#              This installs wordpress
#
##############################################################################

function wp_install(){
cd $DOCROOT
wget --quiet  http://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz --strip-components 1 && rm latest.tar.gz
mv wp-config-sample.php wp-config.php
sed -i 's/database_name_here/'$dbname'/g' $DOCROOT/wp-config.php
sed -i 's/username_here/'$dbuser'/g' $DOCROOT/wp-config.php
sed -i 's/password_here/'$dbpw'/g' $DOCROOT/wp-config.php
}
echo " "
echo " "
wp_install
echo "Please wait ... "
ftp_user

echo "##############################################################################
#
#              Wordpress has been installed !!!!!
#
##############################################################################
"
